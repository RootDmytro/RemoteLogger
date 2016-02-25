//
//  sockets.c
//  RemoteLogServer
//
//  Created by Dmytro Yaropovetsky on 2/15/16.
//  Copyright © 2016 Dmytro Yaropovetsky. All rights reserved.
//

#include "sockets.h"
#import <Foundation/Foundation.h>
#import "errors.h"
#include <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>


#if defined(DEBUG) || defined(_DEBUG_) || defined(_DEBUG)
  #define print(fmt, ...) NSLog(@"" fmt, __VA_ARGS__)
#elif defined(LOG_TO_FILE)
  #define print(fmt, ...) fprintf(_log_file, fmt, __VA_ARGS__); fflush(stdout)
#else
  #define print(fmt, ...) printf(fmt, __VA_ARGS__); fflush(stdout)
#endif

#define IPV4_(a, b, c, d) (((((d << 8) | c) << 8) | b) << 8) | a

int sock = -1;
int last_client = -1;

void RLServerStart(void (^reporter)(int client, const char *ip_v4, const char * data)) {
	sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
//	int ipv6_socket = socket(PF_INET6, SOCK_STREAM, IPPROTO_TCP);
	unsigned port = 1025;
	
	struct sockaddr_in sin;
	memset(&sin, 0, sizeof(sin));
	sin.sin_len = sizeof(sin);
	sin.sin_family = AF_INET; // or AF_INET6 (address family)
	sin.sin_port = htons(port);
	sin.sin_addr.s_addr = INADDR_ANY;//inet_addr("127.0.0.1");
 
	if (bind(sock, (struct sockaddr *)&sin, sin.sin_len) < 0) {
		int code = errno;
		print("\n[bind error] %i %s", code, error_msg[code]);
	}
	
//	socklen_t len = sizeof(sin);
//	if (getsockname(sock, (struct sockaddr *)&sin, &len) < 0) {
//		// Handle error here
//	}
	// You can now get the port number with ntohs(sin.sin_port).
	
	
	if (listen(sock, 10) < 0) {
		int code = errno;
		print("\n[listen error] %i %s", code, error_msg[code]);
	} else {
		char *master_addr_ip_v4 = malloc(INET_ADDRSTRLEN);
		inet_ntop(AF_INET, (const void *)&sin.sin_addr, master_addr_ip_v4, INET_ADDRSTRLEN);
		print("\n[listening on %s:%i]", master_addr_ip_v4, port);
	}
	
	while (1) {
		struct sockaddr_in client_addr;
		socklen_t len = sizeof(client_addr);
		memset(&client_addr, 0, len);
		sin.sin_len = len;
		
		int client = accept(sock, (struct sockaddr *)&client_addr, &len);
		
		if (client != -1) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				char *ip_v4 = malloc(INET_ADDRSTRLEN);
				inet_ntop(AF_INET, (const void *)&client_addr.sin_addr, ip_v4, INET_ADDRSTRLEN);
				
				print("\n[%s opened]", ip_v4);
				last_client = client;
				
				const size_t chunk_size = 1024;
				size_t buff_size = chunk_size;
				size_t chunk_index = 0;
				char *buff = malloc(chunk_size + 1);
				
				size_t length = 0;
				do
				{
					length = recv(client, buff, chunk_size, 0);
					chunk_index += length;
					last_client = client;
					
					while (length == chunk_size && recv(client, &buff[chunk_index], 1, MSG_PEEK) == 1) {
						if (chunk_index >= buff_size) {
							char *buff2 = memmove(malloc((buff_size = chunk_index + chunk_size) + 1), buff, chunk_index);
							free(buff);
							buff = buff2;
						}
						
						length = recv(client, buff + chunk_index, chunk_size, 0);
						chunk_index += length;
					}
					
					buff[chunk_index] = 0;
					print("\n[%s] %s", ip_v4, buff);
					if (reporter) {
						reporter(client, ip_v4, buff);
					}
					chunk_index = 0;
				}
				while (length > 0);
				
				if (length == 0) {
					print("\n[%s closed]", ip_v4);
				} else {
					int code = errno;
					print("\n[%s error] %i %s", ip_v4, code, error_msg[code]);
				}
				
				free(buff);
				free(ip_v4);
			});
		} else {
			int code = errno;
			print("\n[master error] %i %s", code, error_msg[code]);
		}
	}
}

void RLImmediate(int client, const char * data) {
	client = client == -1 ? last_client : client;
	if (client != -1 && send(client, data, strlen(data), 0) < 0) {
		int code = errno;
		print("\n[send error] %i %s", code, error_msg[code]);
	}
}

void RLClientInit(const char * ip_v4, void (^reporter)(const char * data)) {
	sock = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
	//	int ipv6_socket = socket(PF_INET6, SOCK_STREAM, IPPROTO_TCP);
	unsigned port = 1025;
	
	struct sockaddr_in sin;
	memset(&sin, 0, sizeof(sin));
	sin.sin_len = sizeof(sin);
	sin.sin_family = AF_INET; // or AF_INET6 (address family)
	sin.sin_port = htons(port);
	sin.sin_addr.s_addr = inet_addr(ip_v4);
 
	if (connect(sock, (struct sockaddr *)&sin, sin.sin_len) < 0) {
		int code = errno;
		print("\n[connect error] %i %s", code, error_msg[code]);
	} else {
		char *master_addr_ip_v4 = malloc(INET_ADDRSTRLEN);
		inet_ntop(AF_INET, (const void *)&sin.sin_addr, master_addr_ip_v4, INET_ADDRSTRLEN);
		print("\n[connected to %s:%i]", ip_v4, port);
	}
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		const size_t chunk_size = 1024;
		size_t buff_size = chunk_size;
		size_t chunk_index = 0;
		char *buff = malloc(chunk_size + 1);
		
		size_t length = 0;
		do
		{
			length = recv(sock, buff, chunk_size, 0);
			chunk_index += length;
			
			while (length == chunk_size && recv(sock, &buff[chunk_index], 1, MSG_PEEK) == 1) {
				if (chunk_index >= buff_size) {
					char *buff2 = memmove(malloc((buff_size = chunk_index + chunk_size) + 1), buff, chunk_index);
					free(buff);
					buff = buff2;
				}
				
				length = recv(sock, buff + chunk_index, chunk_size, 0);
				chunk_index += length;
			}
			
			buff[chunk_index] = 0;
			print("\n[%s] %s", ip_v4, buff);
			if (reporter) {
				reporter(buff);
			}
			chunk_index = 0;
		}
		while (length > 0);
		
		if (length == 0) {
			print("\n[%s closed]", ip_v4);
		} else {
			int code = errno;
			print("\n[%s error] %i %s", ip_v4, code, error_msg[code]);
		}
		
		free(buff);
	});
}

void RLLog(const char * data) {
	if (send(sock, data, strlen(data), 0) < 0) {
		int code = errno;
		print("\n[send error] %i %s", code, error_msg[code]);
	}
}

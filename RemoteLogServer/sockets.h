//
//  sockets.h
//  RemoteLogServer
//
//  Created by Dmytro Yaropovetsky on 2/15/16.
//  Copyright © 2016 Dmytro Yaropovetsky. All rights reserved.
//

#ifndef sockets_h
#define sockets_h

#include <stdio.h>

void RLServerStart(void (^reporter)(int client, const char *ip_v4, const char * data));
void RLImmediate(int client, const char * data);

void RLClientInit(const char * ip_v4, void (^reporter)(const char * data));
void RLLog(const char * data);

#endif /* sockets_h */

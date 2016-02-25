//
//  main.m
//  RemoteLogServer
//
//  Created by Dmytro Yaropovetsky on 2/15/16.
//  Copyright © 2016 Dmytro Yaropovetsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sockets.h"


int main(int argc, const char * argv[]) {
	@autoreleasepool {
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			char cmd[1024];
			while (1) {
				gets(cmd);
				RLImmediate(-1, cmd);
			}
		});
		RLServerStart(^(int client, const char * addr, const char * data) {
			
		});
	}
    return 0;
}

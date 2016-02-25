//
//  AppDelegate.m
//  RemoteLogServerGUI
//
//  Created by Dmytro Yaropovetsky on 2/15/16.
//  Copyright © 2016 Dmytro Yaropovetsky. All rights reserved.
//

#import "AppDelegate.h"
#import "sockets.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		RLServerStart(^(int client, const char * addr, const char * data) {
			dispatch_async(dispatch_get_main_queue(), ^{
				
			});
		});
	});
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

@end

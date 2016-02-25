//
//  perform.m
//  RemoteLogServer
//
//  Created by Dmytro Yaropovetsky on 2/17/16.
//  Copyright © 2016 Dmytro Yaropovetsky. All rights reserved.
//

#import "perform.h"

void RLPerform(const char * cmd)
{
	static NSMutableDictionary *variables;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		variables = @{}.mutableCopy;
	});
	NSArray<NSString *> *components = [[NSString stringWithUTF8String:cmd] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (components.count == 0) {
		return;
	}
	
	NSString *command = components[0];
	if ([command isEqualToString:@"call"] && components.count > 2) {
		SEL selector = NSSelectorFromString(components[2]);
		if (selector) {
			id target = nil;
			
			Class class = NSClassFromString(components[1]);
			if (class) {
				target = class;
			}
			
			if (!target) {
				void * pointer = (void *)[components[1] longLongValue];
				@try {
					if ([(__bridge id)pointer class]) {
						target = CFBridgingRelease(pointer);
					}
				}
				@catch (NSException *exception) {
				}
			}
			
			if (!target) {
				target = variables[components[1]];
			}
			
			if (target) {
				NSMethodSignature *signature = [target methodSignatureForSelector:selector];
				
				if (signature.numberOfArguments > components.count - 1) {
					return;
				}
				
				NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
				[invocation setTarget:target];
				[invocation setSelector:selector];
				for (int i = 2; i < signature.numberOfArguments; i++) {
					NSString *arg = components[i + 1];
					const char *argType = [signature getArgumentTypeAtIndex:i];
					switch (*argType) {
						case '@':
						{
							[invocation setArgument:&arg atIndex:i];
							break;
						}
						case 'i':
						{
							NSInteger integer = arg.integerValue;
							[invocation setArgument:&integer atIndex:i];
							break;
						}
						default:
						{
							[invocation setArgument:&arg atIndex:i];
							break;
						}
					}
				}
			}
		}
	} else if ([command isEqualToString:@"set"] && components.count > 2) {
		
	}
}
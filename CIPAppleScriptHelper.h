//
//  CIPAppleScriptHelper.h
//  BirthdayWuff
//
//  Created by Stefan Landvogt on 29.08.04.
//  Copyright 2004 Cipresso GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CIPAppleScriptHelper : NSObject {
}

+ (id)sharedHelper;

- (NSAppleEventDescriptor *)callInResource: (NSString *)resourcePath script: (NSString *)scriptName;
- (NSAppleEventDescriptor *)callInResource: (NSString *)resourcePath script: (NSString *)scriptName withArg:(NSString *)argument;
- (NSAppleEventDescriptor *)callInResource: (NSString *)resourcePath script: (NSString *)scriptName withArgs:(NSString *)args, ...;

@end

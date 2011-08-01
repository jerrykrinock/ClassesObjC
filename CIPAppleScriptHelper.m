//
//  CIPAppleScriptHelper.m
//  BirthdayWuff
//
//  Created by Stefan Landvogt on 29.08.04.
//  Copyright 2004 Cipresso GmbH. All rights reserved.
//

//  theLock eliminated by Jerry Krinock 20060719.  I don't see any purpose for it.

#import "CIPAppleScriptHelper.h"
#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

//@interface CIPAppleScriptHelper (private)
//
//NSLock *theLock;
//
//@end

@implementation CIPAppleScriptHelper

static CIPAppleScriptHelper *_sharedHelper = nil;

+ (id)sharedHelper {
	
    if (!_sharedHelper) {
        _sharedHelper = [[CIPAppleScriptHelper allocWithZone:[self zone]] init];
    }
    return _sharedHelper;
}

- (NSAppleEventDescriptor*)callInResource: (NSString *)resourcePath script:(NSString*)scriptName {
	return [self callInResource: resourcePath script: scriptName withArgs: nil];
}

- (NSAppleEventDescriptor *)callInResource: (NSString *)resourcePath script:(NSString*)scriptName withArg:(NSString*)argument {
	return [self callInResource: resourcePath script: scriptName withArgs: argument, nil];
}


- (NSAppleEventDescriptor *)callInResource: (NSString *)resourcePath script: (NSString *)theHandler withArgs:(NSString *)args, ... {
    // Reference:
    // http://lists.apple.com/archives/cocoa-dev/2003/Jan/21/callingapplescriptfromco.001.txt
	
	NSAppleScript* 			myScript;
    NSAppleEventDescriptor* event;
    NSAppleEventDescriptor* targetAddress;
    NSAppleEventDescriptor* subroutineDescriptor;
    NSAppleEventDescriptor* arguments;
    NSAppleEventDescriptor* result;
    NSDictionary* 			myErrorDict = nil;
	
//	if (theLock == 0)
//		theLock = [[NSLock alloc] init];
//	
//	while (![theLock tryLock]) {
//		usleep(10000); //Delay 0.001 seconds to not overrun the display
//	}
	
	int pid = [[NSProcessInfo processInfo] processIdentifier];
	
	NSDictionary *theError = [NSDictionary dictionary];
	NSURL *theURL = [[NSURL alloc] initFileURLWithPath:resourcePath];
	myScript = [[NSAppleScript alloc] initWithContentsOfURL:theURL error:&theError];
	
	// describes the target application (self)...
	targetAddress = [[NSAppleEventDescriptor alloc]
	initWithDescriptorType:typeKernelProcessID bytes:&pid length:sizeof(pid)];
	event = [[NSAppleEventDescriptor alloc] initWithEventClass:kASAppleScriptSuite eventID:kASSubroutineEvent targetDescriptor:targetAddress returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	
	// theHandler must be lower case
	subroutineDescriptor = [NSAppleEventDescriptor descriptorWithString:[theHandler lowercaseString]];
	[event setParamDescriptor:subroutineDescriptor forKeyword:keyASSubroutineName];
	arguments = [[NSAppleEventDescriptor alloc] initListDescriptor];
	
	// add stuff to your arguments list
    NSString *prev;
    va_list argList;
	
    va_start(argList, args);
    prev = args;
    while(prev != nil) {
        [arguments insertDescriptor:[NSAppleEventDescriptor descriptorWithString: prev] atIndex:0 ];
        prev = va_arg(argList, NSString *);
    }
    va_end(argList);
	
	[event setParamDescriptor:arguments forKeyword:keyDirectObject];
	
	// Here we go!!!  Execute the AS handler...
	result = [myScript executeAppleEvent:event error:&myErrorDict];
	
	if ( myErrorDict ) { // AS error, debug...
		NSLog(@"callInResource:script:withArgs: Error=%@\n",[myErrorDict description]);
	}
	
	[theURL release];
	[targetAddress release];
	[myScript release];
	[event release];
	[arguments release];
//	[theLock unlock];
	return(result);
}


@end

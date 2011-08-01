#import <Cocoa/Cocoa.h>
#import "SSYMailto.h"
#import "SSYOtherApper.h"
#import "SSYAlert.h"

@implementation SSYMailto

+ (void)emailTo:(NSString*)address
		subject:(NSString*)subject
		   body:(NSString*)body {
	NSString* mailtoString = [NSString stringWithFormat:@"mailto:%@?subject=%@&body=%@",
							  (NSString*)[(NSString*)CFURLCreateStringByAddingPercentEscapes(
																							 NULL,
																							 (CFStringRef)address,
																							 NULL,
																							 CFSTR("&"),
																							 kCFStringEncodingUTF8) autorelease],
							  (NSString*)[(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL,
																							 (CFStringRef)subject,
																							 NULL, CFSTR("&"),
																							 kCFStringEncodingUTF8) autorelease],
							  (NSString*)[(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL,
																							 (CFStringRef)body,
																							 NULL,
																							 CFSTR("&"),
																							 kCFStringEncodingUTF8) autorelease]] ;
	
	// Create an email message in user's default email client
	NSURL* mailtoURL = [NSURL URLWithString:mailtoString] ;
	[[NSWorkspace sharedWorkspace] openURL:mailtoURL] ;
	
	NSString* bundleIdentifier = [SSYOtherApper bundleIdentifierOfDefaultEmailClient] ;
	
	// The following was added in BookMacster 1.6.3.
	// For some reason, Qualcomm's Eudora 6.2.4 seems to interpret a \n or \r
	// properly-encoded \n or even \r as "end of body".  In that case, we write
	// the body to a file and ask the user to paste it in.  Note that the bundle
	// identifier given below is only for Qualcomm Eudora.  The Penelope Project's
	// new Eudora has bundle identifier org.mozilla.thunderbird.
	if ([bundleIdentifier isEqualToString:@"com.qualcomm.eudora"]) {
		NSString* filename = @"Email-Body.txt" ;
		[body writeToFile:[[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] stringByAppendingPathComponent:filename]
			   atomically:YES
				 encoding:NSUTF8StringEncoding
					error:NULL] ;
		NSString* msg = [NSString stringWithFormat:@"An email message has appeared in %@, and also a file named %@ has appeared on your desktop.  "
						 @"Please open the file %@, copy out its text, and paste it into the email message, then send the message to %@.",
						 [SSYOtherApper nameOfDefaultEmailClient],
						 filename,
						 filename,
						 address] ;
		
		[SSYAlert runModalDialogTitle:nil
							  message:msg
							  buttons:nil] ;
	}
}

@end
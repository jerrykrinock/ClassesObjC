#import <Cocoa/Cocoa.h>


@interface SSYSheetEnder : NSObject {

}

/*!
 @brief    A generic "did end selector" for an alert-style
 sheet containing 1-3 buttons which will invoke a given
 invocation according to which button was clicked.
 
 @param		retainedInvocations An array of 0-3 objects, or nil.
 An attempt will be made to select one of the objects based
 on the return code, if the array's count is large enough:
 ;    Return Code             objectAtIndex
 ;    NSAlertFirstButtonReturn    0
 ;    NSAlertThirdButtonReturn  1
 ;    NSAlertSecondButtonReturn      2
 If an object is obtained, it will be tested to see if
 it responds to -invoke, and will be send the -invoke
 message if it does.
 
 Typically, 'invocations' contains 0-3 NSInvocation or NSNull
 instances.  If there are three and the user's alternate
 selection is "Cancel", the middle object should be NSNull.
 
 We named this param *retained* invocations so you won't forget this…
 Because it is passed as unretained contextInfo, 'retainedInvocations'
 MUST BE SENT A SINGLE UNBALANCED -retain before passing
 it to this method.  This method will send it an unbalanced
 -release to balance that.
 */
+ (void)didEndGenericSheet:(NSWindow*)sheet
				returnCode:(NSInteger)returnCode
			   retainedInvocations:(NSArray*)invocations ;

@end

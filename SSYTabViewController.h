#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface SSYTabViewController : NSTabViewController {
}

/* Workaround for the fact that, if used with a NSTabView, NSTabViewController
 must be the delegate of a NSTabView, but one of your classes needs some of
 those delegate calls .  This is like a "pass through" delegate…
 
 NSTabView .delegate -->  NSTabViewController .surrogate --> Your Delegate
 
 I used a different name, though, in case Apple ever adds .delegate to
 NSTabViewController. */
@property (assign) NSObject <NSTabViewDelegate> * surrogate;

@end

NS_ASSUME_NONNULL_END

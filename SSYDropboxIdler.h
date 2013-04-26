#import <Foundation/Foundation.h>

@protocol SSYDropboxIdlerDelegate <NSObject>

- (void)appendProgress:(NSString*)progress ;

@end

@interface SSYDropboxIdler : NSObject {
    NSObject <SSYDropboxIdlerDelegate> * m_delegate ;
    NSString* m_logPath ;
}

- (id)initWithDelegate:(NSObject <SSYDropboxIdlerDelegate> *)delegate
               logPath:(NSString*)logPath ;

/*!
 @brief    Blocks until the Dropbox application appears to be not busy.
 
 @details  The criteria used is that first the CPU usage of the Dropbox
 application, returned by /bin/ps, is measured once per 2 seconds for 10
 seconds.  If the average of these five measurements is less than 1.0 percent,
 then three more measurements are taken at 1-second intervals.  If all
 three of these are less than 0.25 percent, then isIdle_p is set to point
 to YES and the method returns.  If either of these tests fail, then
 they are repeated, and this continues until the timeout.
 
 When Dropbox is idle, this method usually returns the affirmative result
 after 13-39 seconds.  When Dropbox is receiving a file, it will not
 return an affirmative result until Dropbox is idle.  Also when Time
 Machine is doing a backup, this usually keeps Dropbox active enough
 to not return an affirmative result for a minute or two.  But you
 probably don't want to be messing with Dropbox while Time Machine
 is doing its thing anyhow.
 
 This method sleeps the thread between measurements, so it's not a
 CPU hog, just a thread hog.
 
 @param    timeout  time to wait for Dropbox to become idle.  However,
 one measurement cycle, which takes about 15 seconds, will always
 execute.  So this method will always block for at least about 15
 seconds no matter what value you pass here.
 @param    isIdle_p  Pointer which will, upon return, if not nil,
 point to YES if Dropbox is idle and no error occurred, NO otherwise.
 @param    error_p  Pointer which will, upon return, if the method
 was not able to determine isIdle_p and error_p is not
 NULL, point to an NSError describing said error.
 @result   YES if the method was able to set isIdle_p,
 otherwise NO.
 */
- (BOOL)waitForIdleDropboxTimeout:(NSTimeInterval)samplePeriod
						   isIdle:(BOOL*)isIdle_p
                      narrative_p:(NSString**)narrative_p
						  error_p:(NSError**)error_p ;

@end

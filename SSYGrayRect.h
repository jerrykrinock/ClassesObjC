#import <Cocoa/Cocoa.h>


/*!
 @brief     A view that adds a gray gradient as its background, suitable
 for a status bar at the bottom of a window which complements a Cocoa
 toolbar at the top of same window.
*/
@interface SSYGrayRect : NSView {
    CGFloat m_topWhite ;
    CGFloat m_bottomWhite ;
}


/*!
 @brief     The white value (0=black, 1=white) at the top of the receiver
 @details   Initial default value is 0.627.
 */
@property (assign) CGFloat topWhite ;

/*!
 @brief     The white value (0=black, 1=white) at the top of the receiver
 @details   Initial default value is 0.784.
 */
@property (assign) CGFloat bottomWhite ;


@end

#import <Cocoa/Cocoa.h>

extern NSString* const constBindingToolbarDisplayStyle ;

enum SSYToolbarDisplayStyle_enum {
	SSYToolbarDisplayStyleTextOnly,
	SSYToolbarDisplayStyleTextAndSmallIcons,
	SSYToolbarDisplayStyleTextAndRegularIcons
} ;
typedef enum SSYToolbarDisplayStyle_enum SSYToolbarDisplayStyle ;

/*!
 @brief    A little bindings support in NSToolbar, please!
 
 A tri-state binding and property 'displayStyle' is added, and the
 base class properties -displayMode and -sizeMode are made KVObserveable.
*/
@interface SSYToolbar : NSToolbar {
	BOOL m_isShutDown ;
}

@property (assign) SSYToolbarDisplayStyle displayStyle ;

- (void)shutDown ;

@end

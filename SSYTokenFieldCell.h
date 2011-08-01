#import <Cocoa/Cocoa.h>


/*!
 @brief    An NSTokenFieldCell subclass which can show different
 placeholders for "No Selection", "Multiple Selection" and
 "No Tokens", useful in the detail of a master-detail view; also
 it exposes tokenizingCharacter as a binding.

 @details  The superclass method -setObjectValue: is overridden
 and behaves such that if the 'value' binding, or equivalently
 the objectValue value, is:
 <ul>
 <li>an empty NSArray and noTokensPlaceholder is not nil,
 the noTokensPlaceholder is displayed.</li>
 <li>NSNoSelectionMarker, and noSelectionPlaceholder is not nil,
 the noSelectionPlaceholder is displayed.</li>
 <li>NSMultipleValuesMarker, and a multipleValuesPlaceholder has been
 set, the multipleValuesPlaceholder is displayed.</li>
 <li>NSNotApplicableMarker, and a notApplicablePlaceholder has been
 set, the notApplicablePlaceholder is displayed.</li>
 If none of the above is true, which happens in the normal case
 when the value is a nonempty array, the normal inherited behavior
 occurs and tokens are displayed.
 
 Note: The 'value' parameter with the desired NS...Markers can be
 obtained by using the category method -[NSArray(Select1) select1],
 or probably an NSArrayController. 
 */
@interface SSYTokenFieldCell : NSTokenFieldCell {
	NSString* noSelectionPlaceholder ;
	NSString* noTokensPlaceholder ;
	NSString* multipleValuesPlaceholder ;
	NSString* notApplicablePlaceholder ;
	unichar m_tokenizingCharacter ;
}

@property (copy) NSString* noSelectionPlaceholder ;
@property (copy) NSString* noTokensPlaceholder ;
@property (copy) NSString* multipleValuesPlaceholder ;
@property (copy) NSString* notApplicablePlaceholder ;
@property (assign) unichar tokenizingCharacter ;

@end

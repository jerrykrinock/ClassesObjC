@interface SSYMultiTextFieldCell : NSTextFieldCell {
	NSImage* icon1 ;
	NSImage* icon2 ;
	NSInteger arrowDirection ;
	BOOL overdrawsRectOfDisclosureTriangle ;
}

/*!
 @brief    An icon which, if set, will appear as the leftmost
 element in the cell.

 @details  This element is not editable by the user.
*/
@property (retain) NSImage* icon1 ;

/*!
 @brief    An icon which, if set, will appear as the second leftmost
 element in the cell.
 
 @details  This element is not editable by the user.
 */
@property (retain) NSImage* icon2 ;

/*!
 @brief    An integer which specifies the presence and direction of
 an arrow pointing to a bar between the icon(s) and the main string.
 
 @details  0 = no arrow.  1 = arrow pointing up.  2 = arrow pointing down.
 */
@property (assign) NSInteger arrowDirection ;

@property (assign) BOOL overdrawsRectOfDisclosureTriangle ;

@end


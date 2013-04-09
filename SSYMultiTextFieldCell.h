@interface SSYMultiTextFieldCell : NSTextFieldCell {
	NSInteger arrowDirection ;
	BOOL overdrawsRectOfDisclosureTriangle ;
    NSArray* m_images ;
    NSArray* m_imageRects ;
}

/*!
 @brief    Images which will appear to the left of the text.

 @details  Will return an empty array.
*/
@property (retain) NSArray* images ;

@property (assign) BOOL overdrawsRectOfDisclosureTriangle ;

@end


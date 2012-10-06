#import <Cocoa/Cocoa.h>


enum SSYVectorImageStyles_enum
{
	SSYVectorImageStylePlus,
	SSYVectorImageStyleMinus, 
	SSYVectorImageStyleTriangle, 
	SSYVectorImageStyleArrow,
	SSYVectorImageStyleInfo,
	SSYVectorImageStyleStar,
	SSYVectorImageStyleRemoveX,
} ;
typedef enum SSYVectorImageStyles_enum SSYVectorImageStyle ;


@interface SSYVectorImages : NSObject {
}

+ (NSImage*)imageStyle:(SSYVectorImageStyle)style
			  diameter:(CGFloat)diameter
				 color:(NSColor*)color
		 rotateDegrees:(CGFloat)rotateDegrees ;

@end

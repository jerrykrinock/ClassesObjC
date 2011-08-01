#import <Cocoa/Cocoa.h>


enum SSYVectorImageStyles_enum
{
	SSYVectorImageStylePlus,
	SSYVectorImageStyleMinus, 
	SSYVectorImageStyleTriangle, 
	SSYVectorImageStyleArrow,
	SSYVectorImageStyleInfo
} ;
typedef enum SSYVectorImageStyles_enum SSYVectorImageStyle ;


@interface SSYVectorImages : NSObject {
}

+ (NSImage*)imageStyle:(SSYVectorImageStyle)style
			  diameter:(CGFloat)diameter
		 rotateDegrees:(CGFloat)rotateDegrees ;

@end

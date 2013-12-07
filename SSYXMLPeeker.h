#import <Foundation/Foundation.h>

@interface SSYXMLPeeker : NSObject <NSXMLParserDelegate> {
	NSMutableString* m_parsedValue ;
    NSError* m_error ;
    NSString* m_targetElement ;
    BOOL m_ignoreError ;
}

/*
 @brief    Parses an XML file at a given path and returns a the string value
 of a single given target element
 
 @details  This method returns synchronously.
 
 @param    error_p  If a parse error occurs, and error_p is not NULL, upon 
 return error_p will point to the parse error.
 
 @result   If the target element exists in the XML but does not have a string
 value, result is an empty string.  If the target element does not exist in the
 XML, result is nil.
 */
+ (NSString*)stringValueOfElement:(NSString*)targetElement
                      XMLFilePath:(NSString*)path
                          error_p:(NSError**)error_p ;

@end

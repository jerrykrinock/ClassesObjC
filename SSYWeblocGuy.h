#import <Cocoa/Cocoa.h>


@interface SSYWeblocGuy : NSObject <NSXMLParserDelegate> {
    NSMutableString* m_xmlString ;
}

/*!
 @brief    Returns a dictionary containing the URL and name represented by
 a .webloc file at a given path
 
 @details  The returned dictionary contains objects for two keys, "url" which
 is the url extracted from the .webloc file, and "filename" which is the base
 name of the .webloc file, without the path and without the .webloc extension.
 
 If the given file's name does not have the .webloc extension, or does not
 XML containing a URL as expected for a .webloc file, returns nil.

 This method extracts the URL from XML in the data fork which is assumed to
 look like this example.
 
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
 <key>URL</key>
 <string>http://ancienthistory.about.com/od/cityofrome/ss/7hillsofRome.htm</string>
 </dict>
 </plist>
 
 It simply parses whatever is in the last <string>.  TODO: Do a proper parsing,
 looking for the <string> element of the <dict> element of the <plist> element.
 
 Although ancient versions of Safari created .webloc files with the target URL
 in the resource fork instead of the data fork, this method no longer supports
 that. */
+ (NSDictionary*)filenameAndUrlFromWeblocFileAtPath:(NSString*)path ;

/*!
 @brief    Returns an array of dictionaries, each containing the filename and
 URL extracted from any .webloc file found in a given array of file paths by
 -filenameAndUrlFromWeblocFileAtPath:.
 */
+ (NSArray*)weblocFilenamesAndUrlsInPaths:(NSArray*)paths ;

@end

#import <Cocoa/Cocoa.h>


@interface SSYResourceForks : NSObject <NSXMLParserDelegate> {
    NSMutableString* m_xmlString ;
    BOOL m_accumulatingUrl ;
}

/*
@details  If a URL cannot be found in the resource fork, looks for XML in the
 data fork.  Can extract URL from this:
 <?xml version="1.0" encoding="UTF-8"?>
 <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
 <plist version="1.0">
 <dict>
 <key>URL</key>
 <string>http://ancienthistory.about.com/od/cityofrome/ss/7hillsofRome.htm</string>
 </dict>
 </plist>

 It simply parses whatever is in the last <string>.  Of course, we could do a
 better job by using some kind of 'state' instance variable and looking for the
 <string> element of the <dict> element of the <plist> element, but since
 I'm not sure of the exact xml structure anyhow and just reverse-engineered
 this from a file I received from a user, this is good enough.
 */


+ (NSArray*)weblocFilenamesAndUrlsInPaths:(NSArray*)paths ;

@end

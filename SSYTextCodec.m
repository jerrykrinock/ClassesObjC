#import "SSYTextCodec.h"
#import "NSError+SSYAdds.h"

@implementation SSYTextCodec

+ (BOOL)decodeTextData:(NSData*)fileDataIn
	   decodedString_p:(NSString**)decodedString_p
stringEncodingStated_p:(NSStringEncoding*)stringEncodingStated_p
  stringEncodingUsed_p:(NSStringEncoding*)stringEncodingUsed_p
	   newLinesFound_p:(NSString**)newLinesFound_p 
			   error_p:(NSError**)error_p {
	NSError* error = nil ;
	NSString* msg ;
	
	NSString* stringASCII = [[NSString alloc] initWithData:fileDataIn
												  encoding:NSASCIIStringEncoding];
	
	if (!stringASCII) {
		msg = @"Can't decode given data to ASCII." ;
		NSLog(@"%@", msg) ;
		error = SSYMakeError(47757, msg) ;
	}
	
	// Discover and set line endings type (dos, old Mac or unix)
	NSString* newLinesFound = nil ;
	if (!error) {	
		int rLocation = stringASCII ? [stringASCII rangeOfString:@"\r"].location : 0 ;
		int nLocation = stringASCII ? [stringASCII rangeOfString:@"\n"].location : 0 ;
		
		// Set to whichever occurs first in the file: \r\n, \r or \n
		if (nLocation == rLocation + 1) {
			newLinesFound = @"\r\n" ;
		}			
		else if (rLocation < nLocation) {
			newLinesFound = @"\r" ;
		}
		else {
			newLinesFound = @"\n" ;
		}
	}
		
	NSString *utfdash8Key = @"content=\"text/html; charset=utf-8" ;
	NSString *xmacromanKey = @"content=\"text/html; charset=x-mac-roman" ;
	NSString *xmacsystemKey = @"CONTENT=\"text/html; charset=X-MAC-SYSTEM" ;
	NSString *shiftJisKey = @"CONTENT=\"text/html; charset=Shift_JIS" ;
	NSString *operaUTF8Key = @"encoding = utf8" ;
	NSString *operaBookitUTF8Key = @"encoding=utf8" ;
	
	NSDictionary *encodingDict = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSNumber numberWithUnsignedInt:NSUTF8StringEncoding], utfdash8Key,
								  [NSNumber numberWithUnsignedInt:NSMacOSRomanStringEncoding], xmacromanKey,
								  [NSNumber numberWithUnsignedInt:NSShiftJISStringEncoding], shiftJisKey,
								  [NSNumber numberWithUnsignedInt:[NSString defaultCStringEncoding]], xmacsystemKey,
								  [NSNumber numberWithUnsignedInt:NSUTF8StringEncoding], operaUTF8Key,
								  [NSNumber numberWithUnsignedInt:NSUTF8StringEncoding], operaBookitUTF8Key,
								  nil];
	
	NSRange range;
	NSStringEncoding stringEncodingStated = NSNotFound ;
	NSStringEncoding stringEncodingUsed = NSNotFound ;
	NSString* decodedString = nil ;
	if (!error) {
		for (id key in encodingDict)
		{
			range = [stringASCII rangeOfString:key options:NSCaseInsensitiveSearch];
			if (range.location != NSNotFound)
			{
				stringEncodingStated = [[encodingDict objectForKey:key] unsignedIntValue] ; 
				stringEncodingUsed = [[encodingDict objectForKey:key] unsignedIntValue] ; 
				decodedString = [[NSString alloc] initWithData:fileDataIn encoding:stringEncodingStated] ;
				break ;
			}
		}
		
		NSStringEncoding encoding ;
		
		if (!decodedString) {
			encoding = NSUTF8StringEncoding ;
			decodedString = [[NSString alloc] initWithData:fileDataIn encoding:encoding] ;
			stringEncodingUsed = encoding ; 
		}
		
		if (!decodedString) {
			encoding = [NSString defaultCStringEncoding] ;
			decodedString = [[NSString alloc] initWithData:fileDataIn encoding:encoding] ;
			stringEncodingUsed = encoding ; 
		}
		
		if (!decodedString) {
			encoding = NSASCIIStringEncoding ;
			decodedString = [[NSString alloc] initWithData:fileDataIn encoding:encoding] ;
			stringEncodingUsed = encoding ; 
		}
		
		if (!decodedString) {
			msg = @"All attempts to decode data failed." ;
			NSLog(@"%@", msg) ;
			error = SSYMakeError(47757, msg) ;
		}
	}
	
	[stringASCII release] ;
	
	if (decodedString_p) {
		*decodedString_p = decodedString ;
		[decodedString autorelease] ;
	}
	else {
		[decodedString release] ;
	}
	
	if (stringEncodingStated_p) {
		*stringEncodingStated_p = stringEncodingStated ;
	}
	
	if (stringEncodingUsed_p) {
		*stringEncodingUsed_p = stringEncodingUsed ;
	}
	
	if (newLinesFound_p) {
		*newLinesFound_p = newLinesFound ;
	}
	
	if (error_p && error) {
		*error_p = error ;
	}
	
	return (error == nil) ;
}

+ (NSString*)humanReadableStringEncoding:(NSStringEncoding)stringEncoding {
	NSString* answer ;
	
	switch (stringEncoding) {
		case NSASCIIStringEncoding:
			answer = @"NSASCIIStringEncoding" ;
			break ;
		case NSNEXTSTEPStringEncoding:
			answer = @"NSNEXTSTEPStringEncoding" ;
			break ;
		case NSJapaneseEUCStringEncoding:
			answer = @"NSJapaneseEUCStringEncoding" ;
			break ;
		case NSUTF8StringEncoding:
			answer = @"NSUTF8StringEncoding" ;
			break ;
		case NSISOLatin1StringEncoding:
			answer = @"NSISOLatin1StringEncoding" ;
			break ;
		case NSSymbolStringEncoding:
			answer = @"NSSymbolStringEncoding" ;
			break ;
		case NSNonLossyASCIIStringEncoding:
			answer = @"NSNonLossyASCIIStringEncoding" ;
			break ;
		case NSShiftJISStringEncoding:
			answer = @"NSShiftJISStringEncoding" ;
			break ;
		case NSISOLatin2StringEncoding:
			answer = @"NSISOLatin2StringEncoding" ;
			break ;
		case NSUnicodeStringEncoding:
			answer = @"NSUnicodeStringEncoding" ;
			break ;
		case NSWindowsCP1251StringEncoding:
			answer = @"NSWindowsCP1251StringEncoding" ;
			break ;
		case NSWindowsCP1252StringEncoding:
			answer = @"NSWindowsCP1252StringEncoding" ;
			break ;
		case NSWindowsCP1253StringEncoding:
			answer = @"NSWindowsCP1253StringEncoding" ;
			break ;
		case NSWindowsCP1254StringEncoding:
			answer = @"NSWindowsCP1254StringEncoding" ;
			break ;
		case NSWindowsCP1250StringEncoding:
			answer = @"NSWindowsCP1250StringEncoding" ;
			break ;
		case NSISO2022JPStringEncoding:
			answer = @"NSISO2022JPStringEncoding" ;
			break ;
		case NSMacOSRomanStringEncoding:
			answer = @"NSMacOSRomanStringEncoding" ;
			break ;
		default:
			answer = @"Unknown string encoding" ;
	}
	
	return answer ;
}

@end

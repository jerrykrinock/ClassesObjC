#import "SSYUserInfo.h"
#import <SystemConfiguration/SCDynamicStoreCopySpecific.h>
#import <AddressBook/ABAddressBook.h>
#import <AddressBook/ABMultiValue.h>


@implementation SSYUserInfo

+ (void)fromAddressBookFirstName_p:(NSString**)ptrFirstName
						lastName_p:(NSString**)ptrLastName
						   email_p:(NSString**)ptrEmail {
	ABPerson* me = [[ABAddressBook sharedAddressBook] me] ;		
	
	if (ptrEmail) {
		ABMultiValue *emails = [me valueForProperty:kABEmailProperty]; 
		*ptrEmail = nil ;
		NSString* emailIdentifier = [emails primaryIdentifier] ;
		if (emailIdentifier) {
			*ptrEmail = [emails valueAtIndex:[emails indexForIdentifier:emailIdentifier]];
		}
		if (!(*ptrEmail)) {
			*ptrEmail = @"" ;
		}
	}
	
	if (ptrFirstName) {
		*ptrFirstName = [me valueForProperty:kABFirstNameProperty]; 
		if (!(*ptrFirstName)) {
			*ptrFirstName = @"" ;
		}
	}
	
	if (ptrLastName) {
		*ptrLastName = [me valueForProperty:kABLastNameProperty];
		if (!(*ptrLastName)) {
			*ptrLastName = @"" ;
		}
	}
}	

+ (NSString*)consoleUserNameAndUid_p:(uid_t*)uid_p
							   gid_p:(gid_t*)gid_p {
	NSString* name = (NSString*)SCDynamicStoreCopyConsoleUser(NULL, uid_p, gid_p) ;
	return [name autorelease] ;
}

@end

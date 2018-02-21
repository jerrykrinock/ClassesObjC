#import "SSYUserInfo.h"
#import <SystemConfiguration/SCDynamicStoreCopySpecific.h>
#import <AddressBook/ABAddressBook.h>
#import <AddressBook/ABMultiValue.h>
#import <utmpx.h>
#import <string.h>

NSString* const SSYUserInfoErrorDomain = @"SSYUserInfoErrorDomain";
NSInteger const SSYUserInfoCouldNotGetLoginTimeError = 948308;

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

+ (NSDate*)whenThisUserLoggedInError_p:(NSError**)error_p {
    /* See:
     https://www.freebsd.org/cgi/man.cgi?query=getutxent&sektion=3
     */
    NSString* targetUser = (NSString*)CFBridgingRelease(SCDynamicStoreCopyConsoleUser(NULL, NULL, NULL)) ;
    struct utmpx* entry_p;
    /* getutxent gets the entire history of UTX entries.  By passing 0 in the
     following line, we tell it to give us the most recent entries first. */
    setutxent_wtmp(0);
    NSDate* date = nil;
    NSInteger countOfEntries = 0;
    NSInteger countOfUserEntries = 0;
    NSInteger countOfConsoleUserEntries = 0;
    NSInteger countOfThisConsoleUserEntries = 0;
    NSString* user = nil;
    NSMutableArray* lines = [NSMutableArray new];
    while (!date && (entry_p = getutxent_wtmp()) != NULL) {
        countOfEntries++;
        if (entry_p->ut_type == USER_PROCESS) {
            countOfUserEntries++;
            /* In addition to macOS GUI logins, there are also UTX entries for
             other logins such as Terminal.app tabs.  These are
             differentiated as different "line" types.  For the macOS GUI login
             which we want, the line type is "console". */
            NSString* line = [NSString stringWithUTF8String:entry_p->ut_line];
            if (line) {
                [lines addObject:line];
            }
            if ([line isEqualToString:@"console"]) {
                countOfConsoleUserEntries++;
                /* Finally, of course, we are only interested in logins of the
                 current macOS user. */
                user = [NSString stringWithUTF8String:entry_p->ut_user];
                if ([user isEqualToString:targetUser]) {
                    countOfThisConsoleUserEntries++;
                    time_t unixTime = entry_p->ut_tv.tv_sec;
                    date = [NSDate dateWithTimeIntervalSince1970:unixTime];
                    break;
                }
            }
        }
    };
    endutxent_wtmp();

    if (!date && error_p) {
        NSError* error = [NSError errorWithDomain:SSYUserInfoErrorDomain
                                             code:SSYUserInfoCouldNotGetLoginTimeError
                                         userInfo:@{
                                                    NSLocalizedDescriptionKey: @"SSYUserInfo could not find `%@` console UTX entry",
                                                    @"entries count": [NSNumber numberWithInteger:countOfEntries],
                                                    @"user entries count": [NSNumber numberWithInteger:countOfUserEntries ],
                                                    @"console user entries count": [NSNumber numberWithInteger:countOfConsoleUserEntries ],
                                                    @"this console user entries count": [NSNumber numberWithInteger:countOfThisConsoleUserEntries ],
                                                    @"lines": lines
                                                    }];
        *error_p = error;
    }

    [lines release];
    return date;
}

@end

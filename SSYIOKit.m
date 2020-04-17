/*
 File:			GetPrimaryMACAddress.c
	
 Description:	This sample application demonstrates how to do retrieve the Ethernet MAC
 address of the built-in Ethernet interface from the I/O Registry on macOS.
 Techniques shown include finding the primary (built-in) Ethernet interface,
 finding the parent Ethernet controller, and retrieving properties from the
 controller's I/O Registry entry.
 
  
	Change History (most recent first):
 
 <3>	 	09/15/05	Updated to produce a universal binary. Use kIOMasterPortDefault
 instead of older IOMasterPort function. Print the MAC address
 to stdout in response to <rdar://problem/4021220>.
 <2>		04/30/02	Fix bug in creating the matching dictionary that caused the
 kIOPrimaryInterface property to be ignored. Clean up comments and add
 additional comments about how IOServiceGetMatchingServices operates.
 <1>	 	06/07/01	New sample.
 
 */

#import "SSYIOKit.h"
#include <IOKit/network/IOEthernetInterface.h>
#include <IOKit/network/IONetworkInterface.h>
#include <IOKit/network/IOEthernetController.h>
#import "NSData+SSYCryptoDigest.h"

static kern_return_t FindEthernetInterfaces(io_iterator_t *matchingServices);
CFDataRef CreateMACAddress(io_iterator_t intfIterator);

// Returns an iterator containing the primary (built-in) Ethernet interface. The caller is responsible for
// releasing the iterator after the caller is done with it.
static kern_return_t FindEthernetInterfaces(io_iterator_t *matchingServices)
{
    kern_return_t		kernResult; 
    CFMutableDictionaryRef	matchingDict;
    CFMutableDictionaryRef	propertyMatchDict;
    
    // Ethernet interfaces are instances of class kIOEthernetInterfaceClass. 
    // IOServiceMatching is a convenience function to create a dictionary with the key kIOProviderClassKey and 
    // the specified value.
    matchingDict = IOServiceMatching(kIOEthernetInterfaceClass);
	
    // Note that another option here would be:
    // matchingDict = IOBSDMatching("en0");
	
    if (NULL == matchingDict) {
		NSLog(@"FindEthernetInterfaces: IOServiceMatching returned a NULL dictionary.");
    }
    else {
        // Each IONetworkInterface object has a Boolean property with the key kIOPrimaryInterface. Only the
        // primary (built-in) interface has this property set to TRUE.
        
        // IOServiceGetMatchingServices uses the default matching criteria defined by IOService. This considers
        // only the following properties plus any family-specific matching in this order of precedence 
        // (see IOService::passiveMatch):
        //
        // kIOProviderClassKey (IOServiceMatching)
        // kIONameMatchKey (IOServiceNameMatching)
        // kIOPropertyMatchKey
        // kIOPathMatchKey
        // kIOMatchedServiceCountKey
        // family-specific matching
        // kIOBSDNameKey (IOBSDNameMatching)
        // kIOLocationMatchKey
        
        // The IONetworkingFamily does not define any family-specific matching. This means that in            
        // order to have IOServiceGetMatchingServices consider the kIOPrimaryInterface property, we must
        // add that property to a separate dictionary and then add that to our matching dictionary
        // specifying kIOPropertyMatchKey.
		
        propertyMatchDict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
													  &kCFTypeDictionaryKeyCallBacks,
													  &kCFTypeDictionaryValueCallBacks);
		
        if (NULL == propertyMatchDict) {
			NSLog(@"FindEthernetInterfaces: CFDictionaryCreateMutable returned a NULL dictionary.");
        }
        else {
            // Set the value in the dictionary of the property with the given key, or add the key 
            // to the dictionary if it doesn't exist. This call retains the value object passed in.
            CFDictionarySetValue(propertyMatchDict, CFSTR(kIOPrimaryInterface), kCFBooleanTrue); 
            
            // Now add the dictionary containing the matching value for kIOPrimaryInterface to our main
            // matching dictionary. This call will retain propertyMatchDict, so we can release our reference 
            // on propertyMatchDict after adding it to matchingDict.
            CFDictionarySetValue(matchingDict, CFSTR(kIOPropertyMatchKey), propertyMatchDict);
            CFRelease(propertyMatchDict);
        }
    }
    
    // IOServiceGetMatchingServices retains the returned iterator, so release the iterator when we're done with it.
    // IOServiceGetMatchingServices also consumes a reference on the matching dictionary so we don't need to release
    // the dictionary explicitly.
    kernResult = IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, matchingServices);    
    if (KERN_SUCCESS != kernResult) {
    }
	
    return kernResult;
}

// Given an iterator across a set of Ethernet interfaces, return the MAC address of the last one.
// If no interfaces are found the MAC address is set to an empty string.
// In this sample the iterator should contain just the primary interface.
CFDataRef CreateMACAddress(io_iterator_t intfIterator)
{
    io_object_t		intfService;
    io_object_t		controllerService;
    kern_return_t	kernResult = KERN_FAILURE;
    
	UInt8 MACAddress[kIOEthernetAddressSize] ;
	
	// Initialize the returned address
    bzero(MACAddress, kIOEthernetAddressSize);
	CFTypeRef	MACAddressAsCFData = NULL ;
	// = NULL was not in the original Apple code.  I added it after getting a report from a user
	// of a Hackintosh that +hashedMACAddress was crashing.  After getting a detailed log from
	// him using GetMACAddress, it confirmed that the following loop was not running; hence
	// MACAddressAsCFData was garbage, hence the crash later.
    
    // IOIteratorNext retains the returned object, so release it when we're done with it.
    while ((intfService = IOIteratorNext(intfIterator))) {
        // Memory leak fixed by Jerry Krinock in BookMacster 1.12:
        if (MACAddressAsCFData != NULL) {
            CFRelease(MACAddressAsCFData) ;
        }
        
        // IONetworkControllers can't be found directly by the IOServiceGetMatchingServices call,
        // since they are hardware nubs and do not participate in driver matching. In other words,
        // registerService() is never called on them. So we've found the IONetworkInterface and will 
        // get its parent controller by asking for it specifically.
        
        // IORegistryEntryGetParentEntry retains the returned object, so release it when we're done with it.
        kernResult = IORegistryEntryGetParentEntry(intfService,
												   kIOServicePlane,
												   &controllerService);
		
        if (KERN_SUCCESS != kernResult) {
			MACAddressAsCFData = NULL ;
        }
        else {
            // Retrieve the MAC address property from the I/O Registry in the form of a CFData
            MACAddressAsCFData = IORegistryEntryCreateCFProperty(controllerService,
																 CFSTR(kIOMACAddress),
																 kCFAllocatorDefault,
																 0);
			
            // Done with the parent Ethernet controller object so we release it.
            (void) IOObjectRelease(controllerService);
        }
        
        // Done with the Ethernet interface object so we release it.
        (void) IOObjectRelease(intfService);
    }
	
	return (MACAddressAsCFData) ;
}


@implementation SSYIOKit

+ (NSData*)primaryMACAddressOrMachineSerialNumberData {
    kern_return_t	kernResult = KERN_SUCCESS; // on PowerPC this is an int (4 bytes)
	/*
	 *	error number layout as follows (see mach/error.h and IOKit/IOReturn.h):
	 *
	 *	hi		 		       lo
	 *	| system(6) | subsystem(12) | code(14) |
	 */
	
    io_iterator_t	intfIterator;
	
    kernResult = FindEthernetInterfaces(&intfIterator);
    CFDataRef MACAddressData = NULL ;
	
    if (KERN_SUCCESS != kernResult) {
		NSLog(@"+[SSYIOKit primaryMACAddressOrMachineSerialNumberData]: FindEthernetInterfaces returned error, 0x%08lx", (long)kernResult) ;
    }
    else {
		MACAddressData = CreateMACAddress(intfIterator);
    }
	
	(void) IOObjectRelease(intfIterator);	// Release the iterator.
	
	if (MACAddressData == nil) {
		/* May be a Hackintosh.  Use email instead.  Until 2020-Apr-17 I used
         the email address of the primary user:
         ABPerson* me = [[ABAddressBook sharedAddressBook] me] ;
         ABMultiValue *emails = [me valueForProperty:kABEmailProperty];
         NSString* email = [emails valueAtIndex:[emails indexForIdentifier:[emails primaryIdentifier]]];
         if ((email != nil) && ([email length] > 7)) {
             MACAddressData = (CFDataRef)[[email dataUsingEncoding:NSUTF8StringEncoding] retain] ;
         }
         But then I started to get depracation warnings on AddressBook … use
         Contacts instead.  But after 15 minutes of research I cannot find
         any equivalent method in Contacts which would get the Contacts record
         of the logged-in user.  And even if there was such a method, I am sure
         it would be protected by a bunch of security hoops and/or roadblocks.
         
         So I decided to do this instead – get the machine serial number.  I
         remember reading somewhere that this was not a good idea for some
         reason – maybe if the motherboard is replaced.  But as a fallback
         in extreme edge cases, I think it is good enough.
         
         Instead of using two NSTasks as below, the following code could read
         in the whole ioRegTask output and filter for the desired line using
         Cocoa methods.  I tried that, and [task launch] hung.  This is
         probably too much data got put into the pipe (the output of ioReg -l
         is maybe thousnds of lines), and the pipe plugged up and stalled – I
         forget what the exact terminology is.  There is probably a way to deal
         with it, as I recall doing in Chromessenger, but it makes the
         following two-task method simpler: */
        NSTask* ioRegTask = [[NSTask alloc] init];
        NSTask* grepTask = [[NSTask alloc] init];

        [ioRegTask setLaunchPath: @"/usr/sbin/ioreg"];
        [grepTask setLaunchPath: @"/usr/bin/grep"];

        [ioRegTask setArguments: [NSArray arrayWithObjects: @"-l", nil]];
        [grepTask setArguments: [NSArray arrayWithObjects: @"IOPlatformSerialNumber", nil]];

        /* Connect the pipes */
        NSPipe *pipeBetween = [NSPipe pipe];
        [ioRegTask setStandardOutput: pipeBetween];
        [grepTask setStandardInput: pipeBetween];
        NSPipe *pipeToMe = [NSPipe pipe];
        [grepTask setStandardOutput: pipeToMe];

        NSFileHandle *grepOutput = [pipeToMe fileHandleForReading];

        [ioRegTask launch];
        [grepTask launch];
        [grepTask waitUntilExit];
        
        NSData *data = [grepOutput readDataToEndOfFile];
        [ioRegTask release];
        [grepTask release];
        NSString* targetLine = [[NSString alloc] initWithData:data
                                                     encoding:NSUTF8StringEncoding];
        if (targetLine.length > 0) {
            NSScanner* scanner = [[NSScanner alloc] initWithString:targetLine];
            NSString* serialString = nil;
            [scanner scanUpToString:@"=" intoString:NULL];
            [scanner scanUpToString:@"\"" intoString:NULL];
            scanner.scanLocation = scanner.scanLocation + 1;
            [scanner scanUpToString:@"\"" intoString:&serialString];
            [scanner release];
            NSData* data = [serialString dataUsingEncoding:NSUTF8StringEncoding];
            [data retain];
            MACAddressData = (CFDataRef)data;
        }
        [targetLine release];
	}
			
	return [(NSData*)MACAddressData autorelease] ;
}	

+ (NSData*)hashedMACAddress {
	NSData* macAddress = [SSYIOKit primaryMACAddressOrMachineSerialNumberData] ;
	NSData* hashedMACAddress = [macAddress sha1Digest] ;
	return hashedMACAddress ;
}

+ (NSData*)hashedMACAddressAndShortUserName {
    NSData* macAddress = [SSYIOKit primaryMACAddressOrMachineSerialNumberData];
    NSData* userNameData = [NSUserName() dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData* data = [macAddress mutableCopy];
    [data appendData:userNameData];
    NSData* hash = [data sha256Digest];
#if !__has_feature(objc_arc)
    [data release];
#endif
    return hash;
}

/*
+ (NSData*)machineSerialNumberData {
	NSString                   *result = @"";
	mach_port_t            masterPort;
	kern_return_t            kr = noErr;
	io_registry_entry_t    entry;        
	CFDataRef                 propData;
	CFTypeRef                 prop;
	CFTypeID                 propID;
	UInt8                     *data;
	unsigned int               i, bufSize;
	char                       *s, *t;
	char                       firstPart[64], secondPart[64];
	
	kr = IOMasterPort(MACH_PORT_NULL, &masterPort);                
	if (kr == noErr) {
		entry = IORegistryGetRootEntry(masterPort);
		if (entry != MACH_PORT_NULL) {
			prop = IORegistryEntrySearchCFProperty(entry, kIODeviceTreePlane,
												   CFSTR("serial-number"), NULL, kIORegistryIterateRecursively);
			propID =  CFGetTypeID(prop);
			if (propID == CFDataGetTypeID()) {
				propData = (CFDataRef)prop;
			}
			else {
				propData = NULL ;
			}
		}
		mach_port_deallocate(mach_task_self(), masterPort);
	}
	
	// Documentation for IORegistryEntrySearchCFProperty() says that caller should
	// release the returned result.  So, I autorelease prop before returning.
	return [(NSData*)propData autorelease] ;
}
*/

@end

/*
 File:			GetPrimaryMACAddress.c
	
 Description:	This sample application demonstrates how to do retrieve the Ethernet MAC
 address of the built-in Ethernet interface from the I/O Registry on Mac OS X.
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
#import <AddressBook/ABAddressBook.h>
#import <AddressBook/ABMultiValue.h>
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

+ (NSData*)primaryMACAddressData {
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
		NSLog(@"+[SSYIOKit primaryMACAddressData]: FindEthernetInterfaces returned error, 0x%08lx", (long)kernResult) ;
    }
    else {
		MACAddressData = CreateMACAddress(intfIterator);
    }
	
	(void) IOObjectRelease(intfIterator);	// Release the iterator.
	
	if (MACAddressData == nil) {
		// May be a Hackintosh.  Use email instead.
		// Starting with Mac OS X 10.8, -[ABAddressBook me] will produce an ugly warning
		// asking if it's OK for your app to access Contacts, and will block until
		// user dismisses the dialog.  But I figure that if someone
		// is using a Hackintosh, they should expect stuff like that.
		ABPerson* me = [[ABAddressBook sharedAddressBook] me] ;		
		ABMultiValue *emails = [me valueForProperty:kABEmailProperty]; 
		NSString* email = [emails valueAtIndex:[emails indexForIdentifier:[emails primaryIdentifier]]];
		if ((email != nil) && ([email length] > 7)) {
			MACAddressData = (CFDataRef)[[email dataUsingEncoding:NSUTF8StringEncoding] retain] ;
		}
	}
			
	return [(NSData*)MACAddressData autorelease] ;
}	

+ (NSData*)hashedMACAddress {
	NSData* macAddress = [SSYIOKit primaryMACAddressData] ;
	NSData* hashedMACAddress = [macAddress sha1Digest] ;
	return hashedMACAddress ;
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

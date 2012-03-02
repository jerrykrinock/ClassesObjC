#import "SSYShortcutActuator.h"
#import <Carbon/Carbon.h>
#import "NSUserDefaults+KeyPaths.h"
#import "SRCommon.h"

static SSYShortcutActuator* sharedActuator = nil ;

static const struct { char const* const name; unichar const glyph; } mapOfNamesForUnicodeGlyphs[] =
{
	// Constants defined in NSEvent.h that are expected to relate to unicode characters, but don't seen to translate properly
	{ "Up",           NSUpArrowFunctionKey },
	{ "Down",         NSDownArrowFunctionKey },
	{ "Left",         NSLeftArrowFunctionKey },
	{ "Right",        NSRightArrowFunctionKey },
	{ "Home",         NSHomeFunctionKey },
	{ "End",          NSEndFunctionKey },
	{ "Page Up",      NSPageUpFunctionKey },
	{ "Page Down",    NSPageDownFunctionKey },
	
	//      These are the actual values that these keys translate to
	{ "Up",                 0x1E },
	{ "Down",               0x1F },
	{ "Left",               0x1C },
	{ "Right",              0x1D },
	{ "Home",               0x1 },
	{ "End",                0x4 },
	{ "Page Up",    0xB },
	{ "Page Down",  0xC },
	{ "Return",             0x3 },
	{ "Tab",                0x9 },
	{ "Backtab",    0x19 },
	{ "Enter",              0xd },
	{ "Backspace",  0x8 },
	{ "Delete",             0x7F },
	{ "Escape",             0x1b },
	{ "Space",              0x20 }
	
};

NSString* const SSYShortcutActuatorKeyBindings = @"SSYShortcutActuatorKeyBindings" ;

NSString* const constKeyKeyCode = @"keyCode" ;
NSString* const constKeyModifierFlags = @"modifierFlags" ;
NSString* const constKeyHotKeySerialNumber = @"hotKeySerialNumber" ;
NSString* const constKeyHotKeyReference = @"hotKeyReference" ;
NSString* const constKeyHandlerReference = @"handlerReference" ;

static NSString* const constErrorsHeader = @"  See HIToolbox/CarbonEventsCore.h for error codes." ;

NSString* const SSYShortcutActuatorDidNonemptyNotification = @"SSYShortcutActuatorDidNonemptyNotification" ;
NSString* const SSYShortcutActuatorDidEmptyNotification = @"SSYShortcutActuatorDidEmptyNotification" ;


@interface SSYShortcutActuator ()

@property (assign) BOOL isHandlerInstalled ;

+ (NSString*)stringForKeyCode:(NSInteger)keyCode
				modifierFlags:(NSUInteger)modifierFlags ;
+ (NSString*)descriptionOfModifiers:(NSUInteger)modifiers ;

@end

OSStatus SSYShortcutActuate(
							EventHandlerCallRef nextHandler,
							EventRef carbonEvent,
							void* userData) {
	EventHotKeyID hotKeyID ;
	OSStatus status ;
	status = GetEventParameter (
								carbonEvent,
								kEventParamDirectObject,
								typeEventHotKeyID,
								NULL,
								sizeof(EventHotKeyID),
								NULL,
								&hotKeyID) ;
	if (status == noErr) {
		NSDictionary* selectorNameLookup = (NSDictionary*)userData ;
		NSString* selectorName = [selectorNameLookup objectForKey:[NSNumber numberWithUnsignedLong:hotKeyID.id]] ;
		SEL selector = NSSelectorFromString(selectorName) ;
		if ([[NSApp delegate] respondsToSelector:selector]) {
			[[NSApp delegate] performSelector:selector] ;
			status = noErr ;
		}
		else {
			NSLog(@"Internal Error 501-2832  App Delegate does not respond to selector %@", selectorName) ;
			NSBeep() ;
			status = -1 ;
		}
	}
	else {
		NSLog(@"Internal Error 501-2855  Could not get hot key ID from event") ;
	}
	
	return status ;
}


@implementation SSYShortcutActuator

#define NumberOfUnicodeGlyphReplacements 24

+ (NSString *)stringForKeyCode:(NSInteger)keyCode
				 modifierFlags:(NSUInteger)modifierFlags {
	modifierFlags = SRCocoaToCarbonFlags(modifierFlags) ;
	TISInputSourceRef currentKeyboard = TISCopyCurrentKeyboardInputSource();
	CFDataRef uchr = (CFDataRef)TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData);
	const UCKeyboardLayout *keyboardLayout = (const UCKeyboardLayout*)CFDataGetBytePtr(uchr);
	
	if(keyboardLayout) {
		UInt32 deadKeyState = 0 ;
		UniCharCount maxStringLength = 255 ;
		UniCharCount actualStringLength = 0 ;
		UniChar unicodeString[maxStringLength] ;
		
		OSStatus status = UCKeyTranslate(keyboardLayout,
										 keyCode, kUCKeyActionDown, modifierFlags,
										 LMGetKbdType(), 0,
										 &deadKeyState,
										 maxStringLength,
										 &actualStringLength, unicodeString) ;
		
		if(status != noErr) {
			return [NSString stringWithFormat:
					@"Error %ld %s : %s for key code '%ld'.",
					status,
					GetMacOSStatusErrorString(status),
					GetMacOSStatusCommentString(status),
					keyCode] ;
		}
		else if(actualStringLength > 0) {
			// Replace certain characters with user friendly names, e.g. Space, Enter, Tab etc.
			NSUInteger i = 0 ;
			while(i <= NumberOfUnicodeGlyphReplacements) {
				if(mapOfNamesForUnicodeGlyphs[i].glyph == unicodeString[0]) {
					return [NSString stringWithFormat:
							@"%s",
							mapOfNamesForUnicodeGlyphs[i].name] ;
				}
				i++ ;
			}
			
			return [NSString stringWithCharacters:unicodeString length:(NSInteger)actualStringLength] ;
		}
		else {
			NSLog(@"<Unknown keyCode=%d>", keyCode) ;
		}
	}
	else {
		NSLog(@"<Unknown keyboard layout>") ;
	}
	
	return nil ;
}

+ (NSString*)stringForKeyCode:(NSInteger)keyCode {
	NSString* string = [self stringForKeyCode:keyCode
								modifierFlags:0]  ;
	if ([string length] == 1) {
		string = [string uppercaseString] ;
	}
	
	return string ;
}

+ (NSString*)descriptionOfModifiers:(NSUInteger)modifiers {
	NSMutableString* string = [[NSMutableString alloc] init] ;
	if (modifiers & NSCommandKeyMask) [string appendString:@"cmnd+"] ;
	if (modifiers & NSAlternateKeyMask) [string appendString:@"optn+"] ;
	if (modifiers & NSControlKeyMask) [string appendString:@"ctrl+"] ;
	if (modifiers & NSShiftKeyMask) [string appendString:@"shft+"] ;
	if (modifiers & NSFunctionKeyMask) [string appendString:@"func+"] ;
	
	NSString* answer = [NSString stringWithString:string] ;
	[string release] ;
	
	return answer ;
}

@synthesize isHandlerInstalled = m_isHandlerInstalled ;

- (NSMutableDictionary*)selectorNameLookup {
	if (!m_selectorNameLookup) {
		m_selectorNameLookup = [[NSMutableDictionary alloc] init] ;
	}
	
	return m_selectorNameLookup ;
}

#pragma mark * Accessors for the Registered Shortcuts Dictionary

- (void)addRegisteredShortcutInfo:(NSDictionary*)info
				forSelectorName:(NSString*)name {
	if (!m_registeredShortcutInfos) {
		m_registeredShortcutInfos = [[NSMutableDictionary alloc] init] ;
	}
	
	[m_registeredShortcutInfos setObject:info
							 forKey:name] ;
}

- (void)removeAllRegisteredShortcutInfos {
	[m_registeredShortcutInfos release] ;
	m_registeredShortcutInfos = nil ;
	
	[m_selectorNameLookup removeAllObjects] ;
}

- (void)removeRegisteredShortcutInfoForSelectorName:(NSString*)name {
	[m_registeredShortcutInfos removeObjectForKey:name] ;
	if ([m_registeredShortcutInfos count] == 0) {
		[self removeAllRegisteredShortcutInfos] ;
	}
	
	NSDictionary* selectorNamesLookupCopy = [m_selectorNameLookup copy] ;
	for (NSNumber* serialNumber in selectorNamesLookupCopy) {
		NSString* selectorName = [m_selectorNameLookup objectForKey:serialNumber] ;
		if ([selectorName isEqualToString:name]) {
			[m_selectorNameLookup removeObjectForKey:serialNumber] ;
		}
	}
	[selectorNamesLookupCopy release] ;
}

- (NSDictionary*)registeredShortcutInfos {
	return [NSDictionary dictionaryWithDictionary:m_registeredShortcutInfos] ;
}

- (NSUInteger)countOfRegisteredShortcuts {
	return [m_registeredShortcutInfos count] ;
}

#pragma mark * Other Methods

- (void)postDidEmpty:(BOOL)didEmpty {
	NSString* name = didEmpty ? SSYShortcutActuatorDidEmptyNotification : SSYShortcutActuatorDidNonemptyNotification ;
	[[NSNotificationCenter defaultCenter] postNotificationName:name
														object:self] ;
}

- (void)unregisterShortcutWithInfo:(NSDictionary*)info {
	OSStatus status ;
	
	EventHotKeyRef hotKeyRef = [[info objectForKey:constKeyHotKeyReference] pointerValue] ;
	if (hotKeyRef) {
		status = UnregisterEventHotKey(hotKeyRef) ;
		if (status != noErr) {
			NSLog(@"Internal Error 624-8537  Error %ld removing hot key for hotKeyRef %p with info %@%@",
				  status,
				  hotKeyRef,
				  info,
				  constErrorsHeader) ;
		}
	}
	
	if ([self countOfRegisteredShortcuts] == 0) {
		EventHandlerRef handlerRef = [[info objectForKey:constKeyHandlerReference] pointerValue] ;
		if (handlerRef) {
			status = RemoveEventHandler(handlerRef) ;
			if (status == noErr) {
				[self setIsHandlerInstalled:NO] ;
				[self postDidEmpty:YES] ;
			}
			else {
				NSLog(@"Internal Error 624-8538  Error %ld removing handler for handlerRef %p with info %@.%@",
					  status,
					  handlerRef,
					  info,
					  constErrorsHeader) ;
			}
		}
	}
}

- (void)unregisterShortcutForSelectorName:(NSString*)name {
	[self unregisterShortcutWithInfo:[[self registeredShortcutInfos] objectForKey:name]] ;
}

- (void)unregisterAllShortcuts {
	for (NSDictionary* info in [[self registeredShortcutInfos] allValues]) {
		[self unregisterShortcutWithInfo:info] ;
	}
}

- (NSDictionary*)registerShortcutWithInfo:(NSDictionary*)info
							 selectorName:(NSString*)selectorName {
	NSNumber* number ;
	
	number = [info objectForKey:constKeyKeyCode] ;
	NSInteger keyCode ;
	if ([number respondsToSelector:@selector(integerValue)]) {
		keyCode = [number integerValue] ;
		if (keyCode < 0) {
			return nil ;
		}
	}
	else {
		return nil ;
	}
	
	number = [info objectForKey:constKeyModifierFlags] ;
	NSUInteger modifiers ;
	if ([number respondsToSelector:@selector(unsignedIntegerValue)]) {
		modifiers = [number unsignedIntegerValue] ;
	}
	else {
		return nil ;
	}
	modifiers = SRCocoaToCarbonFlags(modifiers) ;
	
	EventHotKeyID hotKeyID ;
	EventTypeSpec eventType ;
	eventType.eventClass = kEventClassKeyboard ;
	eventType.eventKind = kEventHotKeyPressed ;
	EventHandlerUPP handler = &SSYShortcutActuate ;
	
	hotKeyID.id = ++m_shortcutSerialNumber ;
	EventTargetRef thisAppEventTarget = GetApplicationEventTarget() ;
	EventHotKeyRef hotKeyRef = NULL ;
	EventHandlerRef handlerRef = NULL ;
	
	[[self selectorNameLookup] setObject:selectorName
								  forKey:[NSNumber numberWithUnsignedLong:m_shortcutSerialNumber]] ;
	
	OSStatus status ;
	
	if ([self isHandlerInstalled] == YES) {
		status = noErr ;
	}
	else {
		void* userData = [self selectorNameLookup] ;
		status = InstallEventHandler(
									 thisAppEventTarget,  // in, target which will receive hot key events
									 handler,             // in, pointer to handler function which will receive events
									 1,                   // in, number of event types
									 &eventType,          // in, list of event types
									 userData,            // in, userData
									 &handlerRef) ;       // out, reference to handler which was created
	}
	
	if (status == noErr) {
		[self setIsHandlerInstalled:YES] ;
		
		//NSString* signature = [@"hk" stringByAppendingFormat:@"%02x", (hotKeyID.id % 0x100)] ;
		/* The declaration of the EventHotKeyID struct does not explain the value
		 of its 'signature' member.  There is an explanation of the signature of
		 a similar (but deprecated) struct…
		 *    The client signature should be any unique
		 *    four-character constant that does not have entirely lowercase
		 *    characters; a good choice is the usual DTS-registered creator
		 *    OSType, but you can use any constant that you like."
		 OK, we'll use this… */
		NSString* signature = @"SSYS" ;
		hotKeyID.signature = UTGetOSTypeFromString((CFStringRef)signature) ;
		
		status = RegisterEventHotKey(
									 keyCode,
									 modifiers,
									 hotKeyID,
									 thisAppEventTarget,
									 0,
									 &hotKeyRef) ;
		if (status != noErr) {
			NSLog(@"Internal Error 624-9877.  Error %ld RegisterEventHotKey %d 0x%x %ld %p %p.%@",
				  status,
				  keyCode,
				  modifiers,
				  hotKeyID.id,
				  thisAppEventTarget,
				  hotKeyRef,
				  constErrorsHeader) ;
		}
		
	}
	else {
		NSLog(@"Internal Error 624-9878.  Error %ld InstallEventHandler %d 0x%x %ld %p %p.%@",
			  status,
			  keyCode,
			  modifiers,
			  hotKeyID.id,
			  thisAppEventTarget,
			  handlerRef,
			  constErrorsHeader) ;
	}
	
	NSDictionary* newInfo = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSValue valueWithPointer:hotKeyRef], constKeyHotKeyReference,
							 [NSValue valueWithPointer:handlerRef], constKeyHandlerReference,
							 [NSNumber numberWithUnsignedLong:m_shortcutSerialNumber], constKeyHotKeySerialNumber,
							 nil] ;

	return newInfo ;
}

- (void)enableAllShortcuts {
	NSUserDefaults* sud = [NSUserDefaults standardUserDefaults] ;
	// Use -respondsToSelector: since one should never trust anything
	// that comes out of user defaults
	NSDictionary* shortcutInfos = [sud objectForKey:SSYShortcutActuatorKeyBindings] ;
	if ([shortcutInfos respondsToSelector:@selector(objectForKey:)]) {
		for (NSString* selectorName in shortcutInfos) {
			NSDictionary* infoLaUserDefaults = [shortcutInfos objectForKey:selectorName] ;
			if ([infoLaUserDefaults respondsToSelector:@selector(objectForKey:)]) {
				if ([[self registeredShortcutInfos] objectForKey:selectorName] == nil) {
					// This shortcut is not currently registered and thus needs to be registered
					NSDictionary* infoLaInstall = [self registerShortcutWithInfo:infoLaUserDefaults
																	selectorName:selectorName] ;
					
					// Add to Registered Shortcut Infos dictionary
					[self addRegisteredShortcutInfo:infoLaInstall
									forSelectorName:selectorName] ;
				}
			}
		}
	}
}

- (void)dealloc {
	[m_registeredShortcutInfos release] ;
	[m_selectorNameLookup release] ;
	
	[super dealloc] ;
}


+ (SSYShortcutActuator*)sharedActuator {
	@synchronized(self) {
        if (!sharedActuator) {
            sharedActuator = [[self alloc] init] ;
        }
    }
	
	// No autorelease.  This sticks around forever.
    return sharedActuator ;
}

- (KeyCombo)keyComboForSelectorName:(NSString*)selectorName {
	KeyCombo keyCombo ;
	NSUserDefaults* sud = [NSUserDefaults standardUserDefaults] ;
	// Use -respondsToSelector: since one should never trust anything
	// that comes out of user defaults
	NSDictionary* shortcutInfos = [sud objectForKey:SSYShortcutActuatorKeyBindings] ;
	if ([shortcutInfos respondsToSelector:@selector(objectForKey:)]) {
		NSDictionary* shortcutInfo = [shortcutInfos objectForKey:selectorName] ;
		if ([shortcutInfo respondsToSelector:@selector(objectForKey:)]) {
			NSNumber* number ;
			
			number = [shortcutInfo objectForKey:constKeyKeyCode] ;
			if ([number respondsToSelector:@selector(integerValue)]) {
				keyCombo.code = [number integerValue] ;
			}
			else {
				keyCombo.code = -1 ;
			}

			number = [shortcutInfo objectForKey:constKeyModifierFlags] ;
			if ([number respondsToSelector:@selector(unsignedIntegerValue)]) {
				keyCombo.flags = [number unsignedIntegerValue] ;
			}
			else {
				keyCombo.flags = 0 ;
			}
		}
		else {
			keyCombo.code = -1 ;
			keyCombo.flags = 0 ;
		}
	}
	
	return keyCombo ;
}

- (void)disableAllShortcuts {
	[self unregisterAllShortcuts] ;
	[self removeAllRegisteredShortcutInfos] ;
}

- (void)postDidNonemptyIfNeeded {
	NSUserDefaults* sud = [NSUserDefaults standardUserDefaults] ;
	// Use -respondsToSelector: since one should never trust anything
	// that comes out of user defaults
	NSDictionary* shortcutInfos = [sud objectForKey:SSYShortcutActuatorKeyBindings] ;
	if ([shortcutInfos respondsToSelector:@selector(objectForKey:)]) {
		for (NSString* selectorName in shortcutInfos) {
			NSDictionary* info = [shortcutInfos objectForKey:selectorName] ;
			if ([info respondsToSelector:@selector(objectForKey:)]) {
				[self postDidEmpty:NO] ;
				return ;
			}
		}
	}
}


- (id)init {	
	self = [super init] ;
	
	// There is no need to activate shortcuts now, because the active
	// app is, duh, this app.  Shortcuts should only be active while
	// a web browser is active.  We'll get a notification from
	// NSWorkspace when that happens.
	
	[self postDidNonemptyIfNeeded] ;
	
	return self ;
}

- (void)setKeyCode:(NSInteger)keyCode
	 modifierFlags:(NSUInteger)modifierFlags
	  selectorName:(NSString*)selectorName {
	// In case we already have installed a shortcut for this selector, we remove it

	// #1.  Remove from Registered Shortcuts dictionary
	[self removeRegisteredShortcutInfoForSelectorName:selectorName] ;
	
	// It is important that we do #1 before #2, because #2 will uninstall our handler
	// only if it sees that there are no more Registered shortcuts.

	// #3.  Unregister in Mac OS X
	[self unregisterShortcutForSelectorName:selectorName] ;

	// #4.  Remove from User Defaults
	[[NSUserDefaults standardUserDefaults] removeKey:selectorName
								 fromDictionaryAtKey:SSYShortcutActuatorKeyBindings] ;
	
	if (keyCode >=0) {
		//  Add to User Defaults
		NSDictionary* infoLaUserDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithUnsignedLong:keyCode], constKeyKeyCode,
											[NSNumber numberWithUnsignedLong:modifierFlags], constKeyModifierFlags,
											nil] ;
		NSString* keyPath = [NSString stringWithFormat:
							 @"%@.%@",
							 SSYShortcutActuatorKeyBindings,
							 selectorName] ;
		[[NSUserDefaults standardUserDefaults] setValue:infoLaUserDefaults
											 forKeyPath:keyPath] ;
		
		// Since we've got at least one shortcut now, start observing
		[self postDidEmpty:NO] ;
	}
}

@end
#import "SSYListPicker.h"
#import "SSYAlert.h"
#import "SSYLabelledList.h"
#import "NSString+LocalizeSSY.h"
#import "NS(Attributed)String+Geometrics.h"

NSString* constKeyDidEndTarget = @"didEndTarget" ;
NSString* constKeyDidEndSelectorName = @"didEndSelectorName" ;
NSString* constKeyDidEndUserInfo = @"didEndUserInfo" ;
NSString* constKeyDidCancelInvocation = @"didCancelInvocation" ;

@interface SSYListPicker ()

@property (retain) SSYAlert* alert ;

@end

@implementation SSYListPicker

@synthesize alert = m_alert ;

+ (SSYListPicker*)listPicker {
	return [[[SSYListPicker alloc] init] autorelease] ;
}

- (void)dealloc {
	[m_alert release] ;

	[super dealloc] ;
}

- (void)userPickFromList:(NSArray*)displayNames
				toolTips:(NSArray*)toolTips
		   lineBreakMode:(NSLineBreakMode)lineBreakMode
				 message:(NSString*)message
  allowMultipleSelection:(BOOL)allowMultipleSelection
	 allowEmptySelection:(BOOL)allowEmptySelection
			button1Title:(NSString*)button1Title
			button2Title:(NSString*)button2Title
			initialPicks:(NSIndexSet*)initialPicks
			 windowTitle:(NSString*)windowTitle
				   alert:(SSYAlert*)alert
				runModal:(BOOL)runModal
			didEndTarget:(id)didEndTarget
		  didEndSelector:(SEL)didEndSelector
		  didEndUserInfo:(id)didEndUserInfo
	 didCancelInvocation:(NSInvocation*)didCancelInvocation {	
	if (
		allowMultipleSelection
		&&
		([displayNames count] > 1)
		) {
		message = [message stringByAppendingFormat:
				   @"\n\n%@",
				   [NSString localizeFormat:@"selectMultipleHow", 0x2318]
				   ] ;
	}
	if (!button1Title) {
		button1Title = [NSString localize:@"ok"] ;
	}
	if (!button2Title) {
		button2Title = [NSString localize:@"cancel"] ;
	}
	
	CGFloat width = 0.0 ;
	for (NSString* displayName in displayNames) {
		width = MAX(width, [displayName widthForHeight:20.0
												  font:[SSYLabelledList tableFont]]) ;
	}
	width = MAX(width, 16 * sqrt([message length])) ;
	
	if (!alert) {
		alert = [SSYAlert alert] ;
	}
	[self setAlert:alert] ;
	
	SSYLabelledList* list = [SSYLabelledList listWithLabel:message
												   choices:displayNames
												  toolTips:toolTips
											 lineBreakMode:lineBreakMode
											maxTableHeight:500.0] ;
	[list setAllowsMultipleSelection:allowMultipleSelection] ;
	[list setAllowsEmptySelection:allowEmptySelection] ;
	[list setSelectedIndexes:initialPicks] ;
	[list setTableViewDelegate:self] ;
	[alert addOtherSubview:list
				   atIndex:0] ;
	[alert setWindowTitle:windowTitle] ;
	[alert setButton1Title:button1Title] ;
	[alert setButton2Title:button2Title] ;
	[alert setButton3Title:[NSString localizeFormat:
							@"clearX",
							[NSString localize:@"selection"]]] ;
	[alert setRightColumnMinimumWidth:MIN(width, 700)] ;
	[alert setIconStyle:SSYAlertIconInformational] ;
	[alert setClickTarget:self] ;
	[alert setClickSelector:@selector(handleClickInAlert:)] ;
	[alert setShouldStickAround:YES] ;
	//  I think this was added in BookMacster 1.7.3 or, more likely, 1.8.  I forgot why, except that it was definitely needed…
	[NSApp activateIgnoringOtherApps:YES] ;
	NSMutableDictionary* didEndInfo = [NSMutableDictionary dictionary] ;
	[didEndInfo setValue:didEndTarget
				  forKey:constKeyDidEndTarget] ;
	[didEndInfo setValue:NSStringFromSelector(didEndSelector)
				  forKey:constKeyDidEndSelectorName] ;
	[didEndInfo setValue:didEndUserInfo
				  forKey:constKeyDidEndUserInfo] ;
	[didEndInfo setValue:didCancelInvocation
				  forKey:constKeyDidCancelInvocation] ;
	[alert setClickObject:didEndInfo] ;
	[alert display] ;
	if (runModal) {
		[alert runModalSession] ;
	}
}

- (void)handleClickInAlert:(SSYAlert*)alert {
	BOOL done = NO ;
	BOOL proceed = NO ;
	NSIndexSet* selectedIndexSet = nil ;
	
	[alert endModalSession] ;
	
	if ([alert alertReturn] == NSAlertDefaultReturn) {
		// Clicked "OK" or "Done"
		selectedIndexSet = [[[alert otherSubviews] objectAtIndex:0] selectedIndexes] ;
		done = YES ;
		proceed = YES ;
	}
	else if ([alert alertReturn] == NSAlertAlternateReturn) {
		// Clicked "Cancel"
		done = YES ;
	}
	else {
		// Clicked "Clear Selection"
		[[[alert otherSubviews] objectAtIndex:0] setSelectedIndexes:[NSIndexSet indexSet]] ;
	}
	
	// Need to grab this before popping the configuration
	NSDictionary* clickDic = [alert clickObject] ;

	if (done) {
		[alert goAway] ;
		
		// Needed to break retain cycle:
		[self setAlert:nil] ;
	}
	
	if (proceed) {
		id target = [clickDic objectForKey:constKeyDidEndTarget] ;
		if (target) {
			SEL selector = NSSelectorFromString([clickDic objectForKey:constKeyDidEndSelectorName]) ;
			[target performSelector:selector
						 withObject:selectedIndexSet
						 withObject:[clickDic objectForKey:constKeyDidEndUserInfo]] ;
		}
	}
	
	if (done && !proceed) {
		[[clickDic objectForKey:constKeyDidCancelInvocation] invoke] ;
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSTableView* tableView = [notification object] ;
	SSYAlert* alert = [[[tableView enclosingScrollView] window] windowController] ;

	BOOL weHaveASelection = ([[tableView selectedRowIndexes] count] > 0) ;

	BOOL ok = (weHaveASelection || [tableView allowsEmptySelection]) ;
	[alert setButton1Enabled:ok] ;
	[alert setButton3Enabled:ok] ;
}


@end
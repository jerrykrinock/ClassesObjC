@interface SSRolloverButton : NSButton {
}
@end

@interface SSProgTextField : NSControl {
	NSProgressIndicator* _progBar ;
	NSTextField* _textField ;
	SSRolloverButton* _hyperButton ;
	SSRolloverButton* _cancelButton ;
	NSRect _wholeFrame ;
	int progBarLimit ;
	NSTimeInterval _nextProgressUpdate ;
}

- (void)setVerb:(NSString*)newVerb
		 resize:(BOOL)resize ;
- (void)setProgressBarWidth:(float)width ;
- (void)setHasCancelButtonWithTarget:(id)target
							  action:(SEL)action ;
// To show determinate progress
- (void)setMaxValue:(double)value ;
	// also sets it to determinate
- (void)setIndeterminate:(BOOL)yn ;
- (void)setDoubleValue:(double)value ;
- (void)incrementDoubleValueBy:(double)value ;
- (void)incrementDoubleValueByObject:(NSNumber*)value ;

// The following methods configuration methods will invoke
// -display to display immediately

- (void)displayClearAll ;
- (void)displayIndeterminate:(BOOL)indeterminate
		 withLocalizableVerb:(NSString*)localizableVerb ; 
// localizableVerb will be localized and an ellipsis appended.
// It will be displayed alongside the progress bar.
- (void)displayIndeterminate:(BOOL)indeterminate
		   withLocalizedVerb:(NSString*)localizableVerb ; 
// localizedVerb will have ellipsis appended.
// It will be displayed alongside the progress bar.
- (void)displayOnlyText:(NSString*)text
			  hyperText:(NSString*)hyperText
				 target:(id)target
				 action:(SEL)action ;
	// text may be nil
	// hyperText may be nil
	// target and action may be nil if hyperText is nil.

@end

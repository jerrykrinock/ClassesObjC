- (void)setArray:(NSArray*)array sender:(id)sender ;

@end

@interface SSTableKit : NSView {
	IBOutlet id textTop ;
	IBOutlet id table ;
	IBOutlet id buttonMinus ;
	IBOutlet id buttonPlus ;

	NSArrayController* _arrayController ;
	id _defaultNewObject ;
	id _dataStore ;  // The data source behind the table's dataSource
}

- (void)setArray:(id)array ;

- (void)setTopText:(NSString*)topText
    defaultNewItem:(id)defaultNewObject 
		 dataStore:(id <SSTableDataStore>)dataStore ;

@end
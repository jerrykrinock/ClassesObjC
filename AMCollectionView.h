//
//  AMCollectionView.h
//  AMCollectionViewTest
//
//  Created by Andreas on 19.11.07.
//  Copyright 2007 Andreas Mayer. All rights reserved.
//

//  functionality is similar to NSCollectionView
//  - handles rows only for now
//  - no constraints for number of rows or view sizes


#import <Cocoa/Cocoa.h>

@class AMCollectionViewItem;


@interface AMCollectionView : NSControl {
	IBOutlet AMCollectionViewItem *itemPrototype;
	NSArray *backgroundColors;
	NSArray *content;
	BOOL selectable;
	BOOL allowsMultipleSelection;
	NSDictionary *am_itemsForObjects;
	BOOL am_needsLayout;
	NSData *am_archivedItemPrototype;
	BOOL am_itemRespondsToSizeForViewWithProposedSize;
	BOOL am_drawsBackground;
	BOOL usesAlternatingRowBackgroundColors;
	NSColor *selectedRowColor;
	NSColor *secondarySelectedRowColor;
	BOOL am_initializing;
	CGFloat rowHeight;
	BOOL am_isFirstResponder;
}

- (AMCollectionViewItem *)itemPrototype;
- (void)setItemPrototype:(AMCollectionViewItem *)value;

- (NSArray *)backgroundColors;
- (void)setBackgroundColors:(NSArray *)value;

- (CGFloat)rowHeight;
- (void)setRowHeight:(CGFloat)value;

- (NSArray *)content;
- (void)setContent:(NSArray *)value
		 itemClass:(Class)itemClass;

- (NSIndexSet *)selectionIndexes;
- (void)setSelectionIndexes:(NSIndexSet *)value;

- (BOOL)isSelectable;
- (void)setSelectable:(BOOL)value;

- (BOOL)allowsMultipleSelection;
- (void)setAllowsMultipleSelection:(BOOL)value;

- (BOOL)drawsBackground;
- (void)setDrawsBackground:(BOOL)value;

- (BOOL)usesAlternatingRowBackgroundColors;
- (void)setUsesAlternatingRowBackgroundColors:(BOOL)value;

- (NSColor *)selectedRowColor;
- (void)setSelectedRowColor:(NSColor *)value;

- (NSColor *)secondarySelectedRowColor;
- (void)setSecondarySelectedRowColor:(NSColor *)value;

- (BOOL)isFirstResponder;

- (AMCollectionViewItem *)newItemForRepresentedObject:(id)object;

- (AMCollectionViewItem *)itemForObject:(id)object;

- (id)objectForView:(NSView*)view ;

- (NSArray *)selectedObjects;
- (void)selectItemsForObjects:(NSArray *)objects;

- (void)deselectAll:(id)sender;

- (void)noteSizeForItemsChanged:(NSArray *)items;

- (void)scrollObjectToVisible:(id)object;


@end


APPKIT_EXTERN NSString *const AMCollectionViewSelectionDidChangeNotification;


@interface NSObject (AMCollectionViewDelegate)
- (void)collectionViewSelectionDidChange:(NSNotification *)aNotification;
@end

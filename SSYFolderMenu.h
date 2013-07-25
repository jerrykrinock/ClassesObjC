#import <Cocoa/Cocoa.h>

@protocol SSYFolderItemRepresentedObject

- (NSInteger)lineageDepth ;

@end


/*!
 @brief    A subclass of NSMenu which has overridden -insertItemWithTitle::::
 to insert a subclass of NSMenuItem which has its icon a folder icon and
 which has as its indentation a multiple of the -lineageDepth of its
 represented objects.
 
 @details  The represented objects of the items inserted into this menu
 must conform to the protocol SSYFolderItemRepresentedObject.
 
 A flattened-but-indented hierarchical menu is used in three
 places in BookMacster.  In BkmxDoc.xib ▸ Settings ▸ New Bookmark Landing,
 I use a StarkContainersFlatMenu, which is populated dynamically.  I tried
 to use that in TalderMapsController.xib, in the two "Folder" columns in the
 tables, but couldn't get it to work with bindings.  So in those cases I
 subclassed NSMenu and NSMenuItem to SSYFolderMenu and SSYFolderMenuItem.
*/ 
@interface SSYFolderMenu : NSMenu

@end

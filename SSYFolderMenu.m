#import "SSYFolderMenu.h"

@interface SSYFolderMenuItem : NSMenuItem

@end

@implementation SSYFolderMenuItem

- (NSImage*)image {
    return [NSImage imageNamed:@"folder.tif"] ;
}

- (NSInteger)indentationLevel {
    return [[self representedObject] lineageDepth] ;
}

@end


@implementation SSYFolderMenu

- (NSMenuItem *)insertItemWithTitle:(NSString*)title
                             action:(SEL)action
                      keyEquivalent:(NSString*)keyEquiv
                            atIndex:(NSInteger)index {
    NSMenuItem* item = [[SSYFolderMenuItem alloc] initWithTitle:title
                                                         action:action
                                                  keyEquivalent:keyEquiv] ;
    [self insertItem:item
             atIndex:index] ;
    [item release] ;
    
    return item ;
}

@end

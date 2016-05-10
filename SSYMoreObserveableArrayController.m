#import "SSYMoreObserveableArrayController.h"

@interface SSYMoreObserveableArrayController ()

@property (assign) BOOL hasSelection ;

@end


@implementation SSYMoreObserveableArrayController

- (void)dealloc {
    [self removeObserver:self
              forKeyPath:@"selectedObjects"] ;
    
#if !__has_feature(objc_arc)
    [super dealloc] ;
#endif
}

- (void)awakeFromNib {
    // Per Discussion in documentation of -[NSObject respondsToSelector:].
    // the superclass name in the following must be hard-coded.
    if ([NSArrayController instancesRespondToSelector:@selector(awakeFromNib)]) {
        [super awakeFromNib] ;
    }
    
    [self addObserver:self
           forKeyPath:@"selectedObjects"
              options:0
              context:NULL] ;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"selectedObjects"]) {
        NSInteger selectionCount = [[self selectedObjects] count] ;
        [self setHasSelection:(selectionCount > 0)] ;
    }
    
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context] ;
}

@end

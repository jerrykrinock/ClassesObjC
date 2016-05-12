#import "SSYMoreObserveableArrayController.h"

@interface SSYMoreObserveableArrayController ()

@property (assign) BOOL hasSelection ;
@property (assign) NSInteger countOfArrangedObjects ;

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
              context:[self class]] ;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ((context == [self class]) && [keyPath isEqualToString:@"selectedObjects"]) {
        NSInteger selectionCount = [[self selectedObjects] count] ;
        BOOL hasSelection = (selectionCount > 0) ;
        self.hasSelection = hasSelection ;
        /*SSYDBL*/ NSLog(@"   set hasSelection to %hhd", self.hasSelection) ;
    }
    
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context] ;
}

- (void)rearrangeObjects {
    [super rearrangeObjects] ;
    
    self.countOfArrangedObjects = ((NSArray*)self.arrangedObjects).count ;
    /*SSYDBL*/ NSLog(@"   set countOfArrangedObjects to %ld", self.countOfArrangedObjects) ;
}

@end

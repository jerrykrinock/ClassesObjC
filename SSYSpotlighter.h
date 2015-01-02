#import <Foundation/Foundation.h>

@class SSYSpotlighter ;

@protocol SSYSpotlighterDelegate <NSObject>

- (void)spotlighter:(SSYSpotlighter*)spotlighter
       didFindPaths:(NSArray*)paths ;
- (void)didFinishSpotlighter:(SSYSpotlighter*)spotlighter ;

@end

@interface SSYSpotlighter : NSObject {
    NSString* m_searchKey ;
    NSObject <SSYSpotlighterDelegate> * m_delegate ;
    NSMetadataQuery* m_query ;
    NSUInteger m_resultsAlreadyReported ;
}

- (id)initWithSearchKey:(NSString*)searchKey
               delegate:(NSObject <SSYSpotlighterDelegate> *)delegate ;

- (void)start ;

@end

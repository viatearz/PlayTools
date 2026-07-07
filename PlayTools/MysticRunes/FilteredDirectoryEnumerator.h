//
//  FilteredDirectoryEnumerator.h
//  PlayTools
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^DirectoryEnumeratorFilterBlock) (NSString *path);

@interface FilteredDirectoryEnumerator : NSDirectoryEnumerator

@property (nonatomic, strong, readonly) NSDirectoryEnumerator *wrappedEnumerator;
@property (nonatomic, copy, readonly) DirectoryEnumeratorFilterBlock filter;

- (instancetype) init NS_UNAVAILABLE;

- (instancetype) initWithEnumerator:(NSDirectoryEnumerator *) enumerator
                             filter:(DirectoryEnumeratorFilterBlock) filter;

@end

NS_ASSUME_NONNULL_END

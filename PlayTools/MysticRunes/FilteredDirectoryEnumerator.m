//
//  FilteredDirectoryEnumerator.m
//  PlayTools
//

#import "FilteredDirectoryEnumerator.h"

@implementation FilteredDirectoryEnumerator

- (instancetype) initWithEnumerator:(NSDirectoryEnumerator *) enumerator
                             filter:(DirectoryEnumeratorFilterBlock) filter {
    self = [super init];
    if (self) {
        _wrappedEnumerator = enumerator;
        _filter = [filter copy];
    }
    return self;
}

- (id)nextObject {
    id object;
    
    while ((object = [self.wrappedEnumerator nextObject])) {
        NSString *path = nil;
        
        if ([object isKindOfClass:[NSString class]]) {
            path = object;
        } else if ([object isKindOfClass:[NSURL class]]) {
            path = [(NSURL *)object path];
        }
        
        if (path != nil && self.filter(path)) {
            continue;
        }
        
        return object;
    }
    
    return nil;
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL) sel {
    return [(id)self.wrappedEnumerator methodSignatureForSelector:sel];
}

- (void) forwardInvocation:(NSInvocation *) invocation {
    [invocation invokeWithTarget:self.wrappedEnumerator];
}

@end

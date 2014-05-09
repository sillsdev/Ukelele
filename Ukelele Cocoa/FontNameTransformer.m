//
//  FontNameTransformer.m
//  Ukelele 3
//
//  Created by John Brownie on 14/07/13.
//
//

#import "FontNameTransformer.h"

@implementation FontNameTransformer

+ (Class)tranformedValueClass {
    return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    if (value && [value isKindOfClass:[NSFont class]]) {
        return [NSString stringWithFormat:@"%@ %g pt", [value displayName], [value pointSize]];
    } else {
        return @"";
    }
}

@end

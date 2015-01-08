//
//  StringArrayFirstTransformer.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 8/01/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import "StringArrayFirstTransformer.h"

@implementation StringArrayFirstTransformer

+ (Class)transformedValueClass {
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
	return NO;
}

- (id)transformedValue:(id)value {
	if ([value isKindOfClass:[NSArray class]]) {
		if ([value count] > 0) {
			return value[0];
		}
		return nil;
	}
	return nil;
}

@end

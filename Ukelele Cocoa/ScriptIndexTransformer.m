//
//  ScriptIndexTransformer.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 5/01/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import "ScriptIndexTransformer.h"
#import "ScriptInfo.h"

@implementation ScriptIndexTransformer

+ (Class)transformedValueClass {
	return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
	return YES;
}

- (id)transformedValue:(id)value {
	if ([value isKindOfClass:[NSArray class]] && [(NSArray *)value count] == 0) {
		return [NSIndexSet indexSet];
	}
	NSInteger scriptID = [value isKindOfClass:[NSArray class]] ? [value[0] integerValue] : [value integerValue];
	static NSArray *standardScripts;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		standardScripts = [ScriptInfo standardScripts];
	});
	for (NSUInteger i = 0; i < [standardScripts count]; i++) {
		ScriptInfo *scriptInfo = standardScripts[i];
		if ([scriptInfo scriptID] == scriptID) {
			return [NSIndexSet indexSetWithIndex:i];
		}
	}
	return [NSIndexSet indexSet];
}

- (id)reverseTransformedValue:(id)value {
	if ([(NSIndexSet *)value count] == 0) {
		return @(-1);
	}
	NSInteger scriptIndex = [(NSIndexSet *)value firstIndex];
	static NSArray *standardScripts;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		standardScripts = [ScriptInfo standardScripts];
	});
	ScriptInfo *scriptInfo = standardScripts[scriptIndex];
	return @([scriptInfo scriptID]);
}

@end

@implementation ScriptIndexReverseTransformer

+ (Class)transformedValueClass {
	return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
	return YES;
}

- (id)transformedValue:(id)value {
	NSInteger scriptIndex = [value integerValue];
	static NSArray *standardScripts;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		standardScripts = [ScriptInfo standardScripts];
	});
	ScriptInfo *scriptInfo = standardScripts[scriptIndex];
	return @([scriptInfo scriptID]);
}

- (id)reverseTransformedValue:(id)value {
	if ([(NSIndexSet *)value count] == 0) {
		return @(-1);
	}
	NSInteger scriptID = [(NSIndexSet *)value firstIndex];
	static NSArray *standardScripts;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		standardScripts = [ScriptInfo standardScripts];
	});
	NSInteger index = -1;
	for (NSInteger i = 0; i < (NSInteger)[standardScripts count]; i++) {
		ScriptInfo *scriptInfo = standardScripts[i];
		if ([scriptInfo scriptID] == scriptID) {
			index = i;
			break;
		}
	}
	return @(index);
}

@end

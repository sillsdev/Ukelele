//
//  ScriptInfoTransformer.m
//  Ukelele 3
//
//  Created by John Brownie on 28/02/13.
//
//

#import "ScriptInfoTransformer.h"
#import "ScriptInfo.h"

@implementation ScriptInfoTransformer

+ (Class)transformedValueClass {
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
	return YES;
}

- (id)transformedValue:(id)value {
	NSInteger scriptID = [value integerValue];
	for (ScriptInfo *scriptInfo in [ScriptInfo standardScripts]) {
		if ([scriptInfo scriptID] == scriptID) {
			return [scriptInfo scriptName];
		}
	}
	return nil;
}

- (id)reverseTransformedValue:(id)value {
	return @([(ScriptInfo *)value scriptID]);
}

@end

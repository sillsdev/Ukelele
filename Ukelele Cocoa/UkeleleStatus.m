//
//  UkeleleStatus.m
//  Ukelele
//
//  Created by John Brownie on 20/12/17.
//  Copyright © 2017 John Brownie. All rights reserved.
//

#import "UkeleleStatus.h"
#import "UkeleleConstantStrings.h"

@implementation UkeleleStatus

- (instancetype)init {
	if (self = [super init]) {
		_stateName = kStateNameNone;
		_keyboardType = @"";
		_keyboardCoding = @"";
		_modifierIndex = 0;
	}
	return self;
}

- (NSString *)statusString {
	return [NSString stringWithFormat:@"State: %@, Modifier set: %ld, Keyboard: %@, Coding: %@", self.stateName, self.modifierIndex, self.keyboardType, self.keyboardCoding];
}

@end

//
//  ToolboxData.m
//  Ukelele 3
//
//  Created by John Brownie on 26/12/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "ToolboxData.h"
#import "UkeleleConstantStrings.h"

@implementation ToolboxData

- (instancetype)init {
	self = [super init];
	if (self) {
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		_stickyModifiers = [userDefaults boolForKey:UKStickyModifiers];
		_JISOnly = [userDefaults boolForKey:UKJISOnly];
	}
	return self;
}

+ (ToolboxData *)sharedToolboxData {
	static ToolboxData *theInstance = nil;
	if (!theInstance) {
		theInstance = [[ToolboxData alloc] init];
	}
	return theInstance;
}

@end

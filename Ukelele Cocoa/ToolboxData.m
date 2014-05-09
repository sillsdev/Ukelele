//
//  ToolboxData.m
//  Ukelele 3
//
//  Created by John Brownie on 26/12/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "ToolboxData.h"

@implementation ToolboxData

- (id)init {
	self = [super init];
	if (self) {
		_stickyModifiers = NO;
		_JISOnly = NO;
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

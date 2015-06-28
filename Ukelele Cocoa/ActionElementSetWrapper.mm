//
//  ActionElementSetWrapper.mm
//  Ukelele 3
//
//  Created by John Brownie on 14/06/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "ActionElementSetWrapper.h"

@implementation ActionElementSetWrapper

- (instancetype)init
{
	self = [super init];
	if (self) {
		_actionElements = NULL;
	}
	return self;
}

- (void)dealloc
{
	delete _actionElements;
}

@end

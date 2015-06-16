//
//  RemoveStateData.m
//  Ukelele 3
//
//  Created by John Brownie on 12/06/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "RemoveStateData.h"

@implementation RemoveStateData

- (id)init
{
	self = [super init];
	if (self) {
		_dataBlock = NULL;
	}
	return self;
}

- (void)dealloc
{
	delete _dataBlock;
}

@end

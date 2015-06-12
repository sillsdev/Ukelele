//
//  AddMissingOutputData.mm
//  Ukelele 3
//
//  Created by John Brownie on 30/07/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "AddMissingOutputData.h"

@implementation AddMissingOutputData

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
	[super dealloc];
}

@end

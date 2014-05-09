//
//  KeyboardTypeController.m
//  Ukelele 3
//
//  Created by John Brownie on 2/03/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "KeyboardTypeController.h"

@implementation KeyboardTypeController

@synthesize resourceList;
@synthesize namesList;

- (id)init
{
	self = [super init];
	if (self) {
		resourceList = [KeyboardResourceList getInstance];
		namesList = [resourceList namesList];
	}
	return self;
}

//- (id)arrangedObjects
//{
//	return [resourceList keyboardTypeTable];
//}

- (BOOL)canAdd
{
	return NO;
}

- (BOOL)canRemove
{
	return NO;
}

- (NSUInteger)countOfResourceList
{
	return [[resourceList namesList] count];
}

- (id)objectInResourceListAtIndex:(NSUInteger)index
{
	return [[resourceList namesList] objectAtIndex:index];
}

@end

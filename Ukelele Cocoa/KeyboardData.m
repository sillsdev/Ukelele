//
//  KeyboardData.m
//  Ukelele 3
//
//  Created by John Brownie on 7/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "KeyboardData.h"


@implementation KeyboardData

- (id)initWithDocument:(UkeleleDocument *)theDocument data:(KeyData *)theData
{
	self = [super init];
	if (self) {
		mDocument = theDocument;
		dataBlock = theData;
	}
	return self;
}

- (id)initWithDocument:(UkeleleDocument *)theDocument
			keyboardID:(int)theID
			   keyCode:(int)theCode
			 modifiers:(unsigned int)theModifiers
				 state:(NSString *)theState
{
	KeyData *theData = [KeyData createWithKeyboardID:theID keyCode:theCode modifiers:theModifiers state:theState];
	return [self initWithDocument:theDocument data:theData];
}

- (UkeleleDocument *)document
{
	return mDocument;
}

- (KeyData *)dataBlock
{
	return dataBlock;
}

- (int)keyboardID
{
	return [dataBlock keyboardID];
}

- (int)keyCode
{
	return [dataBlock keyCode];
}

- (unsigned int)modifiers
{
	return [dataBlock modifiers];
}

- (NSString *)state
{
	return [dataBlock state];
}

@end

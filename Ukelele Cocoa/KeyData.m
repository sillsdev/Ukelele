//
//  KeyData.m
//  Ukelele 3
//
//  Created by John Brownie on 2/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "KeyData.h"


@implementation KeyData

- (int)keyboardID
{
	return mKeyboardID;
}

- (void)setKeyboardID:(int)keyboardID
{
	mKeyboardID = keyboardID;
}

- (int)keyCode
{
	return mKeyCode;
}

- (void)setKeyCode:(int)keyCode
{
	mKeyCode = keyCode;
}

- (unsigned int)modifiers
{
	return mModifiers;
}

- (void)setModifiers:(unsigned int)modifiers
{
	mModifiers = modifiers;
}

- (NSString *)state
{
	return mState;
}

- (void)setState:(NSString *)state
{
	mState = state;
}

- (id)init
{
	self = [super init];
	if (self) {
		mState = nil;
	}
	return self;
}

- (void)dealloc
{
	[mState release];
	[super dealloc];
}

+ (KeyData *)createWithKeyboardID:(int)keyboardID
						  keyCode:(int)keyCode
						modifiers:(unsigned int)modifiers
							state:(NSString *)state
{
	KeyData *data = [[KeyData alloc] init];
	[data setKeyboardID:keyboardID];
	[data setKeyCode:keyCode];
	[data setModifiers:modifiers];
	[data setState:state];
	return data;
}

@end

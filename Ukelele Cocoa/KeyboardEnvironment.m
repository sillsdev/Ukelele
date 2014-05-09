//
//  KeyboardEnvironment.m
//  Ukelele 3
//
//  Created by John Brownie on 20/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "KeyboardEnvironment.h"


@implementation KeyboardEnvironment

static KeyboardEnvironment *theKeyboardEnvironment = nil;

- (id)init
{
	self = [super init];
	if (self) {
		_currentKeyboardID = 0;
		_stickyModifiersOn = NO;
		_currentModifiers = 0;
		_currentState = nil;
	}
	return self;
}

+ (KeyboardEnvironment *)instance
{
	if (theKeyboardEnvironment == nil) {
		theKeyboardEnvironment = [[KeyboardEnvironment alloc] init];
	}
	return theKeyboardEnvironment;
}

+ (void)updateKeyboard:(NSInteger)keyboardID
	   stickyModifiers:(BOOL)stickyModifiers
			 modifiers:(NSUInteger)modifiers
				 state:(NSString *)state
{
	KeyboardEnvironment *environment = [KeyboardEnvironment instance];
	[environment setCurrentKeyboardID:keyboardID];
	[environment setStickyModifiersOn:stickyModifiers];
	[environment setCurrentModifiers:modifiers];
	[environment setCurrentState:state];
}

@end

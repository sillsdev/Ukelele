//
//  KeyboardLayoutInformation.m
//  Ukelele 3
//
//  Created by John Brownie on 13/10/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "KeyboardLayoutInformation.h"

@implementation KeyboardLayoutInformation

- (id)initWithObject:(UkeleleKeyboardObject *)theKeyboard fileName:(NSString *)fileName {
	self = [super init];
	_keyboardObject = theKeyboard;
	_keyboardName = [theKeyboard keyboardName];
	_fileName = fileName;
	_hasIcon = NO;
	return self;
}

@end

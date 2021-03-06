//
//  KeyboardLayoutInformation.m
//  Ukelele 3
//
//  Created by John Brownie on 13/10/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "KeyboardLayoutInformation.h"

@implementation KeyboardLayoutInformation

- (instancetype) init NS_UNAVAILABLE {
	abort();
}

- (instancetype)initWithObject:(UkeleleKeyboardObject *)theKeyboard fileName:(NSString *)fileName {
	self = [super init];
	_keyboardObject = theKeyboard;
	_fileName = fileName;
	if (_keyboardObject) {
		_keyboardName = [theKeyboard keyboardName];
	}
	else {
		_keyboardName = fileName;
	}
	_keyboardFileWrapper = nil;
	_intendedLanguage = @"";
	_iconData = nil;
	_doesCapsLockSwitching = NO;
	_keyboardController = nil;
	_hasBadKeyboard = NO;
	_localisedNames = [NSMutableDictionary dictionary];
	return self;
}

- (BOOL)hasIcon {
	return self.iconData != nil;
}

@end

//
//  KeyboardLayoutInformation.m
//  Ukelele 3
//
//  Created by John Brownie on 13/10/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "KeyboardLayoutInformation.h"

@implementation KeyboardLayoutInformation

- (id)initWithDocument:(UkeleleDocument *)theDocument {
	self = [super init];
	_document = theDocument;
	_keyboardName = [theDocument keyboardDisplayName];
	NSURL *theURL = [theDocument fileURL];
	if (nil != theURL) {
		NSString *filePath = [theURL lastPathComponent];
		_fileName = [filePath stringByDeletingPathExtension];
	}
	return self;
}

@end

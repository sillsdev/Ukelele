//
//  KeyData.h
//  Ukelele 3
//
//  Created by John Brownie on 2/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UkeleleDocument;

@interface KeyData : NSObject {
	int mKeyboardID;
	int mKeyCode;
	unsigned int mModifiers;
	NSString *mState;
}

@property (nonatomic) int keyboardID;
@property (nonatomic) int keyCode;
@property (nonatomic) unsigned int modifiers;
@property (copy) NSString *state;

+ (KeyData *)createWithKeyboardID:(int)keyboardID
						  keyCode:(int)keyCode
						modifiers:(unsigned int)modifiers
							state:(NSString *)state;

@end

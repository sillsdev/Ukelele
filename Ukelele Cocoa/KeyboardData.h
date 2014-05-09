//
//  KeyboardData.h
//  Ukelele 3
//
//  Created by John Brownie on 7/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KeyData.h"

@interface KeyboardData : NSObject {
	UkeleleDocument *mDocument;
	KeyData *dataBlock;
}

@property (assign, readonly) UkeleleDocument *document;
@property (assign, readonly) KeyData *dataBlock;
@property (readonly) int keyboardID;
@property (readonly) int keyCode;
@property (readonly) unsigned int modifiers;
@property (readonly) NSString *state;

- (id)initWithDocument:(UkeleleDocument *)theDocument data:(KeyData *)theData;
- (id)initWithDocument:(UkeleleDocument *)theDocument
			keyboardID:(int)theID
			   keyCode:(int)theCode
			 modifiers:(unsigned int)theModifiers
				 state:(NSString *)theState;

@end

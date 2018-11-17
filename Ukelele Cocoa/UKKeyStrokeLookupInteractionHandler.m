//
//  UKKeyStrokeLookupInteractionHandler.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 27/01/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import "UKKeyStrokeLookupInteractionHandler.h"
#import "AskTextSheet.h"
#import "UkeleleConstantStrings.h"
#import "UKKeyboardController.h"

@implementation UKKeyStrokeLookupInteractionHandler {
	UKKeyboardController *keyboardController;
	NSUInteger oldModifiers;
	NSString *oldState;
	AskTextSheet *askTextSheet;
	NSWindow *parentWindow;
	UkeleleKeyboardObject *keyboardObject;
	NSUInteger keyboardID;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		askTextSheet = nil;
		_completionTarget = nil;
	}
	return self;
}

- (void)beginInteractionWithKeyboard:(UKKeyboardController *)theKeyboard {
	keyboardController = theKeyboard;
	keyboardObject = [theKeyboard keyboardLayout];
	parentWindow = [theKeyboard window];
	oldModifiers = [theKeyboard currentModifiers];
	oldState = [theKeyboard currentState];
	keyboardID = [theKeyboard keyboardID];
	if (askTextSheet == nil) {
		askTextSheet = [AskTextSheet askTextSheet];
	}
	[askTextSheet beginAskText:@"Enter the output string for which you want the key strokes" minorText:@"Ukelele will determine the key stroke sequence to produce this string" initialText:@"" forWindow:parentWindow callBack:^(id result) {
		NSDictionary *keyStrokeData = nil;
		if (result != nil && [result length] > 0) {
			keyStrokeData = [self->keyboardObject getKeyStrokeForOutput:result forKeyboard:self->keyboardID];
		}
		[self displayKeyStrokes:keyStrokeData];
	}];
}

- (void)displayKeyStrokes:(NSDictionary *)keyStrokeDict {
	if (keyStrokeDict == nil) {
			// User has cancelled
		[self interactionCompleted];
		[self.completionTarget interactionDidComplete:self];
		return;
	}
	NSInteger theKeyCode = [keyStrokeDict[UKKeyStrokeLookupKeyCode] integerValue];
	NSString *theKeyStrokes = keyStrokeDict[UKKeyStrokeLookupKeyStrokes];
	if ([theKeyStrokes length] == 0) {
			// No key stroke found
		theKeyStrokes = @"No key stroke produces the given output.";
	}
	else {
		NSUInteger theModifiers = [keyStrokeDict[UKKeyStrokeLookupModifiers] unsignedIntegerValue];
		NSString *theState = keyStrokeDict[UKKeyStrokeLookupState];
		if (![[keyboardController currentState] isEqualToString:theState]) {
			[keyboardController enterDeadKeyStateWithName:theState];
		}
		if (oldModifiers != theModifiers) {
			[keyboardController setCurrentModifiers:theModifiers];
		}
		[keyboardController setSelectedKey:theKeyCode];
	}
	NSString *theMessageString = [NSString stringWithFormat:@"%@ (Press any key to continue)", theKeyStrokes];
	[keyboardController setMessageBarText:theMessageString];
}

- (void)handleMessage:(NSDictionary *)messageData {
	if ([kMessageKeyDown isEqualToString:messageData[kMessageNameKey]]) {
			// Interaction is done
		[self interactionCompleted];
	}
}

- (void)interactionCompleted {
	if (![[keyboardController currentState] isEqualToString:oldState]) {
		[keyboardController leaveCurrentDeadKeyState];
	}
	if ([keyboardController currentModifiers] != oldModifiers) {
		[keyboardController setCurrentModifiers:oldModifiers];
	}
	[keyboardController setSelectedKey:kNoKeyCode];
	[keyboardController setMessageBarText:@""];
	[self.completionTarget interactionDidComplete:self];
}

- (void)cancelInteraction {
	[self interactionCompleted];
}

@end

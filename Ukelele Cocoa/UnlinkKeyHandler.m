//
//  UnlinkKeyHandler.m
//  Ukelele 3
//
//  Created by John Brownie on 8/12/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import "UnlinkKeyHandler.h"
#import "UKKeyboardController.h"
#import "UkeleleConstantStrings.h"

@implementation UnlinkKeyHandler {
	UKKeyboardController *parentDocumentWindow;
	NSWindow *parentWindow;
    id<UKInteractionCompletion> completionTarget;
	AskKeyCode *askKeyCodeSheet;
	NSInteger selectedKeyCode;
}

- (id)initWithDocumentWindow:(UKKeyboardController *)theDocumentWindow {
	if (self = [super init]) {
		parentDocumentWindow = theDocumentWindow;
		parentWindow = [theDocumentWindow window];
		completionTarget = nil;
		askKeyCodeSheet = nil;
		selectedKeyCode = kNoKeyCode;
	}
	return self;
}


+ (UnlinkKeyHandler *)unlinkKeyHandler:(UKKeyboardController *)theDocumentWindow {
	return [[UnlinkKeyHandler alloc] initWithDocumentWindow:theDocumentWindow];
}

- (void)setCompletionTarget:(id<UKInteractionCompletion>)theTarget
{
	completionTarget = theTarget;
}

- (void)setSelectedKeyCode:(NSInteger)keyCode {
	selectedKeyCode = keyCode;
}

- (void)beginInteraction:(UnlinkKeyType)keyCodeType
{
	if (keyCodeType == kUnlinkKeyTypeAskCode) {
			// Put up a dialog to ask for the key code
		if (askKeyCodeSheet == nil) {
			askKeyCodeSheet = [AskKeyCode askKeyCode];
		}
		NSString *majorText = NSLocalizedStringFromTable(@"Please enter the key code, which must be in the range 0 to 511", @"dialogs", @"Ask user for the key code");
		NSString *minorText = NSLocalizedStringFromTable(@"Note that the modifiers will be whatever were current when you invoked this command", @"dialogs", @"Warn the user about the modifiers");
		[askKeyCodeSheet setMajorText:majorText];
		[askKeyCodeSheet setMinorText:minorText];
		[askKeyCodeSheet beginDialogForWindow:parentWindow callBack:^(NSNumber *keyCode) {
			[self performUnlink:[keyCode integerValue] withModifiers:[parentDocumentWindow currentModifiers]];
		}];
	}
	else if (keyCodeType == kUnlinkKeyTypeAskKey) {
			// Put up a message to ask for the key
		NSString *messageText = NSLocalizedStringFromTable(@"Press or click the key to be unlinked", @"dialogs", @"Ask user for the key");
		[parentDocumentWindow setMessageBarText:messageText];
	}
	else if (keyCodeType == kUnlinkKeyTypeSelectedKey) {
			// Have the key code already, so just go ahead
		[self performUnlink:selectedKeyCode withModifiers:[parentDocumentWindow currentModifiers]];
	}
	else {
		NSLog(@"Bad unlink type %d", (int)keyCodeType);
		[self interactionCompleted];
	}
}

- (void)performUnlink:(NSInteger)keyCode withModifiers:(NSUInteger)modifierCombination
{
		// Pass it off to the document to handle
	[parentDocumentWindow unlinkKeyWithKeyCode:keyCode andModifiers:modifierCombination];
		// Clean up
	[self interactionCompleted];
}

- (void)interactionCompleted
{
	[completionTarget interactionDidComplete:self];
}

- (void)handleMessage:(NSDictionary *)messageData
{
	NSString *messageName = messageData[kMessageNameKey];
	NSUInteger keyModifiers = [parentDocumentWindow currentModifiers];
	NSInteger keyCode = kNoKeyCode;
	if ([messageName isEqualToString:kMessageClick]) {
			// Handle a click on a key
		keyCode = [messageData[kMessageArgumentKey] integerValue];
		[parentDocumentWindow setMessageBarText:@""];
	}
	else if ([messageName isEqualToString:kMessageKeyDown]) {
			// Handle a key press
		keyCode = [messageData[kMessageArgumentKey] integerValue];
		[parentDocumentWindow setMessageBarText:@""];
	}
	if (keyCode >= 0) {
		[self performUnlink:keyCode withModifiers:keyModifiers];
	}
}

@end

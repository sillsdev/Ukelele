//
//  UnlinkKeyHandler.m
//  Ukelele 3
//
//  Created by John Brownie on 8/12/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import "UnlinkKeyHandler.h"
#import "UkeleleDocument.h"
#import "UkeleleConstantStrings.h"

@implementation UnlinkKeyHandler {
	UkeleleDocument *parentDocument;
	NSWindow *parentWindow;
    id<UKInteractionCompletion> completionTarget;
	AskKeyCode *askKeyCodeSheet;
	NSInteger selectedKeyCode;
}

- (id)initWithDocument:(UkeleleDocument *)theDocument window:(NSWindow *)theWindow
{
	if (self = [super init]) {
		parentWindow = theWindow;
		parentDocument = theDocument;
		completionTarget = nil;
		askKeyCodeSheet = nil;
		selectedKeyCode = kNoKeyCode;
	}
	return self;
}


+ (UnlinkKeyHandler *)unlinkKeyHandler:(UkeleleDocument *)theDocument window:(NSWindow *)theWindow
{
	return [[UnlinkKeyHandler alloc] initWithDocument:theDocument window:theWindow];
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
			[self performUnlink:[keyCode integerValue] withModifiers:[parentDocument currentModifiers]];
		}];
	}
	else if (keyCodeType == kUnlinkKeyTypeAskKey) {
			// Put up a message to ask for the key
		NSString *messageText = NSLocalizedStringFromTable(@"Press or click the key to be unlinked", @"dialogs", @"Ask user for the key");
		[parentDocument setMessageBarText:messageText];
	}
	else if (keyCodeType == kUnlinkKeyTypeSelectedKey) {
			// Have the key code already, so just go ahead
		[self performUnlink:selectedKeyCode withModifiers:[parentDocument currentModifiers]];
	}
	else {
		NSLog(@"Bad unlink type %d", (int)keyCodeType);
		[self interactionCompleted];
	}
}

- (void)performUnlink:(NSInteger)keyCode withModifiers:(NSUInteger)modifierCombination
{
		// Pass it off to the document to handle
	[parentDocument unlinkKeyWithKeyCode:keyCode andModifiers:modifierCombination];
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
	NSUInteger keyModifiers = [parentDocument currentModifiers];
	NSInteger keyCode = kNoKeyCode;
	if ([messageName isEqualToString:kMessageClick]) {
			// Handle a click on a key
		keyCode = [messageData[kMessageArgumentKey] integerValue];
		[parentDocument setMessageBarText:@""];
	}
	else if ([messageName isEqualToString:kMessageKeyDown]) {
			// Handle a key press
		keyCode = [messageData[kMessageArgumentKey] integerValue];
		[parentDocument setMessageBarText:@""];
	}
	if (keyCode >= 0) {
		[self performUnlink:keyCode withModifiers:keyModifiers];
	}
}

@end

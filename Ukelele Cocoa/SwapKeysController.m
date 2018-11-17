//
//  SwapKeysController.m
//  Ukelele 3
//
//  Created by John Brownie on 11/08/13.
//
//

#import "SwapKeysController.h"
#import "UKKeyboardController.h"
#import "AskSwapKeysWindowController.h"
#import "UkeleleConstantStrings.h"

#define kFirstKeyPrompt		@"Press or click the first key"
#define kSecondKeyPrompt	@"Press or click the second key"

@implementation SwapKeysController {
	UKKeyboardController *parentDocumentController;
	NSWindow *parentWindow;
    id<UKInteractionCompletion> completionTarget;
	AskSwapKeysWindowController *askKeyCodeSheet;
	NSInteger keyCode;
}

- (instancetype)initWithDocument:(UKKeyboardController *)theWindowController {
	self = [super init];
	if (self) {
		parentDocumentController = theWindowController;
		parentWindow = [theWindowController window];
		completionTarget = theWindowController;
		askKeyCodeSheet = nil;
		keyCode = kNoKeyCode;
	}
	return self;
}

+ (SwapKeysController *)swapKeysController:(UKKeyboardController *)theWindowController {
	return [[SwapKeysController alloc] initWithDocument:theWindowController];
}

- (void)setCompletionTarget:(id<UKInteractionCompletion>)theTarget {
	completionTarget = theTarget;
}

- (void)beginInteraction:(BOOL)askingKeyCode {
	NSUInteger selectedKey = [parentDocumentController currentSelectedKey];
	if (askingKeyCode) {
			// Bring up a sheet to ask for the key codes
		askKeyCodeSheet = [AskSwapKeysWindowController askSwapKeysWindowController];
		[askKeyCodeSheet beginInteractionWithWindow:parentWindow initialSelection:selectedKey callback:^(NSArray *resultArray) {
			if (resultArray != nil) {
				[self->parentDocumentController swapKeyWithCode:[resultArray[0] integerValue] andKeyWithCode:[resultArray[1] integerValue]];
			}
			[self interactionCompleted];
		}];
	}
	else if (selectedKey != kNoKeyCode) {
			// Have one key already
		keyCode = selectedKey;
		[parentDocumentController setMessageBarText:kSecondKeyPrompt];
	}
	else {
			// Ask for the first key
		[parentDocumentController setMessageBarText:kFirstKeyPrompt];
	}
}

- (void)handleMessage:(NSDictionary *)messageData {
	NSString *messageName = messageData[kMessageNameKey];
	if ([kMessageKeyDown isEqualToString:messageName] || [kMessageClick isEqualToString:messageName]) {
			// Key down or click in a key
		NSInteger selectedKeyCode = [messageData[kMessageArgumentKey] integerValue];
		[self chooseKey:selectedKeyCode];
	}
}

- (void)chooseKey:(NSInteger)selectedKey {
	if (keyCode == kNoKeyCode) {
			// We've selected the first key
		keyCode = selectedKey;
			// Show that key as selected
		[parentDocumentController setSelectedKey:keyCode];
		[parentDocumentController setMessageBarText:kSecondKeyPrompt];
	}
	else if (keyCode != selectedKey) {
			// Got the second key that's not the same as the first
		[parentDocumentController setMessageBarText:@""];
		[parentDocumentController clearSelectedKey];
			// Swap the keys with keyCode and selectedKey
		[parentDocumentController swapKeyWithCode:keyCode andKeyWithCode:selectedKey];
		[self interactionCompleted];
	}
}

- (void)interactionCompleted {
	[completionTarget interactionDidComplete:self];
}

- (void)cancelInteraction {
		// User cancelled
	[parentDocumentController setMessageBarText:@""];
	[parentDocumentController clearSelectedKey];
	[self interactionCompleted];
}

@end

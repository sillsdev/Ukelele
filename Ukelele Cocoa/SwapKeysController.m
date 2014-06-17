//
//  SwapKeysController.m
//  Ukelele 3
//
//  Created by John Brownie on 11/08/13.
//
//

#import "SwapKeysController.h"
#import "UKKeyboardWindow.h"
#import "AskSwapKeysWindowController.h"
#import "UkeleleConstantStrings.h"

@implementation SwapKeysController {
	UKKeyboardWindow *parentDocumentWindow;
	NSWindow *parentWindow;
    id<UKInteractionCompletion> completionTarget;
	AskSwapKeysWindowController *askKeyCodeSheet;
	NSInteger keyCode;
}

- (id)initWithDocument:(UKKeyboardWindow *)theDocumentWindow {
	self = [super init];
	if (self) {
		parentDocumentWindow = theDocumentWindow;
		parentWindow = [theDocumentWindow window];
		completionTarget = nil;
		askKeyCodeSheet = nil;
		keyCode = kNoKeyCode;
	}
	return self;
}

+ (SwapKeysController *)swapKeysController:(UKKeyboardWindow *)theDocumentWindow {
	return [[SwapKeysController alloc] initWithDocument:theDocumentWindow];
}

- (void)setCompletionTarget:(id<UKInteractionCompletion>)theTarget {
	completionTarget = theTarget;
}

- (void)beginInteraction:(BOOL)askingKeyCode {
	if (askingKeyCode) {
			// Bring up a sheet to ask for the key codes
		askKeyCodeSheet = [AskSwapKeysWindowController askSwapKeysWindowController];
		[askKeyCodeSheet beginInteractionWithWindow:parentWindow callback:^(NSArray *resultArray) {
			if (resultArray != nil) {
				[parentDocumentWindow swapKeyWithCode:[resultArray[0] integerValue] andKeyWithCode:[resultArray[1] integerValue]];
			}
			[self interactionCompleted];
		}];
	}
	else {
			// Ask for the first key
		[parentDocumentWindow setMessageBarText:@"Press or click the first key"];
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
		[parentDocumentWindow setSelectedKey:keyCode];
		[parentDocumentWindow setMessageBarText:@"Press or click the second key"];
	}
	else if (keyCode != selectedKey) {
			// Got the second key that's not the same as the first
		[parentDocumentWindow setMessageBarText:@""];
		[parentDocumentWindow clearSelectedKey];
			// Swap the keys with keyCode and selectedKey
		[parentDocumentWindow swapKeyWithCode:keyCode andKeyWithCode:selectedKey];
		[self interactionCompleted];
	}
}

- (void)interactionCompleted {
	[completionTarget interactionDidComplete:self];
}

@end

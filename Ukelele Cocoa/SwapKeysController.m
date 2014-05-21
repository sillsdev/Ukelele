//
//  SwapKeysController.m
//  Ukelele 3
//
//  Created by John Brownie on 11/08/13.
//
//

#import "SwapKeysController.h"
#import "UkeleleDocument.h"
#import "AskSwapKeysWindowController.h"
#import "UkeleleConstantStrings.h"

@implementation SwapKeysController {
	UkeleleDocument *parentDocument;
	NSWindow *parentWindow;
    id<UKInteractionCompletion> completionTarget;
	AskSwapKeysWindowController *askKeyCodeSheet;
	NSInteger keyCode;
}

- (id)initWithDocument:(UkeleleDocument *)theDocument window:(NSWindow *)theWindow {
	self = [super init];
	if (self) {
		parentDocument = theDocument;
		parentWindow = theWindow;
		completionTarget = nil;
		askKeyCodeSheet = nil;
		keyCode = kNoKeyCode;
	}
	return self;
}

+ (SwapKeysController *)swapKeysController:(UkeleleDocument *)theDocument window:(NSWindow *)theWindow {
	return [[SwapKeysController alloc] initWithDocument:theDocument window:theWindow];
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
				[parentDocument swapKeyWithCode:[resultArray[0] integerValue] andKeyWithCode:[resultArray[1] integerValue]];
			}
			[self interactionCompleted];
		}];
	}
	else {
			// Ask for the first key
		[parentDocument setMessageBarText:@"Press or click the first key"];
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
		[parentDocument setSelectedKey:keyCode];
		[parentDocument setMessageBarText:@"Press or click the second key"];
	}
	else if (keyCode != selectedKey) {
			// Got the second key that's not the same as the first
		[parentDocument setMessageBarText:@""];
		[parentDocument clearSelectedKey];
			// Swap the keys with keyCode and selectedKey
		[parentDocument swapKeyWithCode:keyCode andKeyWithCode:selectedKey];
		[self interactionCompleted];
	}
}

- (void)interactionCompleted {
	[completionTarget interactionDidComplete:self];
}

@end
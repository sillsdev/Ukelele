//
//  UnlinkModifierSetHandler.m
//  Ukelele 3
//
//  Created by John Brownie on 10/05/13.
//
//

#import "UnlinkModifierSetHandler.h"
#import "UKKeyboardController.h"
#import "UnlinkModifiersController.h"
#import "KeyboardEnvironment.h"

@implementation UnlinkModifierSetHandler {
	UKKeyboardController *parentDocumentWindow;
	NSWindow *parentWindow;
	void (^callback)(NSInteger);
    id<UKInteractionCompletion> completionTarget;
	UnlinkModifiersController *unlinkModifiersController;
}

- (instancetype)initWithDocument:(UKKeyboardController *)theDocumentWindow {
	if (self = [super init]) {
		parentDocumentWindow = theDocumentWindow;
		parentWindow = [theDocumentWindow window];
		callback = nil;
		completionTarget = nil;
		unlinkModifiersController = nil;
	}
	return self;
}

+ (UnlinkModifierSetHandler *)unlinkModifierSetHandler:(UKKeyboardController *)theDocumentWindow {
	return [[UnlinkModifierSetHandler alloc] initWithDocument:theDocumentWindow];
}

- (void)beginInteractionWithCallback:(void (^)(NSInteger))theCallBack {
	unlinkModifiersController = [UnlinkModifiersController unlinkModifiersController];
	callback = theCallBack;
	UkeleleKeyboardObject *keyboard = [parentDocumentWindow keyboardLayout];
//	[unlinkModifiersController setUsesSimplifiedModifiers:[keyboard hasSimplifiedModifiers]];
	[unlinkModifiersController beginDialogWithWindow:parentWindow isSimplified:[keyboard hasSimplifiedModifiers] callback:^(NSNumber *result) {
		[self acceptModifiers:result];
		[self interactionCompleted];
	}];
}

- (void)acceptModifiers:(NSNumber *)modifierCombination {
	NSInteger modifierSet;
	if (modifierCombination != nil) {
			// Got valid modifiers
		UkeleleKeyboardObject *keyboard = [parentDocumentWindow keyboardLayout];
		modifierSet = [keyboard modifierSetIndexForModifiers:[modifierCombination unsignedIntegerValue] forKeyboard:[[KeyboardEnvironment instance] currentKeyboardID]];
	}
	else {
			// User cancelled
		modifierSet = -1;
	}
	callback(modifierSet);
}

- (void)setCompletionTarget:(id<UKInteractionCompletion>)theTarget {
	completionTarget = theTarget;
}

- (void)interactionCompleted {
	[completionTarget interactionDidComplete:self];
}

- (void)handleMessage:(NSDictionary *)messageData {
#pragma unused(messageData)
		// No messages to handle
}

- (void)cancelInteraction {
		// User cancelled
	callback(-1);
	[self interactionCompleted];
}

@end

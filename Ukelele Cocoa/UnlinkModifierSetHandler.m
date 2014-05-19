//
//  UnlinkModifierSetHandler.m
//  Ukelele 3
//
//  Created by John Brownie on 10/05/13.
//
//

#import "UnlinkModifierSetHandler.h"
#import "UkeleleDocument.h"
#import "UnlinkModifiersController.h"
#import "KeyboardEnvironment.h"

@implementation UnlinkModifierSetHandler

- (id)initWithDocument:(UkeleleDocument *)theDocument window:(NSWindow *)theWindow {
	if (self = [super init]) {
		parentDocument = theDocument;
		parentWindow = theWindow;
		callback = nil;
		completionTarget = nil;
		unlinkModifiersController = nil;
	}
	return self;
}

+ (UnlinkModifierSetHandler *)unlinkModifierSetHandler:(UkeleleDocument *)theDocument window:(NSWindow *)theWindow {
	return [[UnlinkModifierSetHandler alloc] initWithDocument:theDocument window:theWindow];
}

- (void)beginInteractionWithCallback:(void (^)(NSInteger))theCallBack {
	unlinkModifiersController = [UnlinkModifiersController unlinkModifiersController];
	callback = theCallBack;
	UkeleleKeyboardObject *keyboard = [parentDocument keyboardLayout];
	[unlinkModifiersController setUsesSimplifiedModifiers:[keyboard hasSimplifiedModifiers]];
	[unlinkModifiersController beginDialogWithWindow:parentWindow callback:^(NSNumber *result) {
		[self acceptModifiers:result];
		[self interactionCompleted];
	}];
}

- (void)acceptModifiers:(NSNumber *)modifierCombination {
	NSInteger modifierSet;
	if (modifierCombination != nil) {
			// Got valid modifiers
		UkeleleKeyboardObject *keyboard = [parentDocument keyboardLayout];
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
		// No messages to handle
}

@end

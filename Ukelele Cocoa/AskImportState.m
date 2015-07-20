//
//  AskImportState.m
//  Ukelele
//
//  Created by John Brownie on 16/07/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import "AskImportState.h"
#import "UkeleleConstantStrings.h"

#define nibName 	@"AskImportState"
#define windowName	@"AskImportState"

@implementation AskImportState {
	NSArray *importStates;
	NSSet *targetStates;
	void (^completionBlock)(NSString *, NSString *);
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName {
	[[NSBundle mainBundle] loadNibNamed:nibName owner:self topLevelObjects:nil];
	if (self = [super initWithWindowNibName:windowNibName]) {
			// Initialisation
	}
	return self;
}

+ (AskImportState *)askImportState {
	return [[AskImportState alloc] initWithWindowNibName:windowName];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)askImportFromState:(NSArray *)sourceStates excludingStates:(NSArray *)destinationStates withWindow:(NSWindow *)parentWindow completionBlock:(void (^)(NSString *, NSString *))callback {
	importStates = [sourceStates sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
	[self.ChooseStatePopup removeAllItems];
	[self.ChooseStatePopup addItemsWithTitles:importStates];
	targetStates = [[NSSet setWithArray:destinationStates] setByAddingObject:kStateNameNone];
	completionBlock = callback;
	[self.ChooseStateText setStringValue:self.importPrompt];
	[self.AskStateNameText setStringValue:self.destinationStatePrompt];
	[[NSApplication sharedApplication] beginSheet:self.window
								   modalForWindow:parentWindow
									modalDelegate:nil
								   didEndSelector:nil
									  contextInfo:nil];
}

- (IBAction)acceptState:(id)sender {
#pragma unused(sender)
	NSString *sourceState = [self.ChooseStatePopup titleOfSelectedItem];
	NSString *newState = [self.AskStateNameField stringValue];
	if ([targetStates containsObject:newState]) {
			// We already have a state with this name
		[self.NameErrorText setHidden:NO];
		return;
	}
	[self.window orderOut:self];
	[[NSApplication sharedApplication] endSheet:self.window];
	completionBlock(sourceState, newState);
}

- (IBAction)cancelState:(id)sender {
#pragma unused(sender)
		// User cancelled
	[self.window orderOut:self];
	[[NSApplication sharedApplication] endSheet:self.window];
	completionBlock(nil, nil);
}
@end

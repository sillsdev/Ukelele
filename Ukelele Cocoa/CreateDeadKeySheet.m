//
//  CreateDeadKeySheet.m
//  Ukelele 3
//
//  Created by John Brownie on 11/11/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import "CreateDeadKeySheet.h"
#import "UkeleleConstants.h"
#import "UkeleleConstantStrings.h"

	// Dictionary keys
NSString *kDeadKeyDataKeyCode = @"KeyCode";
NSString *kDeadKeyDataModifiers = @"Modifiers";
NSString *kDeadKeyDataStateName = @"StateName";
NSString *kDeadKeyDataStateType = @"StateType";
NSString *kDeadKeyDataTerminator = @"Terminator";
NSString *kDeadKeyDataTerminatorSpecified = @"TerminatorSpecified";

@implementation CreateDeadKeySheet

static NSString *nibFileName = @"CreateDeadKeySheet";
static NSString *windowName = @"CreateDeadKey";

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:nibFileName owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
		callBack = nil;
    }
    
    return self;
}

+ (CreateDeadKeySheet *)createDeadKeySheet
{
	return [[CreateDeadKeySheet alloc] initWithWindowNibName:windowName];
}

- (void)beginCreateDeadKeySheet:(UkeleleKeyboardObject *)keyboardLayout
				  withModifiers:(NSUInteger)modifiers
					   forState:(NSString *)stateName
					  forWindow:(NSWindow *)parentWindow
					   callback:(void (^)(NSDictionary *))theCallback
{
	callBack = theCallback;
	keyboardObject = keyboardLayout;
	modifierCombination = modifiers;
	currentState = stateName;
	NSSet *stateSet = [NSSet setWithObjects:stateName, kStateNameNone, nil];
	NSMutableArray *stateArray = [[keyboardObject stateNamesNotInSet:stateSet] mutableCopy];
	[self.deadKeyState removeAllItems];
	[stateArray insertObject:[keyboardObject uniqueStateName] atIndex:0];
	[self.deadKeyState addItemsWithObjectValues:stateArray];
	[self.deadKeyState selectItemAtIndex:0];
	[self.badKeyCodeMessage setStringValue:@""];
	NSString *baseStateName = [keyboardObject uniqueStateName];
	[self.deadKeyState setStringValue:baseStateName];
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (IBAction)cancelChoice:(id)sender
{
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(nil);
}

- (IBAction)acceptChoice:(id)sender
{
#pragma unused(sender)
	NSNumber *keyCode;
	if ([self.chooseDeadKey selectedRow] == 0) {
			// Direct selection
		keyCode = @(kNoKeyCode);
	}
	else {
			// Key code is entered
		if ([[self window] firstResponder] == self.deadKeyCode) {
			[[self window] endEditingFor:self.deadKeyCode];
		}
		keyCode = [self.deadKeyCode objectValue];
	}
	[[self window] orderOut:self];
	NSMutableDictionary *deadKeyData = [NSMutableDictionary dictionary];
	deadKeyData[kDeadKeyDataKeyCode] = keyCode;
	deadKeyData[kDeadKeyDataModifiers] = @(modifierCombination);
	NSString *stateName = [self.deadKeyState stringValue];
	BOOL makingNewState = NO;
	if ([self.deadKeyState indexOfSelectedItem] == -1) {
			// Not an existing state
		if ([stateName length] == 0) {
				// No state supplied
			[self.missingStateMessage setHidden:NO];
			return;
		}
		else {
			[self.missingStateMessage setHidden:YES];
			deadKeyData[kDeadKeyDataStateType] = @(kDeadKeyTypeNew);
			makingNewState = YES;
		}
	}
	else {
			// Existing state
		deadKeyData[kDeadKeyDataStateType] = @(kDeadKeyTypeExisting);
	}
	deadKeyData[kDeadKeyDataStateName] = stateName;
	if (makingNewState) {
		NSString *terminator = [self.terminatorString stringValue];
		deadKeyData[kDeadKeyDataTerminator] = terminator;
		deadKeyData[kDeadKeyDataTerminatorSpecified] = @YES;
	}
	else {
		deadKeyData[kDeadKeyDataTerminatorSpecified] = @NO;
	}
	[NSApp endSheet:[self window]];
	callBack(deadKeyData);
}

- (IBAction)pickDeadKey:(id)sender
{
#pragma unused(sender)
	switch ([self.chooseDeadKey selectedRow]) {
		case 0:
				// Direct entry
			[self.deadKeyCode setEnabled:NO];
			break;
			
		case 1:
				// Key code entry
			[self.deadKeyCode setEnabled:YES];
			break;
	}
}

- (BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error
{
#pragma unused(string)
	if (control == self.deadKeyCode) {
			// Bad data
		[self.badKeyCodeMessage setStringValue:error];
		NSBeep();
	}
	return NO;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
#pragma unused(fieldEditor)
	if (control == self.deadKeyCode) {
		[self.badKeyCodeMessage setStringValue:@""];
	}
	return YES;
}

@end

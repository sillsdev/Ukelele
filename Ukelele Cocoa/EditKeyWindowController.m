//
//  EditKeyWindowController.m
//  Ukelele 3
//
//  Created by John Brownie on 20/08/13.
//
//

#import "EditKeyWindowController.h"
#import "UkeleleConstants.h"
#import "UkeleleConstantStrings.h"
#import "UkeleleKeyboardObject.h"

#define kExistingStateRow	0
#define kNewStateRow		1

@interface EditKeyWindowController ()

@end

@implementation EditKeyWindowController {
	NSMutableDictionary *callerData;
	void (^actionCallback)(NSDictionary *callbackData);
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"EditKeyWindow" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
		callerData = nil;
		actionCallback = nil;
    }
    
    return self;
}

+ (EditKeyWindowController *)editKeyWindowController {
	return [[EditKeyWindowController alloc] initWithWindowNibName:@"EditKeyWindow"];
}

- (void)beginInteractionForWindow:(NSWindow *)parentWindow withData:(NSDictionary *)dataDict action:(void (^)(NSDictionary *))theCallback {
	callerData = [dataDict mutableCopy];
	actionCallback = theCallback;
		// Set the modifier states
	NSUInteger modifiers = [callerData[kKeyModifiers] unsignedIntegerValue];
	[self.shiftState setState:modifiers & NSEventModifierFlagShift ? NSControlStateValueOn : NSControlStateValueOff];
	[self.optionState setState:modifiers & NSEventModifierFlagOption ? NSControlStateValueOn : NSControlStateValueOff];
	[self.commandState setState:modifiers & NSEventModifierFlagCommand ? NSControlStateValueOn : NSControlStateValueOff];
	[self.controlState setState:modifiers & NSEventModifierFlagControl ? NSControlStateValueOn : NSControlStateValueOff];
	[self.capsLockState setState:modifiers & NSEventModifierFlagCapsLock ? NSControlStateValueOn : NSControlStateValueOff];
		// Set the selected key code, if any
	NSInteger keyCode = [dataDict[kKeyKeyCode] integerValue];
	if (keyCode != kNoKeyCode) {
		[self.keyCode setIntegerValue:keyCode];
	}
		// Run the sheet
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
	if (keyCode != kNoKeyCode) {
		[self getCurrentOutput:self];
	}
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
#pragma unused(tabView)
	if ([kEditKeyOutputTab isEqualToString:[tabViewItem identifier]]) {
			// Selected the output tab
	}
	else if ([kEditKeyDeadKeyTab isEqualToString:[tabViewItem identifier]]) {
			// Selected the dead key tab
			// Populate the state popup
		UkeleleKeyboardObject *keyboard = callerData[kKeyKeyboardObject];
		NSArray *stateNames = [keyboard stateNamesExcept:kStateNameNone];
		[self.nextState removeAllItems];
		if ([stateNames count] > 0) {
			[self.nextState addItemsWithObjectValues:stateNames];
		}
			// If we have a dead key, then we should select the correct dead key state and terminator
		NSInteger keyCode = [self.keyCode integerValue];
		callerData[kKeyKeyCode] = @(keyCode);
		callerData[kKeyModifiers] = @([self currentModifiers]);
		NSString *nextState;
		BOOL isDeadKey;
		[keyboard getCharOutput:callerData isDead:&isDeadKey nextState:&nextState];
		if (isDeadKey) {
			[self.nextState selectItemWithObjectValue:nextState];
			[self.terminatorField setStringValue:[keyboard getTerminatorForState:nextState]];
			[self.terminatorField selectText:self];
		}
	}
}

- (IBAction)getCurrentOutput:(id)sender {
#pragma unused(sender)
	[self.keyCodeWarning setHidden:YES];
	NSInteger keyCode = [self.keyCode integerValue];
	callerData[kKeyKeyCode] = @(keyCode);
	callerData[kKeyModifiers] = @([self currentModifiers]);
	UkeleleKeyboardObject *keyboard = callerData[kKeyKeyboardObject];
	NSString *displayText = [keyboard getOutputInfoForKey:callerData];
	[self.currentOutput setString:displayText];
	[self.currentOutput setNeedsDisplay:YES];
}

- (NSUInteger)currentModifiers {
	NSUInteger modifiers = 0;
	if ([self.shiftState state] == NSControlStateValueOn) {
		modifiers |= NSEventModifierFlagShift;
	}
	if ([self.optionState state] == NSControlStateValueOn) {
		modifiers |= NSEventModifierFlagOption;
	}
	if ([self.commandState state] == NSControlStateValueOn) {
		modifiers |= NSEventModifierFlagCommand;
	}
	if ([self.controlState state] == NSControlStateValueOn) {
		modifiers |= NSEventModifierFlagControl;
	}
	if ([self.capsLockState state] == NSControlStateValueOn) {
		modifiers |= NSEventModifierFlagCapsLock;
	}
	return modifiers;
}

- (IBAction)acceptKey:(id)sender {
	if ([self.window firstResponder] == self.keyCode) {
		[self.window endEditingFor:self.keyCode];
	}
	if ([[self.keyCode stringValue] length] == 0) {
			// No key code entered
		[self cancelOperation:sender];
		return;
	}
	NSInteger keyCode = [self.keyCode integerValue];
	NSMutableDictionary *callbackDictionary = [NSMutableDictionary dictionary];
	callbackDictionary[kKeyKeyCode] = @(keyCode);
	callbackDictionary[kKeyModifiers] = @([self currentModifiers]);
	if ([kEditKeyOutputTab isEqualToString:[[self.keyType selectedTabViewItem] identifier]]) {
			// It's an output item
		callbackDictionary[kKeyKeyType] = kKeyTypeOutput;
		callbackDictionary[kKeyKeyOutput] = [self.replacementOutput stringValue];
	}
	else if ([kEditKeyDeadKeyTab isEqualToString:[[self.keyType selectedTabViewItem] identifier]]) {
			// It's a dead key
		callbackDictionary[kKeyKeyType] = kKeyTypeDead;
		if ([[self.nextState stringValue] length] == 0) {
				// No selection
			[self.missingStateWarning setHidden:NO];
			return;
		}
		[self.missingStateWarning setHidden:YES];
		NSString *deadKeyState;
		if ([self.nextState indexOfSelectedItem] == -1) {
				// Creating a new state
			deadKeyState = [self.nextState stringValue];
			callbackDictionary[kKeyTerminator] = [self.terminatorField stringValue];
		}
		else {
				// Using an existing state
			deadKeyState = [self.nextState objectValueOfSelectedItem];
		}
		callbackDictionary[kKeyNextState] = deadKeyState;
	}
	[self.window orderOut:self];
	[NSApp endSheet:self.window];
	actionCallback(callbackDictionary);
}

- (IBAction)cancelOperation:(id)sender {
#pragma unused(sender)
	[self.window orderOut:self];
	[NSApp endSheet:self.window];
	actionCallback(nil);
}

- (void)control:(NSControl *)control didFailToValidatePartialString:(NSString *)string errorDescription:(NSString *)error {
#pragma unused(control)
#pragma unused(string)
#pragma unused(error)
	[self.keyCodeWarning setHidden:NO];
	[self.keyCode setStringValue:@""];
}

@end

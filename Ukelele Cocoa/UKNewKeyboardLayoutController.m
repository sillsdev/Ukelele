//
//  UKNewKeyboardLayoutController.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 17/10/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import "UKNewKeyboardLayoutController.h"
#import "UkeleleConstants.h"

@interface UKNewKeyboardLayoutController ()

@end

@implementation UKNewKeyboardLayoutController {
	void (^completionBlock)(NSString *keyboardName, NSUInteger baseLayout, NSUInteger commandLayout, NSUInteger capsLockLayout);
	NSWindow *theParentWindow;
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"NewKeyboardDialog" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName owner:self];
    if (self) {
        // Initialization code here.
		theParentWindow = nil;
    }
    return self;
}

+ (UKNewKeyboardLayoutController *)createController {
	return [[UKNewKeyboardLayoutController alloc] initWithWindowNibName:@"NewKeyboardLayout"];
}

- (void)runDialog:(NSWindow *)parentWindow withCompletion:(void (^)(NSString *, NSUInteger, NSUInteger, NSUInteger))completion {
	completionBlock = completion;
	theParentWindow = parentWindow;
	[self.baseLayoutPopup selectItemAtIndex:baseLayoutEmpty];
	[self.commandLayoutPopup selectItemAtIndex:commandLayoutSame];
	[self.capsLockLayoutPopup selectItemAtIndex:capsLockLayoutSame];
	if (theParentWindow != nil) {
		[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
			return;
		}];
	}
	else {
		[NSApp runModalForWindow:self.window];
	}
}

- (IBAction)acceptSelection:(id)sender {
#pragma unused(sender)
	NSString *keyboardName = [self.keyboardName stringValue];
	BaseLayoutTypes baseLayout = [self.baseLayoutPopup indexOfSelectedItem];
	CommandLayoutTypes commandLayout = [self.commandLayoutPopup indexOfSelectedItem];
	CapsLockLayoutTypes capsLockLayout = [self.capsLockLayoutPopup indexOfSelectedItem];
	[self.window orderOut:self];
	if (theParentWindow != nil) {
		[NSApp endSheet:self.window];
	}
	else {
		[NSApp stopModal];
	}
		// Convert popup values to key map types
	NSUInteger base = kStandardLayoutEmpty;
	switch (baseLayout) {
		case baseLayoutEmpty:
			base = kStandardLayoutEmpty;
			break;
			
		case baseLayoutQWERTY:
			base = kStandardLayoutQWERTY;
			break;
			
		case baseLayoutQWERTZ:
			base = kStandardLayoutQWERTZ;
			break;
			
		case baseLayoutAZERTY:
			base = kStandardLayoutAZERTY;
			break;
			
		case baseLayoutDvorak:
			base = kStandardLayoutDvorak;
			break;
			
		case baseLayoutColemak:
			base = kStandardLayoutColemak;
			break;
			
		case baseLayoutNone:
				// Should never come here!
			break;
	}
	NSUInteger command = kStandardLayoutEmpty;
	switch (commandLayout) {
		case commandLayoutSame:
			command = base;
			break;
			
		case commandLayoutEmpty:
			command = kStandardLayoutEmpty;
			break;
			
		case commandLayoutQWERTY:
			command = kStandardLayoutQWERTY;
			break;
			
		case commandLayoutQWERTZ:
			command = kStandardLayoutQWERTZ;
			break;
			
		case commandLayoutAZERTY:
			command = kStandardLayoutAZERTY;
			break;
			
		case commandLayoutDvorak:
			command = kStandardLayoutDvorak;
			break;
			
		case commandLayoutColemak:
			command = kStandardLayoutColemak;
			break;
			
		case commandLayoutNone:
				// Should never come here!
			break;
	}
	NSUInteger capsLock = kStandardLayoutEmpty;
	switch (capsLockLayout) {
		case capsLockLayoutSame:
			capsLock = base;
			break;
			
		case capsLockLayoutEmpty:
			capsLock = kStandardLayoutEmpty;
			break;
			
		case capsLockLayoutQWERTY:
			capsLock = kStandardLayoutQWERTY;
			break;
			
		case capsLockLayoutQWERTZ:
			capsLock = kStandardLayoutQWERTZ;
			break;
			
		case capsLockLayoutAZERTY:
			capsLock = kStandardLayoutAZERTY;
			break;
			
		case capsLockLayoutDvorak:
			capsLock = kStandardLayoutDvorak;
			break;
			
		case capsLockLayoutColemak:
			capsLock = kStandardLayoutColemak;
			break;
			
		case capsLockLayoutNone:
				// Should never get here!
			break;
	}
		// Get a valid name
	NSString *theName = keyboardName;
	if ([theName length] == 0) {
		theName = @"Untitled";
	}
	completionBlock(theName, base, command, capsLock);
}

- (IBAction)cancelSelection:(id)sender {
#pragma unused(sender)
	[self.window orderOut:self];
	if (theParentWindow != nil) {
		[NSApp endSheet:self.window];
	}
	else {
		[NSApp stopModal];
	}
	completionBlock(nil, kStandardLayoutNone, kStandardLayoutNone, kStandardLayoutNone);
}

@end

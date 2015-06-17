//
//  UKNewKeyboardLayoutController.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 17/10/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import "UKNewKeyboardLayoutController.h"

@interface UKNewKeyboardLayoutController ()

@end

@implementation UKNewKeyboardLayoutController {
	void (^completionBlock)(NSString *keyboardName, BaseLayoutTypes baseLayout, CommandLayoutTypes commandLayout, CapsLockLayoutTypes capsLockLayout);
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"NewKeyboardDialog" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName owner:self];
    if (self) {
        // Initialization code here.
    }
    return self;
}

+ (UKNewKeyboardLayoutController *)createController {
	return [[UKNewKeyboardLayoutController alloc] initWithWindowNibName:@"NewKeyboardLayout"];
}

- (void)runDialog:(NSWindow *)parentWindow withCompletion:(void (^)(NSString *, BaseLayoutTypes, CommandLayoutTypes, CapsLockLayoutTypes))completion {
	completionBlock = completion;
	[self.baseLayoutPopup selectItemAtIndex:baseLayoutEmpty];
	[self.commandLayoutPopup selectItemAtIndex:commandLayoutSame];
	[self.capsLockLayoutPopup selectItemAtIndex:capsLockLayoutSame];
	[NSApp beginSheet:self.window modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)acceptSelection:(id)sender {
#pragma unused(sender)
	NSString *keyboardName = [self.keyboardName stringValue];
	BaseLayoutTypes baseLayout = [self.baseLayoutPopup indexOfSelectedItem];
	CommandLayoutTypes commandLayout = [self.commandLayoutPopup indexOfSelectedItem];
	CapsLockLayoutTypes capsLockLayout = [self.capsLockLayoutPopup indexOfSelectedItem];
	[self.window orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(keyboardName, baseLayout, commandLayout, capsLockLayout);
}

- (IBAction)cancelSelection:(id)sender {
#pragma unused(sender)
	[self.window orderOut:self];
	[NSApp endSheet:self.window];
	completionBlock(nil, baseLayoutNone, commandLayoutNone, capsLockLayoutNone);
}

@end

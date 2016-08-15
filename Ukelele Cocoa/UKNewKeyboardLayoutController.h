//
//  UKNewKeyboardLayoutController.h
//  Ukelele Cocoa
//
//  Created by John Brownie on 17/10/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSUInteger, BaseLayoutTypes) {
    baseLayoutEmpty,
    baseLayoutQWERTY,
    baseLayoutQWERTZ,
	baseLayoutAZERTY,
	baseLayoutDvorak,
	baseLayoutColemak,
	baseLayoutNone
};

typedef NS_ENUM(NSUInteger, CommandLayoutTypes) {
    commandLayoutSame,
    commandLayoutEmpty,
    commandLayoutQWERTY,
	commandLayoutQWERTZ,
	commandLayoutAZERTY,
	commandLayoutDvorak,
	commandLayoutColemak,
	commandLayoutNone
};

typedef NS_ENUM(NSUInteger, CapsLockLayoutTypes) {
    capsLockLayoutSame,
    capsLockLayoutEmpty,
	capsLockLayoutQWERTY,
	capsLockLayoutQWERTZ,
	capsLockLayoutAZERTY,
	capsLockLayoutDvorak,
	capsLockLayoutColemak,
	capsLockLayoutNone
};

@interface UKNewKeyboardLayoutController : NSWindowController

@property (strong) IBOutlet NSTextField *keyboardName;
@property (strong) IBOutlet NSPopUpButton *baseLayoutPopup;
@property (strong) IBOutlet NSPopUpButton *commandLayoutPopup;
@property (strong) IBOutlet NSPopUpButton *capsLockLayoutPopup;

+ (UKNewKeyboardLayoutController *)createController;

- (void)runDialog:(NSWindow *)parentWindow withCompletion:(void (^)(NSString *keyboardName, NSUInteger baseLayout, NSUInteger commandLayout, NSUInteger capsLockLayout))completion;

- (IBAction)acceptSelection:(id)sender;
- (IBAction)cancelSelection:(id)sender;

@end

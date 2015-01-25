//
//  UKNewKeyboardLayoutController.h
//  Ukelele Cocoa
//
//  Created by John Brownie on 17/10/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum : NSUInteger {
    baseLayoutEmpty,
    baseLayoutQWERTY,
    baseLayoutQWERTZ,
	baseLayoutAZERTY,
	baseLayoutDvorak,
	baseLayoutColemak,
	baseLayoutNone
} BaseLayoutTypes;

typedef enum : NSUInteger {
    commandLayoutSame,
    commandLayoutEmpty,
    commandLayoutQWERTY,
	commandLayoutQWERTZ,
	commandLayoutAZERTY,
	commandLayoutDvorak,
	commandLayoutColemak,
	commandLayoutNone
} CommandLayoutTypes;

typedef enum : NSUInteger {
    capsLockLayoutSame,
    capsLockLayoutEmpty,
	capsLockLayoutQWERTY,
	capsLockLayoutQWERTZ,
	capsLockLayoutAZERTY,
	capsLockLayoutDvorak,
	capsLockLayoutColemak,
	capsLockLayoutNone
} CapsLockLayoutTypes;

@interface UKNewKeyboardLayoutController : NSWindowController

@property (strong) IBOutlet NSTextField *keyboardName;
@property (strong) IBOutlet NSPopUpButton *baseLayoutPopup;
@property (strong) IBOutlet NSPopUpButton *commandLayoutPopup;
@property (strong) IBOutlet NSPopUpButton *capsLockLayoutPopup;

+ (UKNewKeyboardLayoutController *)createController;

- (void)runDialog:(NSWindow *)parentWindow withCompletion:(void (^)(NSString *keyboardName, BaseLayoutTypes baseLayout, CommandLayoutTypes commandLayout, CapsLockLayoutTypes capsLockLayout))completion;

- (IBAction)acceptSelection:(id)sender;
- (IBAction)cancelSelection:(id)sender;

@end

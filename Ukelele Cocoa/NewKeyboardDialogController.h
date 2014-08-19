//
//  NewKeyboardDialogController.h
//  Ukelele Cocoa
//
//  Created by John Brownie on 11/07/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

	// Dictionary keys
extern NSString *kNewKeyboardName;
extern NSString *kNewKeyboardScript;
extern NSString *kNewKeyboardType;
extern NSString *kNewKeyboardCommandLayout;

@interface NewKeyboardDialogController : NSWindowController

@property (strong) IBOutlet NSTextField *keyboardName;
@property (strong) IBOutlet NSPopUpButton *keyboardScript;
@property (strong) IBOutlet NSPopUpButton *keyboardType;
@property (strong) IBOutlet NSPopUpButton *commandKeyLayout;

+ (NewKeyboardDialogController *)newKeyboardDialogController;

@end

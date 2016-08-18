//
//  WarningDialogController.h
//  Ukelele
//
//  Created by John Brownie on 18/08/2016.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface WarningDialogController : NSWindowController

@property (weak) IBOutlet NSButton *dontShowAgain;
@property (strong) IBOutlet NSTextView *warningField;

+ (WarningDialogController *)warningDialog;
+ (BOOL)hasBeenShown;

- (void)loadWarning:(NSURL *)warningFile;
- (void)runDialogForWindow:(NSWindow *)parentWindow;

- (IBAction)closeDialog:(id)sender;

@end

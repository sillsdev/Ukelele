//
//  EditKeyPopoverController.h
//  Ukelele 3
//
//  Created by John Brownie on 1/06/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EditKeyPopoverController : NSViewController

@property (strong) IBOutlet NSTextField *promptField;
@property (strong) IBOutlet NSTextField *standardOutputField;
@property (strong) IBOutlet NSTextField *outputField;
@property (strong) IBOutlet NSButton *standardButton;
@property (strong) void (^callBack)(NSString *);
@property (copy) NSString *standardOutput;
@property (weak) NSPopover *myPopover;

+ (EditKeyPopoverController *)popoverController;

- (IBAction)makeStandard:(id)sender;
- (IBAction)acceptOutput:(id)sender;

@end

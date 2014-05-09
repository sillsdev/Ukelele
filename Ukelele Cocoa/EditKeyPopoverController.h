//
//  EditKeyPopoverController.h
//  Ukelele 3
//
//  Created by John Brownie on 1/06/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface EditKeyPopoverController : NSViewController

@property (weak, readonly) IBOutlet NSTextField *promptField;
@property (weak, readonly) IBOutlet NSTextField *standardOutputField;
@property (weak, readonly) IBOutlet NSTextField *outputField;
@property (weak, readonly) IBOutlet NSButton *standardButton;
@property (strong) void (^callBack)(NSString *);
@property (copy) NSString *standardOutput;

- (IBAction)makeStandard:(id)sender;
- (IBAction)acceptOutput:(id)sender;

@end

//
//  AskTextViewController.h
//  Ukelele
//
//  Created by John Brownie on 21/08/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AskTextViewController : NSViewController

@property (strong) IBOutlet NSTextField *textField;
@property (strong) IBOutlet NSTextField *messageField;
@property (strong) void (^callBack)(NSString *);
@property (weak) NSPopover *myPopover;

- (IBAction)acceptText:(id)sender;
- (IBAction)cancelText:(id)sender;

+ (AskTextViewController *)askViewText;

- (void)setupPopoverWithText:(NSString *)messageText callback:(void (^)(NSString *))theCallback;

@end

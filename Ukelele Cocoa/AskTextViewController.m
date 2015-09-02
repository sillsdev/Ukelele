//
//  AskTextViewController.m
//  Ukelele
//
//  Created by John Brownie on 21/08/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import "AskTextViewController.h"

#define AskTextViewNibFileName @"AskTextView"
#define AskTextViewWindowName @"AskTextView"

@implementation AskTextViewController {
	BOOL hasCompleted;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
			// Initialise
		hasCompleted = NO;
		_invalidStrings = nil;
		_warningString = @"";
	}
	return self;
}

+ (AskTextViewController *)askViewText {
	return [[AskTextViewController alloc] initWithNibName:AskTextViewWindowName bundle:nil];
}

- (void)setupPopoverWithText:(NSString *)messageText callback:(void (^)(NSString *))theCallback {
	[self.messageField setStringValue:messageText];
	[self setCallBack:theCallback];
	hasCompleted = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

- (IBAction)acceptText:(id)sender {
#pragma unused(sender)
	if (!hasCompleted) {
		if (self.invalidStrings) {
				// Check for a valid string
			NSString *theText = [self.textField stringValue];
			if ([self.invalidStrings containsObject:theText]) {
					// Invalid string
				[self.messageField setStringValue:self.warningString];
				[self.textField selectText:self];
				return;
			}
				// Delete the invalid strings
			self.invalidStrings = nil;
		}
		hasCompleted = YES;
		self.callBack([self.textField stringValue]);
		[self.myPopover performClose:self];
	}
}

- (IBAction)cancelText:(id)sender {
#pragma unused(sender)
	if (!hasCompleted) {
		hasCompleted = YES;
		if (self.invalidStrings) {
			self.invalidStrings = nil;
		}
		self.callBack(nil);
		[self.myPopover performClose:self];
	}
}
@end

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
		hasCompleted = YES;
		self.callBack([self.textField stringValue]);
		[self.myPopover performClose:self];
	}
}

- (IBAction)cancelText:(id)sender {
#pragma unused(sender)
	if (!hasCompleted) {
		hasCompleted = YES;
		self.callBack(nil);
		[self.myPopover performClose:self];
	}
}
@end

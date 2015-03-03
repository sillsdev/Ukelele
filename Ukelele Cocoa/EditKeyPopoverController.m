//
//  EditKeyPopoverController.m
//  Ukelele 3
//
//  Created by John Brownie on 1/06/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "EditKeyPopoverController.h"

@implementation EditKeyPopoverController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (EditKeyPopoverController *)popoverController {
	return [[EditKeyPopoverController alloc] initWithNibName:@"EditKeyPopover" bundle:nil];
}

- (IBAction)makeStandard:(id)sender
{
	self.callBack(self.standardOutput);
	[self.myPopover performClose:self];
}

- (IBAction)cancelOperation:(id)sender
{
	self.callBack(nil);
	[self.myPopover performClose:self];
}

- (IBAction)acceptOutput:(id)sender
{
	self.callBack([self.outputField stringValue]);
	[self.myPopover performClose:self];
}

@end

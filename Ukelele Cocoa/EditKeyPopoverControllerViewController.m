//
//  EditKeyPopoverController.m
//  Ukelele 3
//
//  Created by John Brownie on 1/06/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "EditKeyPopoverController.h"

@interface EditKeyPopoverController ()

@end

@implementation EditKeyPopoverController

@synthesize promptField;
@synthesize standardOutputField;
@synthesize outputField;
@synthesize standardButton;
@synthesize actionTarget;
@synthesize actionSelector;
@synthesize standardOutput;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (IBAction)makeStandard:(id)sender
{
	[actionTarget performSelector:actionSelector withObject:standardOutput];
	[[[self view] window] close];
}

- (IBAction)cancelOperation:(id)sender
{
	[actionTarget performSelector:actionSelector withObject:nil];
	[[[self view] window] close];
}

- (IBAction)acceptOutput:(id)sender
{
	[actionTarget performSelector:actionSelector withObject:[outputField stringValue]];
	[[[self view] window] close];
}

@end

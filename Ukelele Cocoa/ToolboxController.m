//
//  ToolboxController.m
//  Ukelele 3
//
//  Created by John Brownie on 26/12/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "ToolboxController.h"

@implementation ToolboxController

@synthesize toolboxData;

- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner
{
    self = [super initWithWindowNibName:windowNibName owner:owner];
    if (self) {
        // Initialization code here.
		toolboxData = [ToolboxData sharedToolboxData];
		[_stickyModifiers setState:[toolboxData stickyModifiers] ? NSOnState : NSOffState];
		[_JISOnly setState:[toolboxData JISOnly] ? NSOnState : NSOffState];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
}

+ (ToolboxController *)sharedToolboxController {
	static ToolboxController *theInstance = nil;
	if (!theInstance) {
		theInstance = [[ToolboxController alloc] initWithWindowNibName:@"ToolboxController"];
	}
	return  theInstance;
}

@end

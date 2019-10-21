//
//  ToolboxController.m
//  Ukelele 3
//
//  Created by John Brownie on 26/12/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "ToolboxController.h"
#import "UkeleleConstantStrings.h"

@implementation ToolboxController

@synthesize toolboxData;

- (instancetype)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner
{
    self = [super initWithWindowNibName:windowNibName owner:owner];
    if (self) {
        // Initialization code here.
		toolboxData = [ToolboxData sharedToolboxData];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
	[_stickyModifiers setState:[toolboxData stickyModifiers] ? NSOnState : NSOffState];
	[_JISOnly setState:[toolboxData JISOnly] ? NSOnState : NSOffState];
	[_showCodePoints setState:[toolboxData showCodePoints] ? NSOnState : NSOffState];
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
	NSData *frameData =[theDefaults objectForKey:UKToolboxWindowLocation];
	if (frameData != nil) {
		NSRect newFrame = *(NSRect *)[frameData bytes];
		[self.window setFrame:newFrame display:NO];
	}
}

+ (ToolboxController *)sharedToolboxController {
	static ToolboxController *theInstance = nil;
	if (!theInstance) {
		theInstance = [[ToolboxController alloc] initWithWindowNibName:@"ToolboxController"];
	}
	return  theInstance;
}

#pragma mark Delegate methods

- (void)windowDidMove:(NSNotification *)notification {
#pragma unused(notification)
	NSRect newFrame = [self.window frame];
	NSData *frameData = [NSData dataWithBytes:&newFrame length:sizeof(NSRect)];
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
	[theDefaults setObject:frameData forKey:UKToolboxWindowLocation];
}

- (void)windowDidResize:(NSNotification *)notification {
#pragma unused(notification)
	NSRect newFrame = [self.window frame];
	NSData *frameData = [NSData dataWithBytes:&newFrame length:sizeof(NSRect)];
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
	[theDefaults setObject:frameData forKey:UKToolboxWindowLocation];
}

@end

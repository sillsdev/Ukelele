//
//  AskYesNoController.m
//  Ukelele 3
//
//  Created by John Brownie on 28/12/13.
//
//

#import "AskYesNoController.h"

@interface AskYesNoController ()

@end

@implementation AskYesNoController {
	void (^completionBlock)(BOOL);
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[NSBundle loadNibNamed:@"AskYesNo" owner:self];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

+ (AskYesNoController *)askYesNoController {
	return [[AskYesNoController alloc] initWithWindowNibName:@"AskYesNo"];
}

- (void)askQuestion:(NSString *)theQuestion forWindow:(NSWindow *)theWindow completion:(void (^)(BOOL))theBlock {
	completionBlock = theBlock;
	[NSApp beginSheet:[self window]
	   modalForWindow:theWindow
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}

- (IBAction)handleYes:(id)sender {
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(YES);
}

- (IBAction)handleNo:(id)sender {
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(NO);
}

@end

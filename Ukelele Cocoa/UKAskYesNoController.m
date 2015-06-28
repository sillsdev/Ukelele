//
//  AskYesNoController.m
//  Ukelele 3
//
//  Created by John Brownie on 28/12/13.
//
//

#import "UKAskYesNoController.h"

@interface UKAskYesNoController ()

@end

@implementation UKAskYesNoController {
	void (^completionBlock)(BOOL);
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"AskYesNo" owner:self topLevelObjects:nil];
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

+ (UKAskYesNoController *)askYesNoController {
	return [[UKAskYesNoController alloc] initWithWindowNibName:@"AskYesNo"];
}

- (void)askQuestion:(NSString *)theQuestion forWindow:(NSWindow *)theWindow completion:(void (^)(BOOL))theBlock {
	[self.questionField setStringValue:theQuestion];
	completionBlock = theBlock;
	[NSApp beginSheet:[self window]
	   modalForWindow:theWindow
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}

- (IBAction)handleYes:(id)sender {
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(YES);
}

- (IBAction)handleNo:(id)sender {
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(NO);
}

@end

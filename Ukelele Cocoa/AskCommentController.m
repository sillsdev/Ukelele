//
//  AskCommentController.m
//  Ukelele 3
//
//  Created by John Brownie on 30/09/13.
//
//

#import "AskCommentController.h"

@interface AskCommentController () {
	void (^completionBlock)(NSString *);
}

@end

@implementation AskCommentController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"AskCommentSheet" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (AskCommentController *)askCommentController {
	return [[AskCommentController alloc] initWithWindowNibName:@"AskCommentSheet"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)askCommentForWindow:(NSWindow *)parentWindow completion:(void (^)(NSString *))theBlock {
	completionBlock = theBlock;
	[NSApp beginSheet:[self window]
	   modalForWindow:parentWindow
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}

- (IBAction)acceptComment:(id)sender {
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock([self.commentField string]);
}

- (IBAction)cancelComment:(id)sender {
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(nil);
}

@end

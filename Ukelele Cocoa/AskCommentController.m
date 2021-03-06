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

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
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
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (IBAction)acceptComment:(id)sender {
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock([self.commentField string]);
}

- (IBAction)cancelComment:(id)sender {
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(nil);
}

@end

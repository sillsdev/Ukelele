//
//  AskCommentController.h
//  Ukelele 3
//
//  Created by John Brownie on 30/09/13.
//
//

#import <Cocoa/Cocoa.h>

@interface AskCommentController : NSWindowController

@property (strong) IBOutlet NSTextView *commentField;

+ (AskCommentController *)askCommentController;

- (void)askCommentForWindow:(NSWindow *)parentWindow completion:(void (^)(NSString *))theBlock;

- (IBAction)acceptComment:(id)sender;
- (IBAction)cancelComment:(id)sender;

@end

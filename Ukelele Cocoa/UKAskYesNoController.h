//
//  AskYesNoController.h
//  Ukelele 3
//
//  Created by John Brownie on 28/12/13.
//
//

#import <Cocoa/Cocoa.h>

@interface UKAskYesNoController : NSWindowController

@property (strong) IBOutlet NSTextField *questionField;

- (IBAction)handleYes:(id)sender;
- (IBAction)handleNo:(id)sender;

+ (UKAskYesNoController *)askYesNoController;

- (void)askQuestion:(NSString *)theQuestion forWindow:(NSWindow *)theWindow completion:(void (^)(BOOL))theBlock;

@end

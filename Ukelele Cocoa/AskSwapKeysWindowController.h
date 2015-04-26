//
//  AskSwapKeysWindowController.h
//  Ukelele 3
//
//  Created by John Brownie on 15/08/13.
//
//

#import <Cocoa/Cocoa.h>

@interface AskSwapKeysWindowController : NSWindowController<NSTextFieldDelegate>

@property (strong) IBOutlet NSTextField *keyCode1;
@property (strong) IBOutlet NSTextField *keyCode2;
@property (strong) IBOutlet NSTextField *keyCodeWarning;
@property (strong) IBOutlet NSTextField *sameKeyCodeWarning;

+ (AskSwapKeysWindowController *)askSwapKeysWindowController;

- (void)beginInteractionWithWindow:(NSWindow *)theWindow initialSelection:(NSUInteger)selectedKey callback:(void (^)(NSArray *))theCallback;

@end

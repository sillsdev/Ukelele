//
//  SelectKeyByCodeController.h
//  Ukelele 3
//
//  Created by John Brownie on 4/09/13.
//
//

#import <Cocoa/Cocoa.h>

@interface SelectKeyByCodeController : NSWindowController<NSTextFieldDelegate>

@property (strong) IBOutlet NSTextField *majorTextField;
@property (strong) IBOutlet NSTextField *minorTextField;
@property (strong) IBOutlet NSTextField *keyCodeField;

+ (SelectKeyByCodeController *)selectKeyByCodeController;

- (void)beginDialogWithWindow:(NSWindow *)parentWindow completionBlock:(void (^)(NSInteger))callback;
- (void)setMajorText:(NSString *)majorText;
- (void)setMinorText:(NSString *)minorText;

- (IBAction)acceptKeyCode:(id)sender;
- (IBAction)cancelKeyCode:(id)sender;

@end

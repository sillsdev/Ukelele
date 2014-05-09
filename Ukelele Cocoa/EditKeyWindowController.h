//
//  EditKeyWindowController.h
//  Ukelele 3
//
//  Created by John Brownie on 20/08/13.
//
//

#import <Cocoa/Cocoa.h>

	// Tab identifiers
#define kEditKeyOutputTab	@"Output"
#define kEditKeyDeadKeyTab	@"DeadKey"

	// Key types
#define kKeyTypeOutput	@"Output"
#define kKeyTypeDead	@"DeadKey"

@interface EditKeyWindowController : NSWindowController<NSTextFieldDelegate, NSTabViewDelegate>

@property (strong) IBOutlet NSTextField *keyCode;
@property (strong) IBOutlet NSTextField *replacementOutput;
@property (strong) IBOutlet NSTextField *terminatorField;
@property (strong) IBOutlet NSTextView *currentOutput;
@property (strong) IBOutlet NSTextField *keyCodeWarning;
@property (strong) IBOutlet NSButton *shiftState;
@property (strong) IBOutlet NSButton *optionState;
@property (strong) IBOutlet NSButton *commandState;
@property (strong) IBOutlet NSButton *controlState;
@property (strong) IBOutlet NSButton *capsLockState;
@property (strong) IBOutlet NSTabView *keyType;
@property (strong) IBOutlet NSComboBox *nextState;
@property (strong) IBOutlet NSTextField *missingStateWarning;

- (IBAction)getCurrentOutput:(id)sender;
- (IBAction)acceptKey:(id)sender;
- (IBAction)cancelOperation:(id)sender;

+ (EditKeyWindowController *)editKeyWindowController;

- (void)beginInteractionForWindow:(NSWindow *)parentWindow withData:(NSDictionary *)dataDict action:(void (^)(NSDictionary *callbackData))theCallback;

@end

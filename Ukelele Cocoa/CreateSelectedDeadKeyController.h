//
//  CreateSelectedDeadKeyController.h
//  Ukelele 3
//
//  Created by John Brownie on 3/09/13.
//
//

#import <Cocoa/Cocoa.h>

#define kCreateSelectedDeadKeyState	@"CreateSelectedDeadKeyState"
#define kCreateSelectedDeadKeyTerminator	@"CreateSelectedDeadKeyTerminator"

@class UkeleleKeyboardObject;

@interface CreateSelectedDeadKeyController : NSWindowController

@property (strong) IBOutlet NSComboBox *stateField;
@property (strong) IBOutlet NSTextField *missingStateWarning;
@property (strong) IBOutlet NSTextField *terminatorField;
@property (strong) IBOutlet NSTextField *invalidStateNameWarning;

- (IBAction)acceptDeadKey:(id)sender;
- (IBAction)cancelDeadKey:(id)sender;

+ (CreateSelectedDeadKeyController *)createSelectedDeadKeyController;

- (void)runSheetForWindow:(NSWindow *)parentWindow keyboard:(UkeleleKeyboardObject *)keyboardObject keyCode:(NSInteger)keyCode targetState:(NSString *)targetState completionBlock:(void (^)(NSDictionary *))callback;

@end

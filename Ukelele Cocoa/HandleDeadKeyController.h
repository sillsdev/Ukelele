//
//  HandleDeadKeyController.h
//  Ukelele 3
//
//  Created by John Brownie on 14/09/13.
//
//

#import <Cocoa/Cocoa.h>

@class UkeleleKeyboardObject;

#define kHandleDeadKeyType	@"Type"
#define kHandleDeadKeyString	@"String"

typedef enum HandleDeadKeyType: NSInteger {
	kHandleDeadKeyChangeTerminator = 0,
	kHandleDeadKeyChangeState = 1,
	kHandleDeadKeyChangeToOutput = 2,
	kHandleDeadKeyEnterState = 3
} HandleDeadKeyType;

@interface HandleDeadKeyController : NSWindowController

@property (strong) IBOutlet NSTextField *infoField;
@property (strong) IBOutlet NSMatrix *choiceGroup;
@property (strong) IBOutlet NSTextField *terminatorField;
@property (strong) IBOutlet NSComboBox *statePopup;
@property (strong) IBOutlet NSTextField *outputField;
@property (strong) IBOutlet NSTextField *terminatorLabel;
@property (strong) IBOutlet NSTextField *stateLabel;
@property (strong) IBOutlet NSTextField *outputLabel;

+ (HandleDeadKeyController *)handleDeadKeyController;

- (void)beginInteractionWithWindow:(NSWindow *)parentWindow
						  document:(UkeleleKeyboardObject *)theDocument
						  forState:(NSString *)theState
						 nextState:(NSString *)nextState
				   completionBlock:(void (^)(NSDictionary *))callback;

- (IBAction)acceptChoice:(id)sender;
- (IBAction)cancelChoice:(id)sender;
- (IBAction)chooseAction:(id)sender;

@end

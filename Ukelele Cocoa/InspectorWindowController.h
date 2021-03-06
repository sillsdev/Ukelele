//
//  InspectorWindowController.h
//  Ukelele 3
//
//  Created by John Brownie on 10/02/13.
//
//

#import <Cocoa/Cocoa.h>

@class UkeleleKeyboardObject;
@class UKKeyboardController;
@class UKKeyboardDocument;

#define kTabIdentifierDocument	@"Document"
#define kTabIdentifierOutput	@"Output"
#define kTabIdentifierState		@"State"

@interface InspectorWindowController : NSWindowController<NSTableViewDelegate, NSTabViewDelegate, NSWindowDelegate>

@property (strong) IBOutlet NSTabView *tabView;

@property (strong) IBOutlet NSTextField *outputField;
@property (strong) IBOutlet NSTableView *stateStackTable;

@property (strong) IBOutlet NSTextField *modifiersField;
@property (strong) IBOutlet NSTextField *modifierMatchField;
@property (strong) IBOutlet NSTextField *keyCodeField;
@property (strong) IBOutlet NSTextField *selectedKeyField;

@property (strong) IBOutlet NSTextField *keyboardNameField;
@property (strong) IBOutlet NSPopUpButton *keyboardScriptButton;
@property (strong) IBOutlet NSTextField *keyboardIDField;

@property (nonatomic, strong) IBOutlet NSArray *stateStack;
@property (strong) NSArray *scriptList;
@property (strong) IBOutlet NSTextField *scriptDescription;
@property (strong) NSArray *scriptDescriptionList;

@property (weak, nonatomic) UkeleleKeyboardObject *currentKeyboard;
@property (weak, nonatomic) UKKeyboardController *currentWindow;
@property (weak, nonatomic) UKKeyboardDocument *currentBundle;

- (IBAction)selectScript:(id)sender;

+ (InspectorWindowController *)getInstance;
- (void)setKeyboardSectionEnabled:(BOOL)enabled;

@end

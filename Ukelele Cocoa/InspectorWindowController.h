//
//  InspectorWindowController.h
//  Ukelele 3
//
//  Created by John Brownie on 10/02/13.
//
//

#import <Cocoa/Cocoa.h>

@class UkeleleDocument;
@class UKKeyboardLayoutBundle;

#define kTabIdentifierDocument	@"Document"
#define kTabIdentifierOutput	@"Output"
#define kTabIdentifierState		@"State"

@interface InspectorWindowController : NSWindowController<NSTableViewDelegate, NSTabViewDelegate>

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
@property (strong) IBOutlet NSButton *generateButton;
@property (strong) IBOutlet NSTextField *bundleNameField;
@property (strong) IBOutlet NSTextField *bundleVersionField;
@property (strong) IBOutlet NSTextField *buildVersionField;
@property (strong) IBOutlet NSTextField *sourceVersionField;

@property (nonatomic, strong) IBOutlet NSArray *stateStack;
@property (strong) IBOutlet NSArray *scriptList;

@property (weak, nonatomic) UkeleleDocument *currentKeyboard;
@property (weak, nonatomic) UKKeyboardLayoutBundle *currentBundle;

+ (InspectorWindowController *)getInstance;
- (IBAction)generateID:(id)sender;
- (void)setScript:(NSInteger)scriptCode;
- (void)setKeyboardSectionEnabled:(BOOL)enabled;
- (void)setBundleSectionEnabled:(BOOL)enabled;

@end

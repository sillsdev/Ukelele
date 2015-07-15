//
//  UKKeyboardController.h
//  Ukelele Cocoa
//
//  Created by John Brownie on 11/06/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ModifiersDataSource.h"
#import "UkeleleKeyboardObject.h"
#import "UKMenuDelegate.h"
#import "UKKeyCapClick.h"
#import "UKInteractionCompletion.h"
#import "UKInteractionHandler.h"
#import "UkeleleDocumentDelegate.h"
#import "AskNewKeyMap.h"
#import "AskFromList.h"
#import "ChooseScale.h"
#import "ChooseKeyboardIDWindowController.h"
#import "ReplaceNameSheet.h"
#import "KeyboardTypeSheet.h"
#import "ModifiersSheet.h"

enum ToolbarItemTags {
	kToolbarTagCreate = 10,
	kToolbarTagEnter = 11,
	kToolbarTagLeave = 12,
	kToolbarTagUnlink = 13
};

@class UKKeyboardDocument;
@class UKKeyboardPrintInfo;

@interface UKKeyboardController : NSWindowController<NSWindowDelegate,
	NSTableViewDelegate, NSTabViewDelegate, NSTextDelegate, UKKeyCapClick,
	UKMenuDelegate, UKInteractionCompletion, UkeleleDocumentDelegate>
{
	NSMutableDictionary *internalState;
	NSMutableArray *stateStack;
	NSMutableArray *scalesList;
	NSMutableArray *modifiersList;
	id<UKInteractionHandler> interactionHandler;
	NSInteger selectedKey;
	BOOL commentChanged;
	NSDictionary *deadKeyData;
		// Sheets
	NSAlert *documentAlert;
	AskNewKeyMap *askNewKeyMap;
	AskFromList *askFromList;
	ChooseScale *chooseScale;
	ChooseKeyboardIDWindowController *keyboardIDSheet;
	KeyboardTypeSheet *keyboardTypeSheet;
	ReplaceNameSheet *replaceNameSheet;
	ModifiersSheet *modifiersSheet;
	NSPrintInfo *printInfo;
	UKKeyboardPrintInfo *printingInfo;
}

	// Outlets
@property (strong) IBOutlet NSMenu *deadKeyContextualMenu;
@property (strong) IBOutlet NSMenu *nonDeadKeyContextualMenu;
@property (strong) IBOutlet NSTabView *tabView;
	// Keyboard tab
@property (strong) IBOutlet NSComboBox *scaleComboBox;
@property (strong) IBOutlet NSTextField *messageBar;
@property (strong) IBOutlet NSScrollView *keyboardView;
@property (strong) IBOutlet NSButton *cancelButton;
	// Modifiers tab
@property (strong) IBOutlet NSTableView *modifiersTableView;
@property (strong) IBOutlet NSButton *removeModifiersButton;
@property (strong) IBOutlet NSPopUpButton *defaultIndexButton;
@property (strong) IBOutlet NSButton *simplifyModifiersButton;
@property (strong) IBOutlet ModifiersDataSource *modifiersDataSource;
	// Comments tab
@property (strong) IBOutlet NSTextView *commentPane;
@property (strong) IBOutlet NSTextField *commentBindingPane;
@property (strong) IBOutlet NSButton *firstCommentButton;
@property (strong) IBOutlet NSButton *previousCommentButton;
@property (strong) IBOutlet NSButton *nextCommentButton;
@property (strong) IBOutlet NSButton *lastCommentButton;
@property (strong) IBOutlet NSButton *removeCommentButton;

	// Keyboard layout
@property (strong) UkeleleKeyboardObject *keyboardLayout;
@property (nonatomic) NSInteger keyboardID;
@property (nonatomic) NSInteger keyboardScript;
@property (strong) NSString *keyboardName;
@property (weak, readonly) NSURL *iconFile;
	// Current state
@property (nonatomic) NSUInteger currentModifiers;
@property (nonatomic, readonly) NSInteger currentSelectedKey;
@property (weak, readonly) NSString *currentState;
@property (weak) UKKeyboardDocument *parentDocument;
@property (strong, nonatomic) NSUndoManager *undoManager;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *keyboardDisplayName;
@property (NS_NONATOMIC_IOSONLY, readonly) CGFloat currentScale;
@property (NS_NONATOMIC_IOSONLY, readonly) NSUInteger currentKeyboard;

	// Actions
	// View scale
- (IBAction)setScaleValue:(id)sender;
- (IBAction)setScaleLevel:(id)sender;
	// Dead keys
- (IBAction)enterDeadKeyState:(id)sender;
- (IBAction)leaveDeadKeyState:(id)sender;
- (IBAction)createDeadKeyState:(id)sender;
- (IBAction)changeTerminator:(id)sender;
- (IBAction)makeOutput:(id)sender;
- (IBAction)makeDeadKey:(id)sender;
- (IBAction)changeOutput:(id)sender;
- (IBAction)changeNextState:(id)sender;
- (IBAction)importDeadKey:(id)sender;
	// Key actions
- (IBAction)cutKey:(id)sender;
- (IBAction)copyKey:(id)sender;
- (IBAction)pasteKey:(id)sender;
- (IBAction)editKey:(id)sender;
- (IBAction)swapKeys:(id)sender;
- (IBAction)swapKeysByCode:(id)sender;
- (IBAction)selectKeyByCode:(id)sender;
- (IBAction)unlinkKey:(id)sender;
- (IBAction)unlinkKeyAskingKeyCode:(id)sender;
- (IBAction)attachComment:(id)sender;
	// Other actions
- (IBAction)setKeyboardType:(id)sender;
- (IBAction)installForCurrentUser:(id)sender;
- (IBAction)installForAllUsers:(id)sender;
- (IBAction)findKeyStroke:(id)sender;

	// Printing
- (IBAction)runPageLayout:(id)sender;
- (void)printOperationDidRun:(NSPrintOperation *)printOperation success:(BOOL)success contextInfo:(void *)contextInfo;

	// Accessors
- (NSRect)keyRect:(NSInteger)keyCode;

	// Validate interface element states
- (BOOL)setsStatusForSelector:(SEL)selector;
- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem;

	// Messages
- (void)messageModifiersChanged:(int)modifiers;
- (void)messageMouseEntered:(int)keyCode;
- (void)messageMouseExited:(int)keyCode;
- (void)messageKeyDown:(int)keyCode;
- (void)messageKeyUp:(int)keyCode;
- (void)messageClick:(int)keyCode;
- (void)messageDoubleClick:(int)keyCode;
- (void)messageDragText:(NSString *)draggedText toKey:(int)keyCode;
- (void)messageEditPaneClosed;
- (void)messageScaleChanged:(CGFloat)newScale;
- (void)messageScaleCompleted;

	// Dead key actions
- (void)changeOutputForKey:(NSDictionary *)keyDataDict to:(NSString *)newOutput usingBaseMap:(BOOL)usingBaseMap;
- (void)changeTerminatorForState:(NSString *)stateName to:(NSString *)newTerminator;
- (void)enterDeadKeyStateWithName:(NSString *)stateName;
- (void)leaveCurrentDeadKeyState;
- (void)makeKeyDeadKey:(NSDictionary *)keyDataDict state:(NSString *)nextState;
- (void)makeDeadKeyOutput:(NSDictionary *)keyDataDict output:(NSString *)newOutput;
- (void)changeDeadKeyNextState:(NSDictionary *)keyDataDict newState:(NSString *)nextState;
- (void)createNewDeadKey:(NSDictionary *)keyDataDict nextState:(NSString *)nextState usingExistingState:(BOOL)usingExisting;

	// Other actions
- (void)updateWindow;
- (void)showEditingPaneForKeyCode:(int)keyCode text:(NSString *)initialText target:(id)target action:(SEL)action;
- (void)setMessageBarText:(NSString *)message;
- (void)setSelectedKey:(NSInteger)keyCode;
- (void)clearSelectedKey;

- (void)inspectorDidAppear;
- (void)inspectorDidActivateTab:(NSString *)tabIdentifier;

- (void)unlinkKeyWithKeyCode:(NSInteger)keyCode andModifiers:(NSUInteger)modifierCombination;
- (void)doUnlinkKey:(NSDictionary *)keyDataDict;
- (void)doRelinkKey:(NSDictionary *)keyDataDict originalAction:(NSString *)actionName;
- (void)unlinkModifierCombination;
- (void)swapKeyWithCode:(NSInteger)keyCode1 andKeyWithCode:(NSInteger)keyCode2;

@end

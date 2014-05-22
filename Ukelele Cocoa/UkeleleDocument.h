//
//  UkeleleDocument.h
//  Ukelele 3
//
//  Created by John Brownie on 11/01/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UkeleleKeyboardObject.h"
#import "UKInteractionHandler.h"
#import "UKInteractionCompletion.h"
#import "ModifiersDataSource.h"
#import "ModifiersSheet.h"
#import "AskFromList.h"
#import "AskNewKeyMap.h"
#import "ChooseScale.h"
#import "UkeleleDocumentDelegate.h"
#import "CreateDeadKeyHandler.h"
#import "KeyboardTypeSheet.h"
#import "ReplaceNameSheet.h"
#import "ChooseKeyboardIDWindowController.h"
#import "UKKeyboardLayoutBundle.h"
#import "UKMenuDelegate.h"
#import "UKKeyCapClick.h"

enum ToolbarItemTags {
	kToolbarTagCreate = 10,
	kToolbarTagEnter = 11,
	kToolbarTagLeave = 12,
	kToolbarTagUnlink = 13
};

@interface UkeleleDocument : NSDocument<NSWindowDelegate,
    NSTableViewDelegate,
    NSTabViewDelegate,
	NSTextDelegate,
    UKInteractionCompletion,
    UkeleleDocumentDelegate,
	UKMenuDelegate,
	UKKeyCapClick>
{
    IBOutlet NSWindow *ukeleleWindow;
    IBOutlet NSTabView *tabView;
	IBOutlet NSComboBox *scaleComboBox;
	IBOutlet NSTextField *messageBar;
	IBOutlet NSScrollView *keyboardView;
    IBOutlet NSTableView *modifiersTableView;
    IBOutlet NSButton *removeModifiersButton;
    IBOutlet NSPopUpButton *defaultIndexButton;
    IBOutlet NSButton *simplifyModifiersButton;
    IBOutlet NSTextView *commentPane;
    IBOutlet NSTextField *commentBindingPane;
    IBOutlet NSButton *firstCommentButton;
    IBOutlet NSButton *previousCommentButton;
    IBOutlet NSButton *nextCommentButton;
    IBOutlet NSButton *lastCommentButton;
    IBOutlet NSButton *removeCommentButton;
    NSMutableDictionary *internalState;
	NSMutableArray *stateStack;
	NSMutableArray *scalesList;
	NSMutableArray *modifiersList;
	ModifiersDataSource *modifiersDataSource;
    ModifiersSheet *modifiersSheet;
    AskNewKeyMap *askNewKeyMap;
    AskFromList *askFromList;
    ChooseScale *chooseScale;
    id<UKInteractionHandler> interactionHandler;
	KeyboardTypeSheet *keyboardTypeSheet;
	NSDictionary *deadKeyData;
	NSAlert *documentAlert;
	ReplaceNameSheet *replaceNameSheet;
	ChooseKeyboardIDWindowController *keyboardIDSheet;
	NSInteger selectedKey;
	BOOL commentChanged;
}

@property (readonly) UkeleleKeyboardObject *keyboardLayout;
@property (readonly) NSUInteger currentModifiers;
@property (weak, readonly) NSString *currentState;
@property (weak, readonly) NSURL *iconFile;
@property (weak) UKKeyboardLayoutBundle *parentBundle;
@property (nonatomic) NSInteger keyboardID;
@property (nonatomic) NSInteger keyboardScript;
@property (strong) NSString *keyboardName;
@property (strong) IBOutlet NSMenu *deadKeyContextualMenu;
@property (strong) IBOutlet NSMenu *nonDeadKeyContextualMenu;

- (IBAction)setScaleValue:(id)sender;
- (IBAction)setScaleLevel:(id)sender;
- (IBAction)enterDeadKeyState:(id)sender;
- (IBAction)leaveDeadKeyState:(id)sender;
- (IBAction)createDeadKeyState:(id)sender;
- (IBAction)unlinkKey:(id)sender;
- (IBAction)unlinkKeyAskingKeyCode:(id)sender;
- (IBAction)setKeyboardType:(id)sender;
- (IBAction)importDeadKey:(id)sender;
- (IBAction)changeTerminator:(id)sender;
- (IBAction)swapKeys:(id)sender;
- (IBAction)swapKeysByCode:(id)sender;
- (IBAction)editKey:(id)sender;
- (IBAction)selectKeyByCode:(id)sender;
- (IBAction)cutKey:(id)sender;
- (IBAction)copyKey:(id)sender;
- (IBAction)pasteKey:(id)sender;
- (IBAction)makeOutput:(id)sender;
- (IBAction)makeDeadKey:(id)sender;
- (IBAction)changeNextState:(id)sender;
- (IBAction)changeOutput:(id)sender;
- (IBAction)attachComment:(id)sender;
- (IBAction)installForCurrentUser:(id)sender;
- (IBAction)installForAllUsers:(id)sender;

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

- (id)initWithCurrentInputSource;

- (NSString *)keyboardDisplayName;
- (void)updateWindow;

- (void)showEditingPaneForKeyCode:(int)keyCode text:(NSString *)initialText target:(id)target action:(SEL)action;
- (NSView *)keyboardView;
- (NSRect)keyRect:(NSInteger)keyCode;
- (void)setMessageBarText:(NSString *)message;
- (CGFloat)currentScale;
- (NSUInteger)currentKeyboard;
- (void)setSelectedKey:(NSInteger)keyCode;
- (void)clearSelectedKey;

- (void)changeOutputForKey:(NSDictionary *)keyDataDict to:(NSString *)newOutput usingBaseMap:(BOOL)usingBaseMap;
- (void)changeTerminatorForState:(NSString *)stateName to:(NSString *)newTerminator;
- (void)enterDeadKeyStateWithName:(NSString *)stateName;
- (void)leaveCurrentDeadKeyState;
- (void)makeKeyDeadKey:(NSDictionary *)keyDataDict state:(NSString *)nextState;
- (void)makeDeadKeyOutput:(NSDictionary *)keyDataDict output:(NSString *)newOutput;
- (void)changeDeadKeyNextState:(NSDictionary *)keyDataDict newState:(NSString *)nextState;
- (void)createNewDeadKey:(NSDictionary *)keyDataDict nextState:(NSString *)nextState usingExistingState:(BOOL)usingExisting;

- (void)unlinkKeyWithKeyCode:(NSInteger)keyCode andModifiers:(NSUInteger)modifierCombination;
- (void)doUnlinkKey:(NSDictionary *)keyDataDict;
- (void)doRelinkKey:(NSDictionary *)keyDataDict originalAction:(NSString *)actionName;
- (void)unlinkModifierCombination;
- (void)swapKeyWithCode:(NSInteger)keyCode1 andKeyWithCode:(NSInteger)keyCode2;

- (void)inspectorDidActivateTab:(NSString *)tabIdentifier;

@end

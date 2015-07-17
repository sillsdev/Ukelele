//
//  UkeleleKeyboardObject.h
//  Ukelele 3
//
//  Created by John Brownie on 11/02/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#if defined(__cplusplus)
class UkeleleKeyboard; // Don't import header here
#else
typedef void * UkeleleKeyboard;
#endif
#import "UkeleleDocumentDelegate.h"
#import "ModifiersSheet.h"
#import "RemoveStateData.h"
#import "ActionElementSetWrapper.h"
#import "AddMissingOutputData.h"

#define UKKeyStrokeLookupKeyStrokes	@"UKKeyStrokeLookupKeyStrokes"
#define UKKeyStrokeLookupModifiers @"UKKeyStrokeLookupModifiers"
#define UKKeyStrokeLookupState @"UKKeyStrokeLookupState"
#define UKKeyStrokeLookupKeyCode @"UKKeyStrokeLookupKeyCode"

@class XMLCommentHolderObject;

@interface UkeleleKeyboardObject : NSObject<NSCopying>

@property (readonly) UkeleleKeyboard *keyboard;
@property (weak) id<UkeleleDocumentDelegate> delegate;
@property (nonatomic) NSInteger keyboardGroup;
@property (nonatomic) NSInteger keyboardID;
@property (nonatomic, strong) NSString *keyboardName;
@property (weak) NSWindowController *parentController;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *modifierIndices;
@property (NS_NONATOMIC_IOSONLY) NSUInteger defaultModifierIndex;

- (id)initWithName:(NSString *)keyboardName;
- (id)initWithName:(NSString *)keyboardName base:(NSUInteger)baseLayout command:(NSUInteger)commandLayout capsLock:(NSUInteger)capsLockLayout;
- (id)initWithData:(NSData *)xmlData withError:(NSError **)outError;
- (NSData *)convertToData;
- (void)setParentDocument:(NSDocument *)parent;
- (BOOL)keyMapSelectHasOneModifierCombination:(NSInteger)modifierIndex;
- (void)updateEditingComment;
- (void)addCreationComment;
- (void)assignRandomID;

	// Get information on key output
- (NSString *)getCharOutput:(NSDictionary *)keyDataDict isDead:(BOOL *)deadKey nextState:(NSString **)stateName;
- (BOOL)isDeadKey:(NSDictionary *)keyDataDict;
- (NSString *)getNextState:(NSDictionary *)keyDataDict;
- (NSString *)getOutputInfoForKey:(NSDictionary *)keyDataDict;
- (NSDictionary *)getKeyStrokeForOutput:(NSString *)outputString forKeyboard:(NSUInteger)keyboardID;

	// Transform a key output
- (void)changeOutputForKey:(NSDictionary *)keyDataDict to:(NSString *)newOutput usingBaseMap:(BOOL)usingBaseMap;
- (NSString *)getTerminatorForState:(NSString *)stateName;
- (void)changeTerminatorForState:(NSString *)stateName to:(NSString *)newTerminator;
- (void)makeKeyDeadKey:(NSDictionary *)keyDataDict state:(NSString *)nextState;
- (void)makeDeadKeyOutput:(NSDictionary *)keyDataDict output:(NSString *)newOutput;
- (void)changeDeadKeyNextState:(NSDictionary *)keyDataDict toState:(NSString *)newState;

	// Actions
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *actionNames;

- (BOOL)isActionElement:(NSDictionary *)keyDataDict;
- (NSString *)actionNameForKey:(NSDictionary *)keyDataDict;
- (void)unlinkKey:(NSDictionary *)keyDataDict;
- (void)relinkKey:(NSDictionary *)keyDataDict actionName:(NSString *)originalAction;
- (void)unlinkModifierSet:(NSUInteger)modifierCombination forKeyboard:(NSInteger)keyboardID;
- (NSUInteger)modifiersForIndex:(NSUInteger)theIndex forKeyboard:(NSInteger)keyboardID;
- (BOOL)hasActionWithName:(NSString *)actionName;

	// States
@property (NS_NONATOMIC_IOSONLY, readonly) NSUInteger stateCount;

- (NSArray *)stateNamesExcept:(NSString *)stateToOmit;
- (NSArray *)stateNamesNotInSet:(NSSet *)statesToOmit;
- (BOOL)hasStateWithName:(NSString *)stateName;
- (NSString *)uniqueStateName;
- (void)createState:(NSString *)stateName withTerminator:(NSString *)terminator;
- (NSString *)terminatorForState:(NSString *)stateName;

	// Importing a dead key state
- (BOOL)hasEquivalentModifierMap:(UkeleleKeyboardObject *)otherKeyboard;
- (void)importDeadKeyState:(NSString *)sourceState toState:(NSString *)localState fromKeyboard:(UkeleleKeyboardObject *)sourceKeyboard;
- (void)undoImportDeadKeyState:(NSString *)importedState;
- (void)redoImportDeadKeyState:(NSString *)importedState data:(RemoveStateData *)removeStateData;

	// Swap keys
- (void)swapKeyCode:(NSInteger)keyCode1 withKeyCode:(NSInteger)keyCode2;

	// Cut, copy, paste keys
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasKeyOnPasteboard;

- (void)cutKeyCode:(NSInteger)keyCode;
- (void)undoCutKeyCode:(NSInteger)keyCode;
- (void)copyKeyCode:(NSInteger)keyCode;
- (void)pasteKeyCode:(NSInteger)keyCode;

	// Modifiers
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasSimplifiedModifiers;

- (void)changeModifiersIndex:(NSInteger)index
					subIndex:(NSInteger)subindex
					   shift:(NSInteger)newShift
					  option:(NSInteger)newOption
					capsLock:(NSInteger)newCapsLock
					 command:(NSInteger)newCommand
					 control:(NSInteger)newControl;
- (void)addModifierElement:(NSInteger)keyboardID
					 index:(NSInteger)index
				  subIndex:(NSInteger)subindex
					 shift:(NSInteger)shiftValue
				  capsLock:(NSInteger)capsLockValue
					option:(NSInteger)optionValue
				   command:(NSInteger)commandValue
				   control:(NSInteger)controlValue;
- (void)removeModifierElement:(NSInteger)keyboardID index:(NSInteger)index subindex:(NSInteger)subindex;
- (void)removeKeyMap:(NSInteger)index forKeyboard:(NSInteger)keyboardID newDefaultIndex:(NSInteger)newDefaultIndex;
- (void)replaceKeyMap:(NSInteger)index
		  forKeyboard:(NSInteger)keyboardID
		 defaultIndex:(NSInteger)defaultIndex
		 keyMapSelect:(void *)keyMapSelect
	   keyMapElements:(void *)deletedKeyMapElements;
- (void)addEmptyKeyMapForKeyboard:(NSInteger)keyboardID withModifiers:(ModifiersInfo *)modifierInfo;
- (void)addStandardKeyMap:(NSInteger)standardType
              forKeyboard:(NSInteger)keyboardID
            withModifiers:(ModifiersInfo *)modifierInfo;
- (void)addCopyKeyMap:(NSInteger)indexToCopy
               unlink:(BOOL)unlinkMap
          forKeyboard:(NSInteger)keyboardID
        withModifiers:(ModifiersInfo *)modifierInfo;
- (void)simplifyModifiers;
- (NSUInteger)modifierSetCountForKeyboard:(NSUInteger)keyboardID;
- (NSUInteger)modifierSetIndexForModifiers:(NSUInteger)modifiers forKeyboard:(NSUInteger)keyboardID;
- (void)moveModifierSetIndex:(NSInteger)sourceSet toIndex:(NSInteger)destinationSet forKeyboard:(NSUInteger)keyboardID;
- (BOOL)hasModifierSetWithIndex:(NSInteger)setIndex;

	// Comments
@property (NS_NONATOMIC_IOSONLY, readonly, strong) XMLCommentHolderObject *currentCommentHolder;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) XMLCommentHolderObject *documentCommentHolder;
@property (NS_NONATOMIC_IOSONLY, getter=isEditableComment, readonly) BOOL editableComment;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *firstComment;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *previousComment;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *nextComment;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *lastComment;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *currentComment;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSString *currentHolderText;

- (void)addComment:(NSString *)commentText
		  toHolder:(XMLCommentHolderObject *)commentHolder;
- (void)removeComment:(NSString *)commentText
		   fromHolder:(XMLCommentHolderObject *)commentHolder;
- (void)changeCommentText:(NSString *)oldText
					   to:(NSString *)newText
				forHolder:(XMLCommentHolderObject *)commentHolder;
- (XMLCommentHolderObject *)commentHolderForKey:(NSDictionary *)keyDataDict;
- (BOOL)isFirstComment;
- (BOOL)isLastComment;

- (void)addComment:(NSString *)commentText keyData:(NSDictionary *)keyDataDict;
- (void)removeComment:(NSString *)commentText keyData:(NSDictionary *)keyDataDict;

	// Housekeeping: Removing unused elements
- (RemoveStateData *)removeUnusedStates;
- (void)undoRemoveUnusedStates:(RemoveStateData *)removeStateData;
- (ActionElementSetWrapper *)removeUnusedActions;
- (void)undoRemoveUnusedActions:(ActionElementSetWrapper *)removedActions;

	// Housekeeping: Changing names
- (void)changeStateName:(NSString *)oldStateName toName:(NSString *)newStateName;
- (void)changeActionName:(NSString *)oldActionName toName:(NSString *)newActionName;

	// Housekeeping: Adding missing output
- (AddMissingOutputData *)addSpecialKeyOutput;
- (void)undoAddSpecialKeyOutput:(AddMissingOutputData *)addMissingOutputData;

@end

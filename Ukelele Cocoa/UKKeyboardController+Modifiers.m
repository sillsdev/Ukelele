//
//  UKKeyboardController+Modifiers.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 12/06/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import "UKKeyboardController+Modifiers.h"
#import "KeyboardDefinitions.h"
#import "UkeleleConstantStrings.h"
#import "KeyboardEnvironment.h"

@implementation UKKeyboardController (Modifiers)

#pragma mark === Modifiers tab ===

#pragma mark Setup

- (void)setupDefaultIndex:(UkeleleKeyboardObject *)keyboardObject
{
	if (self.defaultIndexButton == nil || keyboardObject == nil) {
			// The window hasn't been set up yet or no data
		return;
	}
	NSMenu *indexMenu = [self.defaultIndexButton menu];
	NSAssert(indexMenu, @"Index menu must exist");
	[indexMenu removeAllItems];
	NSArray *modifierIndices = [keyboardObject getModifierIndices];
	NSAssert(modifierIndices && [modifierIndices count] > 0, @"Must have modifier indices");
	for (NSNumber *theIndex in modifierIndices) {
		[indexMenu addItemWithTitle:[NSString stringWithFormat:@"%@", theIndex] action:nil keyEquivalent:@""];
	}
	NSUInteger defaultIndex = [keyboardObject getDefaultModifierIndex];
	[self.defaultIndexButton selectItemWithTitle:[NSString stringWithFormat:@"%d", (int)defaultIndex]];
}

- (void)setupDataSource
{
	if (self.modifiersDataSource == nil) {
			// Window hasn't been set up yet
		return;
	}
	[self.modifiersDataSource setKeyboard:self.keyboardLayout];
	if ([self.modifiersTableView dataSource] != self.modifiersDataSource) {
		[self.modifiersTableView setDataSource:self.modifiersDataSource];
	}
	else {
		[self.modifiersTableView reloadData];
	}
	[self setupDefaultIndex:self.keyboardLayout];
}

- (void)updateModifiers
{
	[self.modifiersDataSource updateKeyboard];
	[self.modifiersTableView reloadData];
	[self setupDefaultIndex:self.keyboardLayout];
    [self.simplifyModifiersButton setEnabled:![self.keyboardLayout hasSimplifiedModifiers]];
}

#pragma mark User actions

- (IBAction)doubleClickRow:(id)sender
{
#pragma unused(sender)
	NSInteger selectedRow = [self.modifiersTableView selectedRow];
    if (selectedRow < 0) {
        return;
    }
    ModifiersInfo *modifiersInfo = internalState[kStateModifiersInfo];
    if (modifiersInfo == nil) {
        modifiersInfo = [[ModifiersInfo alloc] init];
        internalState[kStateModifiersInfo] = modifiersInfo;
    }
	[modifiersInfo setShiftValue:[self.modifiersDataSource modifierValueForRow:selectedRow column:kLabelShift]];
	[modifiersInfo setCapsLockValue:[self.modifiersDataSource modifierValueForRow:selectedRow column:kLabelCapsLock]];
	[modifiersInfo setOptionValue:[self.modifiersDataSource modifierValueForRow:selectedRow column:kLabelOption]];
	[modifiersInfo setCommandValue:[self.modifiersDataSource modifierValueForRow:selectedRow column:kLabelCommand]];
	[modifiersInfo setControlValue:[self.modifiersDataSource modifierValueForRow:selectedRow column:kLabelControl]];
    if ([self.keyboardLayout hasSimplifiedModifiers]) {
        modifiersSheet = [ModifiersSheet simplifiedModifiersSheet:modifiersInfo];
        [modifiersSheet beginSimplifiedModifiersSheetWithCallback:^(ModifiersInfo *newModifiersInfo) {
			[self acceptEditModifiers:newModifiersInfo];
		}
															isNew:NO
												   canBeSameIndex:NO
														forWindow:self.window];
    }
    else {
        modifiersSheet = [ModifiersSheet modifiersSheet:modifiersInfo];
        [modifiersSheet beginModifiersSheetWithCallback:^(ModifiersInfo *newModifiersInfo) {
			[self acceptEditModifiers:newModifiersInfo];
		}
												  isNew:NO
										 canBeSameIndex:NO
											  forWindow:self.window];
    }
}

- (IBAction)setDefaultIndex:(id)sender
{
#pragma unused(sender)
	NSUInteger newIndex = [[[self.defaultIndexButton selectedItem] title] integerValue];
	if (newIndex != [self.keyboardLayout getDefaultModifierIndex]) {
		[self.keyboardLayout setDefaultModifierIndex:newIndex];
		[self.modifiersDataSource setKeyboard:self.keyboardLayout];
		[self.modifiersTableView reloadData];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
#pragma unused(notification)
	[self.removeModifiersButton setEnabled:([self.modifiersTableView selectedRow] >= 0)];
}

- (IBAction)addModifiers:(id)sender
{
#pragma unused(sender)
	NSInteger selectedRow = [self.modifiersTableView selectedRow];
    ModifiersInfo *modifiersInfo = internalState[kStateModifiersInfo];
    if (modifiersInfo == nil) {
        modifiersInfo = [[ModifiersInfo alloc] init];
        internalState[kStateModifiersInfo] = modifiersInfo;
    }
	if (selectedRow != -1) {
		[modifiersInfo setExistingOrNewValue:kModifiersSameIndex];
	}
	else {
		[modifiersInfo setExistingOrNewValue:kModifiersNewIndex];
	}
    if ([self.keyboardLayout hasSimplifiedModifiers]) {
        modifiersSheet = [ModifiersSheet simplifiedModifiersSheet:modifiersInfo];
        [modifiersSheet beginSimplifiedModifiersSheetWithCallback:^(ModifiersInfo *newModifiersInfo) {
			[self acceptNewModifiers:newModifiersInfo];
		}
															isNew:YES
												   canBeSameIndex:(selectedRow != -1)
														forWindow:self.window];
    }
    else {
        modifiersSheet = [ModifiersSheet modifiersSheet:modifiersInfo];
        [modifiersSheet beginModifiersSheetWithCallback:^(ModifiersInfo *newModifiersInfo) {
			[self acceptNewModifiers:newModifiersInfo];
		}
												  isNew:YES
										 canBeSameIndex:(selectedRow != -1)
											  forWindow:self.window];
    }
}

- (IBAction)removeModifiers:(id)sender
{
#pragma unused(sender)
	NSInteger selectedRow = [self.modifiersTableView selectedRow];
	NSAssert(selectedRow != -1, @"No selected row to delete");
	NSInteger selectedIndex = [self.modifiersDataSource indexForRow:selectedRow];
	NSInteger selectedSubindex = [self.modifiersDataSource subindexForRow:selectedRow];
	if ([self.keyboardLayout keyMapSelectHasOneModifierCombination:selectedIndex]) {
			// Deleting a whole map
		if (selectedIndex == (NSInteger)[self.keyboardLayout getDefaultModifierIndex]) {
				// Deleting the map with default index
			NSArray *modifierIndices = [self.keyboardLayout getModifierIndices];
			NSMutableArray *menuItems = [NSMutableArray arrayWithCapacity:[modifierIndices count]];
			for (NSNumber *modIndex in modifierIndices) {
				if ([modIndex integerValue] != selectedIndex) {
					[menuItems addObject:[NSString stringWithFormat:@"%@", modIndex]];
				}
			}
			NSString *dialogText =
            NSLocalizedStringFromTable(@"You are deleting the modifier set with the default index. Please select a new default index.",
                                       @"dialogs", @"Choose new default index");
            if (!askFromList) {
                askFromList = [AskFromList askFromList];
            }
			[askFromList beginAskFromListWithText:dialogText
                                         withMenu:menuItems
                                        forWindow:self.window
										 callBack:^(NSString *newDefault) {
											 if (newDefault == nil) {	// User cancelled
												 return;
											 }
											 NSUndoManager *undoManager = [self undoManager];
											 [undoManager beginUndoGrouping];
												 // Change the default index
											 NSInteger deleteIndex = [self.modifiersDataSource indexForRow:[self.modifiersTableView selectedRow]];
											 NSInteger defaultIndex = [newDefault integerValue];
											 if (deleteIndex < defaultIndex) {
												 defaultIndex--;
											 }
											 [self.keyboardLayout setDefaultModifierIndex:defaultIndex];
												 // Delete the row
											 [self.keyboardLayout removeKeyMap:deleteIndex
															   forKeyboard:[[KeyboardEnvironment instance] currentKeyboardID]
														   newDefaultIndex:defaultIndex];
											 [undoManager endUndoGrouping];
											 [self updateModifiers];
										 }];
		}
		else {
				// Delete the row
			NSInteger newDefaultIndex = [self.keyboardLayout getDefaultModifierIndex];
			if (newDefaultIndex > selectedIndex) {
				newDefaultIndex--;
			}
			[self.keyboardLayout removeKeyMap:selectedIndex
								  forKeyboard:[[KeyboardEnvironment instance] currentKeyboardID]
							  newDefaultIndex:newDefaultIndex];
			[self updateModifiers];
		}
	}
	else {
			// Do the deletion
		[self.keyboardLayout removeModifierElement:[[KeyboardEnvironment instance] currentKeyboardID]
											 index:selectedIndex
										  subindex:selectedSubindex];
        [self updateModifiers];
	}
}

- (IBAction)simplifyModifiers:(id)sender
{
#pragma unused(sender)
    [self.keyboardLayout simplifyModifiers];
}

- (IBAction)unlinkModifierSet:(id)sender
{
#pragma unused(sender)
	if ([kTabNameKeyboard isEqualToString:[[self.tabView selectedTabViewItem] identifier]]) {
			// We're on the keyboard tab, so invoke unlinking a set
		[self unlinkModifierCombination];
		return;
	}
	NSInteger selectedRow = [self.modifiersTableView selectedRow];
	NSAssert(selectedRow != -1, @"No selected row for unlinking");
	NSInteger selectedIndex = [self.modifiersDataSource indexForRow:selectedRow];
	NSInteger keyboardID = [internalState[kStateCurrentKeyboard] integerValue];
	NSUInteger modifiers = [self.keyboardLayout modifiersForIndex:selectedIndex forKeyboard:keyboardID];
	[self.keyboardLayout unlinkModifierSet:modifiers forKeyboard:keyboardID];
}

#pragma mark Callbacks

- (void)acceptEditModifiers:(ModifiersInfo *)newModifiersInfo
{
	if (newModifiersInfo == nil) {
			// User cancelled
		return;
	}
	if (![newModifiersInfo modifiersAreEqualTo:internalState[kStateModifiersInfo]]) {
			// New modifiers
        internalState[kStateModifiersInfo] = newModifiersInfo;
		NSInteger selectedRow = [self.modifiersTableView selectedRow];
		NSInteger index = [self.modifiersDataSource indexForRow:selectedRow];
        [newModifiersInfo setKeyMapIndex:index];
		NSInteger subindex = [self.modifiersDataSource subindexForRow:selectedRow];
        [newModifiersInfo setKeyMapSubindex:subindex];
		[self.keyboardLayout changeModifiersIndex:index
										 subIndex:subindex
											shift:[newModifiersInfo shiftValue]
										   option:[newModifiersInfo optionValue]
										 capsLock:[newModifiersInfo capsLockValue]
										  command:[newModifiersInfo commandValue]
										  control:[newModifiersInfo controlValue]];
	}
	[self updateModifiers];
}

- (void)acceptNewModifiers:(ModifiersInfo *)newModifiersInfo
{
	if (newModifiersInfo == nil) {
			// User cancelled
		return;
	}
	NSInteger selectedRow = [self.modifiersTableView selectedRow];
	BOOL newIndex = selectedRow == -1 || [newModifiersInfo existingOrNewValue] == kModifiersNewIndex;
	if (newIndex) {
			// Creating a new modifier map, so have to ask what type
        [newModifiersInfo setKeyMapIndex:-1];
        [newModifiersInfo setKeyMapSubindex:0];
        internalState[kStateModifiersInfo] = newModifiersInfo;
        if (!askNewKeyMap) {
            askNewKeyMap = [AskNewKeyMap askNewKeyMap];
        }
		NSString *infoString = NSLocalizedStringFromTable(@"Choose what kind of key map to create:", @"dialogs",
														  @"Ask user for key map type");
		NSArray *modifierIndices = [self.keyboardLayout getModifierIndices];
		NSMutableArray *keyMaps = [NSMutableArray arrayWithCapacity:[modifierIndices count]];
		for (NSNumber *theIndex in modifierIndices) {
			[keyMaps addObject:[NSString stringWithFormat:@"%@", theIndex]];
		}
		[askNewKeyMap beginNewKeyMapWithText:infoString
								 withKeyMaps:keyMaps
								   forWindow:self.window
									callBack:^(NewKeyMapInfo *mapTypeInfo) {
										[self acceptNewKeyMapType:mapTypeInfo];
									}];
		return;
	}
		// Adding to an existing modifier map
	NSInteger rowIndex = [self.modifiersDataSource indexForRow:selectedRow];
	NSInteger subindex = [self.modifiersDataSource subindexForRow:selectedRow];
	[self.keyboardLayout addModifierElement:[[KeyboardEnvironment instance] currentKeyboardID]
									  index:rowIndex
								   subIndex:subindex
									  shift:[newModifiersInfo shiftValue]
								   capsLock:[newModifiersInfo capsLockValue]
									 option:[newModifiersInfo optionValue]
									command:[newModifiersInfo commandValue]
									control:[newModifiersInfo controlValue]];
    internalState[kStateModifiersInfo] = newModifiersInfo;
	[self modifierMapDidChange];
}

- (void)acceptNewKeyMapType:(NewKeyMapInfo *)mapTypeInfo
{
	if (mapTypeInfo == nil) {
			// User cancelled
		return;
	}
	NSInteger keyMapType = [mapTypeInfo keyMapTypeSelection];
    NSNumber *keyboardID = internalState[kStateCurrentKeyboard];
    if (keyMapType == kNewKeyMapEmpty) {
			// Create an empty key map
        [self.keyboardLayout addEmptyKeyMapForKeyboard:[keyboardID integerValue]
										 withModifiers:internalState[kStateModifiersInfo]];
    }
    else if (keyMapType == kNewKeyMapStandard) {
			// Create a new key map of the specified standard type
        NSInteger standardType = [mapTypeInfo standardKeyMapSelection];
        switch (standardType) {
            case kStandardKeyMapqwerty:
                standardType = kStandardKeyMapQWERTYLowerCase;
                break;
                
            case kStandardKeyMapQWERTY:
                standardType = kStandardKeyMapQWERTYUpperCase;
                break;
                
            case kStandardKeyMapDvorackLower:
                standardType = kStandardKeyMapDvorakLowerCase;
                break;
                
            case kStandardKeyMapDvorackUpper:
                standardType = kStandardKeyMapDvorakUpperCase;
                break;
                
            case kStandardKeyMapazerty:
                standardType = kStandardKeyMapAZERTYLowerCase;
                break;
                
            case kStandardKeyMapAZERTY:
                standardType = kStandardKeyMapAZERTYUpperCase;
                break;
                
            case kStandardKeyMapqwertz:
                standardType = kStandardKeyMapQWERTZLowerCase;
                break;
                
            case kStandardKeyMapQWERTZ:
                standardType = kStandardKeyMapQWERTZUpperCase;
                break;
				
			case kStandardKeyMapColemakLower:
				standardType = kStandardKeyMapColemakLower;
				break;
				
			case kStandardKeyMapColemakUpper:
				standardType = kStandardKeyMapColemakUpper;
				break;
        }
        [self.keyboardLayout addStandardKeyMap:standardType
								   forKeyboard:[keyboardID integerValue]
								 withModifiers:internalState[kStateModifiersInfo]];
    }
    else if (keyMapType == kNewKeyMapCopy) {
			// Create a copy of the new key map
        NSInteger mapToCopyIndex = [mapTypeInfo copyKeyMapSelection];
        BOOL unlinkMap = [mapTypeInfo isUnlinked];
        [self.keyboardLayout addCopyKeyMap:mapToCopyIndex
									unlink:unlinkMap
							   forKeyboard:[keyboardID integerValue]
							 withModifiers:internalState[kStateModifiersInfo]];
    }
    else {
			// Some unknown value!
        NSLog(@"Received unknown map type %ld to create a new key map", (long)keyMapType);
        return;
    }
}

- (void)acceptReplacementDefaultIndex:(NSString *)newDefault
{
	if (newDefault == nil) {	// User cancelled
		return;
	}
	NSUndoManager *undoManager = [self undoManager];
	[undoManager beginUndoGrouping];
		// Change the default index
	NSInteger deleteIndex = [self.modifiersDataSource indexForRow:[self.modifiersTableView selectedRow]];
	NSInteger defaultIndex = [newDefault integerValue];
	if (deleteIndex < defaultIndex) {
		defaultIndex--;
	}
	[self.keyboardLayout setDefaultModifierIndex:defaultIndex];
		// Delete the row
	[self.keyboardLayout removeKeyMap:deleteIndex
					  forKeyboard:[[KeyboardEnvironment instance] currentKeyboardID]
				  newDefaultIndex:defaultIndex];
	[undoManager endUndoGrouping];
	[self updateModifiers];
}

- (void)modifierMapDidChangeImplementation
{
		// Delegate method to indicate that the modifier map has changed
    [self.modifiersDataSource updateKeyboard];
    [self.modifiersTableView reloadData];
    [self setupDefaultIndex:self.keyboardLayout];
    [self.simplifyModifiersButton setEnabled:![self.keyboardLayout hasSimplifiedModifiers]];
    [self updateWindow];
}

#pragma mark Action routines

- (void)setDefaultModifierIndex:(NSUInteger)defaultIndex
{
	[self.keyboardLayout setDefaultModifierIndex:defaultIndex];
	[self updateWindow];
    [self setupDataSource];
}

- (void)changeModifiersIndex:(NSInteger)index
					subIndex:(NSInteger)subindex
					   shift:(NSInteger)newShift
					  option:(NSInteger)newOption
					capsLock:(NSInteger)newCapsLock
					 command:(NSInteger)newCommand
					 control:(NSInteger)newControl
{
	[self.keyboardLayout changeModifiersIndex:index
									 subIndex:subindex
										shift:newShift
									   option:newOption
									 capsLock:newCapsLock
									  command:newCommand
									  control:newControl];
	[self updateWindow];
}

- (void)removeModifierElement:(NSInteger)keyboardID
						index:(NSInteger)index
					 subindex:(NSInteger)subindex
{
	[self.keyboardLayout removeModifierElement:keyboardID index:index subindex:subindex];
	[self updateWindow];
}

- (void)addModifierElement:(NSInteger)keyboardID
					 index:(NSInteger)index
				  subIndex:(NSInteger)subindex
					 shift:(NSInteger)newShift
				  capsLock:(NSInteger)newCapsLock
					option:(NSInteger)newOption
				   command:(NSInteger)newCommand
				   control:(NSInteger)newControl
{
	[self.keyboardLayout addModifierElement:keyboardID
									  index:index
								   subIndex:subindex
									  shift:newShift
								   capsLock:newCapsLock
									 option:newOption
									command:newCommand
									control:newControl];
	[self updateWindow];
}

- (void)removeKeyMap:(NSInteger)index forKeyboard:(NSInteger)keyboardID newDefaultIndex:(NSInteger)newDefaultIndex
{
	[self.keyboardLayout removeKeyMap:index forKeyboard:keyboardID newDefaultIndex:newDefaultIndex];
	[self updateWindow];
}

- (void)replaceKeyMap:(NSInteger)index
		  forKeyboard:(NSInteger)keyboardID
		 defaultIndex:(NSInteger)defaultIndex
		 keyMapSelect:(void *)keyMapSelect
	   keyMapElements:(void *)deletedKeyMapElements
{
	[self.keyboardLayout replaceKeyMap:index
						   forKeyboard:keyboardID
						  defaultIndex:defaultIndex
						  keyMapSelect:keyMapSelect
						keyMapElements:deletedKeyMapElements];
	[self updateWindow];
}

@end

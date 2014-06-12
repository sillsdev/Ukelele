//
//  UKKeyboardWindow+Housekeeping.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 12/06/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import "UKKeyboardWindow+Housekeeping.h"
#import "RemoveStateData.h"
#import "ActionElementSetWrapper.h"
#import "ScriptInfo.h"
#import "InspectorWindowController.h"
#import "ColourThemeEditorController.h"
#import "UkeleleConstantStrings.h"

@implementation UKKeyboardWindow (Housekeeping)

- (IBAction)removeUnusedStates:(id)sender
{
	RemoveStateData *removeStateData = [[self keyboardLayout] removeUnusedStates];
	if (nil == removeStateData) {
			// No states removed
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"No states removed"];
		[alert setInformativeText:@"All states are currently used, so there were no unused states to remove"];
		[alert addButtonWithTitle:@"OK"];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
		return;
	}
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] undoRemoveUnusedStates:removeStateData];
	[undoManager setActionName:@"Remove unused states"];
}

- (IBAction)removeUnusedActions:(id)sender
{
	ActionElementSetWrapper *removedActions = [[self keyboardLayout] removeUnusedActions];
	if (nil == removedActions) {
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"No actions removed"];
		[alert setInformativeText:@"All actions are currently used, so there were no unused actions to remove"];
		[alert addButtonWithTitle:@"OK"];
		[alert setAlertStyle:NSInformationalAlertStyle];
		[alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
		return;
		return;
	}
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] undoRemoveUnusedActions:removedActions];
	[undoManager setActionName:@"Remove unused actions"];
}

- (IBAction)changeStateName:(id)sender
{
	NSArray *stateNames = [[self keyboardLayout] stateNamesExcept:@"none"];
	NSString *infoText = @"Choose the state name to replace";
	if (nil == replaceNameSheet) {
		replaceNameSheet = [ReplaceNameSheet createReplaceNameSheet];
	}
	[replaceNameSheet beginReplaceNameSheetWithText:infoText
										  forWindow:self.window
										  withNames:stateNames
									 verifyCallBack:^BOOL(NSString *stateName) {
										 if ([stateName isEqualToString:@"none"] || [[self keyboardLayout] hasStateWithName:stateName]) {
												 // Can't have "none" or an existing state name
											 return NO;
										 }
										 return YES;
									 }
									 acceptCallBack:^(NSString *oldName, NSString *newName) {
										 [[self keyboardLayout] changeStateName:oldName toName:newName];
										 NSUndoManager *undoManager = [self undoManager];
										 [[undoManager prepareWithInvocationTarget:self] replaceStateName:newName withName:oldName];
										 [undoManager setActionName:@"Replace state name"];
									 }];
}

- (IBAction)changeActionName:(id)sender
{
	NSArray *actionNames = [[self keyboardLayout] actionNames];
	NSString *infoText = @"Choose the action name to replace";
	if (nil == replaceNameSheet) {
		replaceNameSheet = [ReplaceNameSheet createReplaceNameSheet];
	}
	[replaceNameSheet beginReplaceNameSheetWithText:infoText
										  forWindow:self.window
										  withNames:actionNames
									 verifyCallBack:^BOOL(NSString *actionName) {
										 if ([[self keyboardLayout] hasActionWithName:actionName]) {
											 return NO;
										 }
										 return YES;
									 }
									 acceptCallBack:^(NSString *oldActionName, NSString *newActionName) {
										 if (nil == oldActionName) {
											 return;
										 }
										 [self replaceActionName:oldActionName withName:newActionName];
									 }];
}

- (IBAction)addSpecialKeyOutput:(id)sender
{
	AddMissingOutputData *addMissingOutputData = [[self keyboardLayout] addSpecialKeyOutput];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] undoAddSpecialKeyOutput:addMissingOutputData];
	[undoManager setActionName:@"Add special key output"];
}

- (IBAction)askKeyboardIdentifiers:(id)sender
{
	NSInteger keyboardScript = [[self keyboardLayout] keyboardGroup];
	NSUInteger scriptIndex = [ScriptInfo indexForScript:keyboardScript];
	NSLog(@"Script %ld, index %ld", keyboardScript, scriptIndex);
	if (nil == keyboardIDSheet) {
		keyboardIDSheet = [ChooseKeyboardIDWindowController chooseKeyboardID];
	}
	NSMutableDictionary *infoDictionary = [NSMutableDictionary dictionaryWithCapacity:6];
	infoDictionary[kKeyboardIDWindowScript] = @(scriptIndex);
	infoDictionary[kKeyboardIDWindowName] = [[self keyboardLayout] keyboardName];
	infoDictionary[kKeyboardIDWindowID] = @([[self keyboardLayout] keyboardID]);
		// Need to set the bundle parameters!
	[keyboardIDSheet startDialogWithInfo:infoDictionary
							   forWindow:self.window
								callBack:^(NSDictionary *infoDictionary) {
									if (infoDictionary == nil) {
											// User cancelled
										return;
									}
									NSString *existingName = [[self keyboardLayout] keyboardName];
									NSString *newName = infoDictionary[kKeyboardIDWindowName];
									if (![existingName isEqualToString:newName]) {
											// New keyboard layout name
										[self changeKeyboardName:newName];
									}
									NSInteger scriptIndex = [infoDictionary[kKeyboardIDWindowScript] integerValue];
									NSArray *scriptArray = [ScriptInfo standardScripts];
									ScriptInfo *selectedInfo = scriptArray[scriptIndex];
									NSInteger scriptID = [selectedInfo scriptID];
									NSInteger existingScript = [[self keyboardLayout] keyboardGroup];
									if (scriptID != existingScript) {
											// New script code
										[self changeKeyboardScript:scriptID];
									}
									NSInteger keyboardID = [infoDictionary[kKeyboardIDWindowID] integerValue];
									NSInteger oldID = [[self keyboardLayout] keyboardID];
									if (keyboardID != oldID) {
											// New keyboard ID
										[self changeKeyboardID:keyboardID];
									}
								}];
}

- (IBAction)colourThemes:(id)sender {
	__block ColourThemeEditorController *theController = [ColourThemeEditorController colourThemeEditorController];
	[theController showColourThemesWithWindow:self.window completionBlock:^(NSString *theTheme) {
		if (theTheme) {
				// Set the current theme
			NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
			[theDefaults setObject:theTheme forKey:UKColourTheme];
		}
		theController = nil;
	}];
}

#pragma mark Action routines

- (void)undoRemoveUnusedStates:(RemoveStateData *)removeStateData
{
	[[self keyboardLayout] undoRemoveUnusedStates:removeStateData];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeUnusedStates:self];
	[undoManager setActionName:@"Remove unused states"];
}

- (void)undoRemoveUnusedActions:(ActionElementSetWrapper *)removedActions
{
	[[self keyboardLayout] undoRemoveUnusedActions:removedActions];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeUnusedActions:self];
	[undoManager setActionName:@"Remove unused actions"];
}

- (void)replaceStateName:(NSString *)oldName withName:(NSString *)newName
{
	[[self keyboardLayout] changeStateName:oldName toName:newName];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] replaceStateName:newName withName:oldName];
	[undoManager setActionName:@"Replace state name"];
}

- (void)replaceActionName:(NSString *)oldName withName:(NSString *)newName
{
	[[self keyboardLayout] changeActionName:oldName toName:newName];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] replaceActionName:newName withName:oldName];
	[undoManager setActionName:@"Replace action name"];
}

- (void)undoAddSpecialKeyOutput:(AddMissingOutputData *)addOutputData
{
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] addSpecialKeyOutput:self];
	[undoManager setActionName:@"Add special key output"];
}

- (void)changeKeyboardID:(NSInteger)newID
{
	NSInteger oldID = [[self keyboardLayout] keyboardID];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] setKeyboardID:oldID];
	[undoManager setActionName:@"Set keyboard ID"];
	[[self keyboardLayout] setKeyboardID:newID];
}

- (void)changeKeyboardScript:(NSInteger)newScriptCode
{
	NSInteger newID = [ScriptInfo randomIDforScript:newScriptCode];
	[self setKeyboardID:newID];
	NSInteger oldScriptCode = [[self keyboardLayout] keyboardGroup];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] setKeyboardScript:oldScriptCode];
	[undoManager setActionName:@"Set keyboard script"];
	[[self keyboardLayout] setKeyboardGroup:newScriptCode];
}

- (void)changeKeyboardName:(NSString *)newName
{
	NSString *oldName = [[self keyboardLayout] keyboardName];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] changeKeyboardName:oldName];
	[undoManager setActionName:@"Set keyboard name"];
	[[self keyboardLayout] setKeyboardName:newName];
//	[[self parentBundle] notifyNewName:newName forDocument:self];
	[self.window setTitle:newName];
}

#pragma mark Callbacks

- (BOOL)verifyStateName:(NSString *)stateName
{
	if (/*![UkeleleDocument isValidStateName:stateName] ||*/ [[self keyboardLayout] hasStateWithName:stateName]) {
			// Can't have "none" or an existing state name
		return NO;
	}
	return YES;
}

- (void)acceptReplaceState:(NSString *)oldStateName withName:(NSString *)newStateName
{
	if (nil == oldStateName) {
		return;
	}
	[self replaceStateName:oldStateName withName:newStateName];
}

- (BOOL)verifyActionName:(NSString *)actionName
{
	if ([[self keyboardLayout] hasActionWithName:actionName]) {
		return NO;
	}
	return YES;
}

- (void)acceptReplaceAction:(NSString *)oldActionName withName:(NSString *)newActionName
{
	if (nil == oldActionName) {
		return;
	}
	[self replaceActionName:oldActionName withName:newActionName];
}

- (void)handleSetKeyboardID:(NSDictionary *)infoDictionary
{
	if (infoDictionary == nil) {
			// User cancelled
		return;
	}
	NSString *existingName = [[self keyboardLayout] keyboardName];
	NSString *newName = infoDictionary[kKeyboardIDWindowName];
	if (![existingName isEqualToString:newName]) {
			// New keyboard layout name
		[self changeKeyboardName:newName];
	}
	NSInteger scriptIndex = [infoDictionary[kKeyboardIDWindowScript] integerValue];
	NSArray *scriptArray = [ScriptInfo standardScripts];
	ScriptInfo *selectedInfo = scriptArray[scriptIndex];
	NSInteger scriptID = [selectedInfo scriptID];
	NSInteger existingScript = [[self keyboardLayout] keyboardGroup];
	if (scriptID != existingScript) {
			// New script code
		[self changeKeyboardScript:scriptID];
	}
	NSInteger keyboardID = [infoDictionary[kKeyboardIDWindowID] integerValue];
	NSInteger oldID = [[self keyboardLayout] keyboardID];
	if (keyboardID != oldID) {
			// New keyboard ID
		[self changeKeyboardID:keyboardID];
	}
		// Check the bundle parameters
}

#pragma mark Parameter checking

+ (BOOL)isValidStateName:(NSString *)stateName {
	static NSSet *reservedNames = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		reservedNames = [NSSet setWithObjects:@"none", @"0", nil];
	});
	return ![reservedNames containsObject:stateName];
}

@end

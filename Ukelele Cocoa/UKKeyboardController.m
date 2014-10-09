//
//  UKKeyboardController.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 11/06/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import "UKKeyboardController.h"
#import "UKKeyboardController+Comments.h"
#import "UKKeyboardController+Housekeeping.h"
#import "UKKeyboardController+Modifiers.h"
#import "UkeleleConstants.h"
#import "UkeleleConstantStrings.h"
#import "ViewScale.h"
#import "UkeleleView.h"
#import "KeyboardEnvironment.h"
#import "InspectorWindowController.h"
#import "CreateDeadKeyHandler.h"
#import "CreateDeadKeySheet.h"
#import "UnlinkKeyHandler.h"
#import "UnlinkModifierSetHandler.h"
#import "SwapKeysController.h"
#import "ImportDeadKeyHandler.h"
#import "AskTextSheet.h"
#import "AskStateAndTerminatorController.h"
#import "EditKeyWindowController.h"
#import "ToolboxData.h"
#import "SelectKeyByCodeController.h"
#import "KeyboardPrintView.h"
#import "GetKeyCodeHandler.h"
#import "DoubleClickHandler.h"
#import "AskCommentController.h"
#import "LayoutInfo.h"
#import "DragTextHandler.h"
#import "UKKeyboardDocument.h"
#include <Carbon/Carbon.h>

const float kWindowMinWidth = 450.0f;
const float kWindowMinHeight = 300.0f;
const float kScalePercentageFactor = 100.0f;

@interface UKKeyboardController ()

@end

@implementation UKKeyboardController

@synthesize keyboardLayout = _keyboardLayout;

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
		NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
		internalState = [NSMutableDictionary dictionaryWithCapacity:20];
		internalState[kStateCurrentState] = kStateNameNone;
		stateStack = [NSMutableArray array];
		[stateStack addObject:kStateNameNone];
		scalesList = [ViewScale standardScales];
		internalState[kStateCurrentScale] = @([theDefaults floatForKey:UKScaleFactor]);
		internalState[kStateCurrentModifiers] = @0U;
		SInt32 keyboardType;
		OSStatus err = Gestalt(gestaltKeyboardType, &keyboardType);
		if (err != noErr || [theDefaults boolForKey:UKAlwaysUsesDefaultLayout]) {
			keyboardType = (SInt32)[theDefaults integerForKey:UKDefaultLayoutID];
		}
		internalState[kStateCurrentKeyboard] = @(keyboardType);
		interactionHandler = nil;
		modifiersSheet = nil;
		askFromList = nil;
		askNewKeyMap = nil;
		chooseScale = nil;
		keyboardTypeSheet = nil;
		documentAlert = nil;
		deadKeyData = nil;
		replaceNameSheet = nil;
		_iconFile = nil;
		selectedKey = kNoKeyCode;
		commentChanged = NO;
		_undoManager = nil;
    }
    return self;
}

- (void)awakeFromNib
{
    [self.modifiersTableView registerForDraggedTypes:@[ModifiersTableDragType]];
	[self.modifiersTableView setVerticalMotionCanBeginDrag:YES];
}

- (void)windowDidLoad {
	SInt32 keyboardType;
	OSStatus err = Gestalt(gestaltKeyboardType, &keyboardType);
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
	if (err != noErr || [theDefaults boolForKey:UKAlwaysUsesDefaultLayout]) {
		keyboardType = (SInt32)[theDefaults integerForKey:UKDefaultLayoutID];
	}
    internalState[kStateCurrentKeyboard] = @(keyboardType);
    [self.tabView selectTabViewItemWithIdentifier:kTabNameKeyboard];
	UkeleleView *ukeleleView = [[UkeleleView alloc] init];
    NSNumber *scaleValue = internalState[kStateCurrentScale];
	[ukeleleView createViewWithKeyboardID:(int)keyboardType withScale:[scaleValue doubleValue]];
	[ukeleleView setMenuDelegate:self];
	[self.keyboardView setDocumentView:ukeleleView];
	[self assignClickTargets];
    [self setupDataSource];
	[self calculateSize];
	[self updateWindow];
	[self setViewScaleComboBox];
	[self.window makeFirstResponder:self.keyboardView];
}

#pragma mark Accessors

- (NSUInteger)currentModifiers {
	return [internalState[kStateCurrentModifiers] unsignedIntegerValue];
}

- (void)setCurrentModifiers:(NSUInteger)currentModifiers {
	internalState[kStateCurrentModifiers] = @(currentModifiers);
}

- (NSString *)currentState {
	return internalState[kStateCurrentState];
}

- (void)setCurrentState:(NSString *)currentState {
	internalState[kStateCurrentState] = currentState;
}

- (NSInteger)keyboardID {
	return [self.keyboardLayout keyboardID];
}

- (void)setKeyboardID:(NSInteger)keyboardID {
	[self changeKeyboardID:keyboardID];
}

- (NSInteger)keyboardScript {
	return [self.keyboardLayout keyboardGroup];
}

- (void)setKeyboardScript:(NSInteger)keyboardScript {
	[self changeKeyboardScript:keyboardScript];
}

- (NSString *)keyboardName {
	return [self.keyboardLayout keyboardName];
}

- (void)setKeyboardName:(NSString *)keyboardName {
	[self changeKeyboardName:keyboardName];
}

- (NSString *)keyboardDisplayName {
	NSString *theKeyboardName = [self.keyboardLayout keyboardName];
	if (nil == theKeyboardName || [theKeyboardName isEqualToString:@""]) {
		theKeyboardName = [self.window title];
	}
	return theKeyboardName;
}

- (NSRect)keyRect:(NSInteger)keyCode
{
	UkeleleView *ukeleleView = [self.keyboardView documentView];
	KeyCapView *keyCap = [ukeleleView findKeyWithCode:(int)keyCode];
	return [keyCap frame];
}

- (CGFloat)currentScale {
    NSNumber *currentScaleValue = internalState[kStateCurrentScale];
	return [currentScaleValue floatValue];
}

- (NSUInteger)currentKeyboard {
    NSNumber *keyboardID = internalState[kStateCurrentKeyboard];
	return [keyboardID unsignedIntegerValue];
}

- (UkeleleKeyboardObject *)keyboardLayout {
	return _keyboardLayout;
}

- (void)setKeyboardLayout:(UkeleleKeyboardObject *)keyboardLayout {
	_keyboardLayout = keyboardLayout;
	NSDocument *theDocument = (NSDocument *)[self parentDocument];
	if (theDocument) {
		[self.keyboardLayout setParentDocument:theDocument];
	}
	[self.keyboardLayout setDelegate:self];
	[self.modifiersDataSource setKeyboard:keyboardLayout];
	[self setupDataSource];
}

#pragma mark Window sizing

- (NSSize)getIdealContentSize
{
	NSScrollView *scrollView = self.keyboardView;
	UkeleleView *ukeleleView = [scrollView documentView];
    NSSize contentSize = [[self.window contentView] bounds].size;
    NSSize viewSize = [scrollView contentSize];
    CGFloat verticalPadding = contentSize.height - viewSize.height;
    CGFloat horizontalPadding = contentSize.width - viewSize.width;
	NSSize keyboardSize = [ukeleleView bounds].size;
    keyboardSize = [NSScrollView frameSizeForContentSize:keyboardSize
                                 horizontalScrollerClass:[NSScroller class]
                                   verticalScrollerClass:[NSScroller class]
                                              borderType:NSLineBorder
                                             controlSize:NSRegularControlSize
                                           scrollerStyle:NSScrollerStyleOverlay];
    keyboardSize.height += 1;
    keyboardSize.width += 1;
	NSSize maximumSize = keyboardSize;
    maximumSize.height += verticalPadding;
    maximumSize.width += horizontalPadding;
	return maximumSize;
}

- (void)calculateSize
{
	NSSize maximumSize = [self getIdealContentSize];
	NSSize minimumSize = NSMakeSize(kWindowMinWidth, kWindowMinHeight);
	[self.window setContentMaxSize:maximumSize];
	[self.window setContentMinSize:minimumSize];
    NSDisableScreenUpdates();
	[self.window setContentSize:maximumSize];
	NSRect winBounds = [self.window frame];
	NSRect availableRect = [[NSScreen mainScreen] visibleFrame];
	if (!NSContainsRect(availableRect, winBounds)) {
			// Doesn't fit!
		availableRect = NSInsetRect(availableRect, 2, 2);
		NSRect newBounds;
			// If the width is too big to fit in the available rectangle
		if (winBounds.size.width > availableRect.size.width) {
				// Set the width to available and the origin to the available
			newBounds.size.width = availableRect.size.width;
			newBounds.origin.x = availableRect.origin.x;
		}
		else {
				// Width is OK
			newBounds.size.width = winBounds.size.width;
				// If the window is too far to the right
			if (winBounds.origin.x + winBounds.size.width > availableRect.origin.x + availableRect.size.width) {
					// Shift the origin to the left
				newBounds.origin.x = availableRect.origin.x + availableRect.size.width - winBounds.size.width;
			}
				// Else if the window is too far to the left
            else if (winBounds.origin.x < availableRect.origin.x) {
					// Shift the origin to the available rectangle
                newBounds.origin.x = availableRect.origin.x;
            }
			else {
					// Origin.x is OK
				newBounds.origin.x = winBounds.origin.x;
			}
		}
			// If the height is too big to fit
		if (winBounds.size.height > availableRect.size.height) {
				// Set the height to the available height, and the origin to the available
			newBounds.size.height = availableRect.size.height;
			newBounds.origin.y = availableRect.origin.y;
		}
		else {
				// Height is OK
			newBounds.size.height = winBounds.size.height;
				// If the window is too high
			if (winBounds.origin.y + winBounds.size.height > availableRect.origin.y + availableRect.size.height) {
					// Shift the origin down
				newBounds.origin.y = availableRect.origin.y + availableRect.size.height - winBounds.size.height;
			}
				// Else if the window is too low
            else if (winBounds.origin.y < availableRect.origin.y) {
					// Shift the origin up
                newBounds.origin.y = availableRect.origin.y + availableRect.size.height - winBounds.size.height;
            }
			else {
					// Origin.y is OK
				newBounds.origin.y = winBounds.origin.y;
			}
		}
		[self.window setFrame:newBounds display:YES];
	}
    NSEnableScreenUpdates();
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame
{
	NSToolbar *theToolbar = [window toolbar];
	float toolbarHeight = 0.0;
	if ([theToolbar isVisible]) {
		NSRect windowFrame = [NSWindow contentRectForFrameRect:[window frame] styleMask:[window styleMask]];
		toolbarHeight = NSHeight(windowFrame) - NSHeight([[window contentView] frame]);
	}
	NSRect contentRect = [window contentRectForFrameRect:[window frame]];
	contentRect.size = [self getIdealContentSize];
	contentRect.size.height += toolbarHeight;
	NSRect frameRect = [NSWindow frameRectForContentRect:contentRect styleMask:[window styleMask]];
	if (!NSContainsRect(newFrame, frameRect)) {
			// Not inside, but will it fit there?
		if (frameRect.size.height > newFrame.size.height || frameRect.size.width > newFrame.size.width) {
			frameRect.size.height = fminf(frameRect.size.height, newFrame.size.height);
			frameRect.size.width = fminf(frameRect.size.width, newFrame.size.width);
		}
		NSRect windowFrame = [window frame];
		frameRect.origin = windowFrame.origin;
		frameRect.origin.y += NSHeight(windowFrame) - NSHeight(frameRect);
	}
	return frameRect;
}

#pragma mark Window updating

- (void)setViewScaleComboBox
{
    NSNumber *scaleFactor = internalState[kStateCurrentScale];
	NSString *scaleString = [NSString stringWithFormat:@"%.0f%%", [scaleFactor doubleValue] * kScalePercentageFactor];
	[self.scaleComboBox setStringValue:scaleString];
}

- (CGFloat)fitWidthScale
{
		// First get the base width of the view
	UkeleleView *ukeleleView = [self.keyboardView documentView];
	CGFloat baseViewWidth = [ukeleleView baseFrame].size.width;
		// Now work out how much space would be available in a full width window
	NSRect winBounds = [self.window frame];
	CGFloat horizontalPadding = winBounds.size.width - [self.keyboardView frame].size.width;
	NSRect availableRect = NSInsetRect([[NSScreen mainScreen] visibleFrame], 2, 2);
		// The scale we want is then the ratio of the size for the widest view to the base view width
	CGFloat widthFactor = (availableRect.size.width - horizontalPadding) / baseViewWidth;
	return widthFactor;
}

- (void)updateWindow
{
	UkeleleView *ukeleleView = [self.keyboardView documentView];
	NSArray *subViews = [ukeleleView keyCapViews];
    NSNumber *modifiersValue = internalState[kStateCurrentModifiers];
    unsigned int theModifiers = [modifiersValue unsignedIntValue];
    NSMutableDictionary *keyDataDict = [NSMutableDictionary dictionary];
    keyDataDict[kKeyKeyboardID] = internalState[kStateCurrentKeyboard];
    keyDataDict[kKeyKeyCode] = @0;
    keyDataDict[kKeyModifiers] = modifiersValue;
    keyDataDict[kKeyState] = internalState[kStateCurrentState];
	for (KeyCapView *keyCapView in subViews) {
		NSInteger keyCode = [keyCapView keyCode];
		if (theModifiers & NSNumericPadKeyMask) {
			keyCode = [keyCapView fnKeyCode];
		}
		NSString *output;
		BOOL deadKey;
		NSString *nextState;
        keyDataDict[kKeyKeyCode] = @(keyCode);
		output = [self.keyboardLayout getCharOutput:keyDataDict isDead:&deadKey nextState:&nextState];
		[keyCapView setOutputString:output];
		[keyCapView setDeadKey:deadKey];
	}
	[ukeleleView updateModifiers:theModifiers];
	NSString *keyboardName = [[self keyboardLayout] keyboardName];
	if (keyboardName) {
		[self.window setTitle:keyboardName];
	}
	[ukeleleView setNeedsDisplay:YES];
}

- (void)changeViewScale:(double)newScale
{
    UkeleleView *ukeleleView = [self.keyboardView documentView];
    internalState[kStateCurrentScale] = @(newScale);
	[ukeleleView scaleViewToScale:newScale limited:YES];
    [self calculateSize];
    [self setViewScaleComboBox];
    [self updateWindow];
}

- (void)changeKeyboardType:(NSInteger)newKeyboardType
{
	NSScrollView *scrollView = self.keyboardView;
	UkeleleView *ukeleleView = [scrollView documentView];
	internalState[kStateCurrentKeyboard] = @(newKeyboardType);
	NSNumber *scaleValue = internalState[kStateCurrentScale];
	[ukeleleView createViewWithKeyboardID:(int)newKeyboardType withScale:[scaleValue doubleValue]];
	[ukeleleView setMenuDelegate:self];
	[self assignClickTargets];
    [self calculateSize];
    [self setViewScaleComboBox];
    [self updateWindow];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSAssert(documentAlert != nil, @"Ending an alert when there is none");
	documentAlert = nil;
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    NSNumber *keyboardID = internalState[kStateCurrentKeyboard];
    NSNumber *modifierValue = internalState[kStateCurrentModifiers];
	[KeyboardEnvironment updateKeyboard:[keyboardID integerValue]
						stickyModifiers:NO
							  modifiers:[modifierValue unsignedIntegerValue]
								  state:internalState[kStateCurrentState]];
		// Tell the font panel what font we have
	UkeleleView *ukeleleView = [self.keyboardView documentView];
	NSDictionary *largeAttributes = [ukeleleView largeAttributes];
	NSFont *largeFont = largeAttributes[NSFontAttributeName];
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	[fontManager setSelectedFont:largeFont isMultiple:NO];
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	[self inspectorDidActivateTab:[[[infoInspector tabView] selectedTabViewItem] identifier]];
	[infoInspector setCurrentWindow:self];
	[infoInspector setCurrentKeyboard:self.keyboardLayout];
}

- (void)windowDidResignMain:(NSNotification *)notification {
	InspectorWindowController *inspectorController = [InspectorWindowController getInstance];
	[inspectorController setCurrentWindow:nil];
	[inspectorController setCurrentKeyboard:nil];
}

- (void)windowWillClose:(NSNotification *)notification {
	if (commentChanged) {
			// Unsaved comment
		[self saveUnsavedComment];
	}
}

- (void)interactionDidComplete:(id<UKInteractionHandler>)handler
{
    NSAssert(handler == interactionHandler, @"Wrong interaction handler");
    interactionHandler = nil;
}

#pragma mark Setup

- (void)assignClickTargets {
	UkeleleView *ukeleleView = [self.keyboardView documentView];
	for (KeyCapView *subView in [ukeleleView keyCapViews]) {
		[subView setClickDelegate:self];
	}
}

#pragma mark Tab handling

- (void)tabView:(NSTabView *)theTabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	if ([kTabNameComments isEqualToString:[[theTabView selectedTabViewItem] identifier]]) {
			// We are about to leave the comment tab
		if (commentChanged) {
				// Unsaved comment
			[self saveUnsavedComment];
		}
	}
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if ([kTabNameKeyboard isEqualTo:[tabViewItem identifier]]) {
			// Activating the keyboard tab
        [self setMessageBarText:@""];
		[self setViewScaleComboBox];
		[self.window makeFirstResponder:self.keyboardView];
    }
    else if ([kTabNameModifiers isEqualTo:[tabViewItem identifier]]) {
			// Activating the modifiers tab
        [self.modifiersTableView setDoubleAction:@selector(doubleClickRow:)];
        [self.modifiersTableView setTarget:self];
        [self updateModifiers];
        [self.removeModifiersButton setEnabled:([self.modifiersTableView selectedRow] >= 0)];
        [self.simplifyModifiersButton setEnabled:![self.keyboardLayout hasSimplifiedModifiers]];
    }
    else if ([kTabNameComments isEqualTo:[tabViewItem identifier]]) {
			// Activating the comments tab
		[self updateCommentFields];
    }
}

- (BOOL)setsStatusForSelector:(SEL)selector {
	if (selector == @selector(setKeyboardType:) ||
		selector == @selector(createDeadKeyState:) ||
		selector == @selector(swapKeys:) ||
		selector == @selector(swapKeysByCode:) ||
		selector == @selector(addSpecialKeyOutput:) ||
		selector == @selector(unlinkKeyAskingKeyCode:) ||
		selector == @selector(unlinkModifierSet:) ||
		selector == @selector(importDeadKey:) ||
		selector == @selector(editKey:) ||
		selector == @selector(selectKeyByCode:) ||
		selector == @selector(cutKey:) ||
		selector == @selector(copyKey:) ||
		selector == @selector(attachComment:) ||
		selector == @selector(enterDeadKeyState:) ||
		selector == @selector(changeStateName:) ||
		selector == @selector(changeTerminator:) ||
		selector == @selector(leaveDeadKeyState:) ||
		selector == @selector(unlinkKey:) ||
		selector == @selector(pasteKey:)) {
		return YES;
	}
	return NO;
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
	SEL action = [anItem action];
	NSString *currentTabName = [[self.tabView selectedTabViewItem] identifier];
	if (action == @selector(createDeadKeyState:) || action == @selector(swapKeys:) ||
		action == @selector(swapKeysByCode:) || action == @selector(addSpecialKeyOutput:) ||
		action == @selector(unlinkKeyAskingKeyCode:) || action == @selector(unlinkModifierSet:) ||
		action == @selector(importDeadKey:) || action == @selector(editKey:) ||
		action == @selector(selectKeyByCode:) || action == @selector(cutKey:) ||
		action == @selector(copyKey:) || action == @selector(setKeyboardType:)) {
			// All of these can only be selected if we are on the keyboard tab and
			// there is no interaction in progress
		return (interactionHandler == nil) && [kTabNameKeyboard isEqualToString:currentTabName];
	}
	else if (action == @selector(askKeyboardIdentifiers:) ||
			 action == @selector(installForAllUsers:) ||
			 action == @selector(installForCurrentUser:)) {
			// These can only be selected if there is no interaction in progress
		return (interactionHandler == nil);
	}
	else if (action == @selector(attachComment:)) {
			// These can only be selected if there is no interaction in progress, we are on the
			/// keyboard tab, and a key is selected
		return (interactionHandler == nil) && [kTabNameKeyboard isEqualToString:currentTabName] && (selectedKey != kNoKeyCode);
	}
	else if (action == @selector(enterDeadKeyState:) || action == @selector(changeTerminator:)) {
			// These can only be selected if there are any states other than "none",
			// there is no interaction in progress, and we are on the keyboard tab
		NSUInteger stateCount = [self.keyboardLayout stateCount];
		return (interactionHandler == nil) && [kTabNameKeyboard isEqualToString:currentTabName] && ([stateStack count] > 1 ? stateCount > 1 : stateCount > 0);
	}
	else if (action == @selector(changeStateName:) || action == @selector(removeUnusedStates:)) {
			// These can only be selected if there is no interaction in progress and
			// there are states other than "none"
		NSUInteger stateCount = [self.keyboardLayout stateCount];
		return (interactionHandler == nil) && ([stateStack count] > 1 ? stateCount > 1 : stateCount > 0);
	}
	else if (action == @selector(changeActionName:) || action == @selector(removeUnusedActions:)) {
			// These can only be selected if there are any actions
		NSArray *actionNames = [[self keyboardLayout] actionNames];
		return [actionNames count] > 0;
	}
	else if (action == @selector(leaveDeadKeyState:)) {
			// These can only selected if we are in a dead key state,
			// we are on the keyboard tab, and no interaction is in progress
		return (interactionHandler == nil) && [kTabNameKeyboard isEqualToString:currentTabName] && [stateStack count] > 1;
	}
	else if (action == @selector(unlinkKey:)) {
			// This can come up either on the keyboard or modifiers tab
		if ([kTabNameKeyboard isEqualToString:currentTabName]) {
			return interactionHandler == nil;
		}
		else if ([kTabNameModifiers isEqualToString:currentTabName]) {
			return (interactionHandler == nil) && ([self.modifiersTableView selectedRow] >= 0);
		}
		else {
			return NO;
		}
	}
	else if (action == @selector(pasteKey:)) {
			// This can only be selected if there is a key to paste, and no interation is in progress
		return (interactionHandler == nil) && [self.keyboardLayout hasKeyOnPasteboard];
	}
	return NO;
}

#pragma === Inspector ===

- (void)inspectorDidActivateTab:(NSString *)tabIdentifier {
	InspectorWindowController *inspectorController = [InspectorWindowController getInstance];
	[inspectorController setCurrentKeyboard:self.keyboardLayout];
	if ([tabIdentifier isEqualToString:kTabIdentifierDocument]) {
			// Activating the document tab
		[inspectorController setKeyboardSectionEnabled:YES];
	}
	else if ([tabIdentifier isEqualToString:kTabIdentifierOutput]) {
			// Activating the output tab
	}
	else if ([tabIdentifier isEqualToString:kTabIdentifierState]) {
			// Activating the state tab
		[self inspectorSetModifiers];
		[self inspectorSetModifierMatch];
		[inspectorController setStateStack:stateStack];
	}
}

- (void)inspectorSetModifiers {
	NSInteger currentModifiers = [internalState[kStateCurrentModifiers] integerValue];
	NSMutableString *modifierString = [NSMutableString string];
	if (currentModifiers & NSAlphaShiftKeyMask) {
		[modifierString appendFormat:@"%C", (unichar)kCapsLockUnicode];
	}
	if (currentModifiers & NSCommandKeyMask) {
		[modifierString appendFormat:@"%C", (unichar)kCommandUnicode];
	}
	if (currentModifiers & NSShiftKeyMask) {
		[modifierString appendFormat:@"%C", (unichar)kShiftUnicode];
	}
	if (currentModifiers & NSControlKeyMask) {
		[modifierString appendFormat:@"%C", (unichar)kControlUnicode];
	}
	if (currentModifiers & NSAlternateKeyMask) {
		[modifierString appendFormat:@"%C", (unichar)kOptionUnicode];
	}
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	[[infoInspector modifiersField] setStringValue:modifierString];
}

- (void)inspectorSetModifierMatch {
	NSInteger currentModifiers = [internalState[kStateCurrentModifiers] integerValue];
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	NSUInteger matchingSet = [_keyboardLayout modifierSetIndexForModifiers:currentModifiers forKeyboard:[internalState[kStateCurrentKeyboard] unsignedIntegerValue]];
	[[infoInspector modifierMatchField] setStringValue:[NSString stringWithFormat:@"%lu", matchingSet]];
}

#pragma mark === Keyboard tab ===

- (IBAction)setScaleValue:(id)sender
{
	float scaleValue;
    NSInteger selItem = [sender indexOfSelectedItem];
	ViewScale *selectedObject = scalesList[selItem];
	scaleValue = [selectedObject scaleValue];
    NSNumber *currentScaleValue = internalState[kStateCurrentScale];
    double currentScale = [currentScaleValue doubleValue];
    if (scaleValue < 0) {
			// This is fit width
        [self changeViewScale:[self fitWidthScale]];
    }
    else if (scaleValue == 0) {
			// This is "other"
        chooseScale = [ChooseScale makeChooseScale];
        [chooseScale beginChooseScale:currentScale * kScalePercentageFactor
                            forWindow:self.window
                             callBack:^(NSNumber *newValue) {
								 if (newValue != nil) {
										 // Extract the new scale value
									 double scaleValue = [newValue doubleValue];
										 // Change the scale of the window
									 [self changeViewScale:scaleValue / kScalePercentageFactor];
								 }
								 chooseScale = nil;
							 }];
    }
	else if (scaleValue != currentScale) {
			// Change the scale of the window
        [self changeViewScale:scaleValue];
	}
}

- (IBAction)setScaleLevel:(id)sender
{
	NSInteger selectedItem = [self.scaleComboBox indexOfSelectedItem];
	if (selectedItem == -1) {
			// No selection, so we take the value from the text field
		CGFloat percentageEntered = [self.scaleComboBox floatValue];
		CGFloat scaleEntered = percentageEntered / kScalePercentageFactor;
		[self changeViewScale:scaleEntered];
	}
	else {
		ViewScale *selectedObject = scalesList[selectedItem];
		CGFloat scaleValue = [selectedObject scaleValue];
		if (scaleValue < 0) {
			[self changeViewScale:[self fitWidthScale]];
		}
		else {
			[self changeViewScale:scaleValue];
		}
	}
	[self setViewScaleComboBox];
	[self.window makeFirstResponder:self.keyboardView];
}

- (void)enterDeadKeyStateWithName:(NSString *)stateName
{
	if ([stateName isEqualToString:internalState[kStateCurrentState]]) {
			// We're already in this state
		NSLog(@"Trying to enter state %@ when we are in that state", stateName);
		return;
	}
	[stateStack addObject:stateName];
    internalState[kStateCurrentState] = stateName;
	[self updateWindow];
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	[infoInspector setStateStack:stateStack];
}

- (void)leaveCurrentDeadKeyState
{
	if ([stateStack count] <= 1) {
		NSLog(@"Trying to pop state none");
		return;
	}
	[stateStack removeLastObject];
    internalState[kStateCurrentState] = [stateStack lastObject];
	[self updateWindow];
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	[infoInspector setStateStack:stateStack];
}

- (void)setMessageBarText:(NSString *)message
{
	[self.messageBar setStringValue:message];
	[self.messageBar setNeedsDisplay:YES];
}

- (void)setSelectedKey:(NSInteger)keyCode {
	if (selectedKey == keyCode) {
			// Selecting the same key, so toggle it
		[self clearSelectedKey];
		return;
	}
	if (selectedKey != kNoKeyCode) {
			// There was a previous selected key
		[self clearSelectedKey];
	}
	selectedKey = keyCode;
	UkeleleView *ukeleleView = [self.keyboardView documentView];
	KeyCapView *keyCap = [ukeleleView findKeyWithCode:(int)selectedKey];
	if (keyCap) {
		[keyCap setSelected:YES];
		[self updateWindow];
	}
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	if ([[infoInspector window] isVisible]) {
		NSString *keyCodeString = [NSString stringWithFormat:@"%ld", (long)keyCode];
		[[infoInspector selectedKeyField] setStringValue:keyCodeString];
	}
}

- (void)clearSelectedKey {
	UkeleleView *ukeleleView = [self.keyboardView documentView];
	KeyCapView *keyCap = [ukeleleView findKeyWithCode:(int)selectedKey];
	if (keyCap) {
		[keyCap setSelected:NO];
		[self updateWindow];
	}
	selectedKey = kNoKeyCode;
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	if ([[infoInspector window] isVisible]) {
		[[infoInspector selectedKeyField] setStringValue:@""];
	}
}

#pragma mark Callbacks

- (void)showEditingPaneForKeyCode:(int)keyCode text:(NSString *)initialText target:(id)target action:(SEL)action
{
	UkeleleView *ukeleleView = [self.keyboardView documentView];
	KeyCapView *keyCap = [ukeleleView findKeyWithCode:keyCode];
	NSRect editingPaneFrame = [keyCap frame];
	NSTextField *editingPane = [[NSTextField alloc] initWithFrame:editingPaneFrame];
	[ukeleleView addSubview:editingPane];
	[editingPane setEditable:YES];
	[editingPane setStringValue:initialText];
	[editingPane setTarget:target];
	[editingPane setAction:action];
	[editingPane setHidden:NO];
	[editingPane setDelegate:target];
	[[ukeleleView window] makeFirstResponder:editingPane];
}

- (void)handleScaleChoice:(NSNumber *)newValue
{
    if (newValue != nil) {
			// Extract the new scale value
        double scaleValue = [newValue doubleValue];
			// Change the scale of the window
        [self changeViewScale:scaleValue / kScalePercentageFactor];
    }
    chooseScale = nil;
}

- (void)acceptDeadKeyStateToEnter:(NSString *)stateName
{
	if (stateName == nil) {
			// User cancelled
	} else {
		[self enterDeadKeyStateWithName:stateName];
	}
	askFromList = nil;
}

- (void)setKeyboard:(NSNumber *)keyboardID
{
	if (keyboardID == nil) {
			// User cancelled
	}
	else {
		NSInteger theKeyboard = [keyboardID intValue];
		[self changeKeyboardType:theKeyboard];
	}
	keyboardTypeSheet = nil;
}

#pragma mark User actions

- (IBAction)createDeadKeyState:(id)sender
{
	NSAssert(interactionHandler == nil, @"Starting an interaction when one is in progress");
	NSUInteger currentModifiers = [internalState[kStateCurrentModifiers] unsignedIntegerValue];
	CreateDeadKeyHandler *theHandler = [[CreateDeadKeyHandler alloc]
										initWithCurrentState:internalState[kStateCurrentState]
										modifiers:currentModifiers
										keyboardID:[internalState[kStateCurrentKeyboard] integerValue]
										keyboardWindow:self
										keyCode:selectedKey
										nextState:nil
										terminator:nil];
	interactionHandler = theHandler;
	[theHandler setCompletionTarget:self];
	[theHandler startHandling];
}

- (IBAction)enterDeadKeyState:(id)sender
{
		// Ask for a dead key state to enter
	if (!askFromList) {
		askFromList = [AskFromList askFromList];
	}
	NSString *dialogText = NSLocalizedStringFromTable(@"Choose the dead key state to enter.",
													  @"dialogs", @"Choose dead key state to enter");
	NSArray *menuItems = [self.keyboardLayout stateNamesExcept:internalState[kStateCurrentState]];
	[askFromList beginAskFromListWithText:dialogText
								 withMenu:menuItems
								forWindow:self.window
								 callBack:^(NSString *stateName) {
									 if (stateName == nil) {
											 // User cancelled
									 } else {
										 [self enterDeadKeyStateWithName:stateName];
									 }
									 askFromList = nil;
								 }];
}

- (IBAction)leaveDeadKeyState:(id)sender
{
	[self leaveCurrentDeadKeyState];
}

- (void)changeDeadKeyNextState:(NSDictionary *)keyDataDict newState:(NSString *)nextState
{
	[self.keyboardLayout changeDeadKeyNextState:keyDataDict toState:nextState];
	[self updateWindow];
}

- (void)createNewDeadKey:(NSDictionary *)keyDataDict nextState:(NSString *)nextState usingExistingState:(BOOL)usingExisting
{
	if (!usingExisting) {
		[self.keyboardLayout createState:nextState withTerminator:keyDataDict[kDeadKeyDataTerminator]];
	}
	[self.keyboardLayout makeKeyDeadKey:keyDataDict state:nextState];
	[self enterDeadKeyStateWithName:nextState];
}

- (IBAction)unlinkKey:(id)sender
{
	if ([kTabNameModifiers isEqualToString:[[self.tabView selectedTabViewItem] identifier]]) {
			// We're on the modifiers tab, so invoke unlinking a set
//		[self unlinkModifierSet:sender];
		return;
	}
	NSAssert(interactionHandler == nil, @"Interaction is in progress");
	UnlinkKeyHandler *theHandler = [UnlinkKeyHandler unlinkKeyHandler:self];
	interactionHandler = theHandler;
	[theHandler setCompletionTarget:self];
	UnlinkKeyType keyType = kUnlinkKeyTypeAskKey;
	if (selectedKey != kNoKeyCode || [sender isMemberOfClass:[KeyCapView class]]) {
		keyType = kUnlinkKeyTypeSelectedKey;
		if (selectedKey != kNoKeyCode) {
			[theHandler setSelectedKeyCode:selectedKey];
		}
		else {
			[theHandler setSelectedKeyCode:[(KeyCapView *)sender keyCode]];
		}
	}
	[theHandler beginInteraction:keyType];
}

- (IBAction)unlinkKeyAskingKeyCode:(id)sender
{
	NSAssert(interactionHandler == nil, @"Interaction is in progress");
	UnlinkKeyHandler *theHandler = [UnlinkKeyHandler unlinkKeyHandler:self];
	interactionHandler = theHandler;
	[theHandler setCompletionTarget:self];
	[theHandler beginInteraction:kUnlinkKeyTypeAskCode];
}

- (void)unlinkModifierCombination {
	NSAssert(interactionHandler == nil, @"Interaction is in progress");
	UnlinkModifierSetHandler *theHandler = [UnlinkModifierSetHandler unlinkModifierSetHandler:self];
	interactionHandler = theHandler;
	[theHandler setCompletionTarget:self];
	[theHandler beginInteractionWithCallback:^(NSInteger modifierSet) {
		if (modifierSet >= 0) {
				// Unlink the set
			NSInteger keyboardID = [internalState[kStateCurrentKeyboard] integerValue];
			[self.keyboardLayout unlinkModifierSet:modifierSet forKeyboard:keyboardID];
		}
	}];
}

- (IBAction)swapKeys:(id)sender {
	interactionHandler = [SwapKeysController swapKeysController:self];
	[(SwapKeysController *)interactionHandler beginInteraction:NO];
}

- (IBAction)swapKeysByCode:(id)sender {
	interactionHandler = [SwapKeysController swapKeysController:self];
	[(SwapKeysController *)interactionHandler beginInteraction:YES];
}

- (IBAction)setKeyboardType:(id)sender
{
	keyboardTypeSheet = [KeyboardTypeSheet createKeyboardTypeSheet];
	[keyboardTypeSheet beginKeyboardTypeSheetForWindow:self.window
										  withKeyboard:[internalState[kStateCurrentKeyboard] integerValue]
											  callBack:^(NSNumber *keyboardID) {
												  if (keyboardID == nil) {
														  // User cancelled
												  }
												  else {
													  NSInteger theKeyboard = [keyboardID intValue];
													  [self changeKeyboardType:theKeyboard];
												  }
												  keyboardTypeSheet = nil;
											  }];
}

- (IBAction)importDeadKey:(id)sender {
	NSAssert(interactionHandler == nil, @"Cannot start new interaction");
	ImportDeadKeyHandler *importHandler = [ImportDeadKeyHandler importDeadKeyHandler];
	interactionHandler = importHandler;
	[importHandler setCompletionTarget:self];
	[importHandler beginInteractionForWindow:self];
}

- (IBAction)changeTerminator:(id)sender {
	NSString *currentTerminator;
	NSString *currentState = internalState[kStateCurrentState];
	if ([sender isMemberOfClass:[KeyCapView class]]) {
			// Contextual menu version
		NSInteger keyCode = [(KeyCapView *)sender keyCode];
		NSDictionary *keyData = @{kKeyKeyboardID: internalState[kStateCurrentKeyboard],
								  kKeyState: currentState,
								  kKeyKeyCode: @(keyCode),
								  kKeyModifiers: internalState[kStateCurrentModifiers]};
		currentState = [self.keyboardLayout getNextState:keyData];
	}
	if ([currentState isEqualToString:kStateNameNone]) {
			// Not in a dead key state, and not a contextual menu
		[self changeTerminatorSpecifyingState];
		return;
	}
	currentTerminator = [self.keyboardLayout terminatorForState:currentState];
	__block AskTextSheet *askTerminatorSheet = [AskTextSheet askTextSheet];
	[askTerminatorSheet beginAskText:@"Please enter the new terminator"
						   minorText:[NSString stringWithFormat:@"This will be the terminator for the state \"%@\"", currentState]
						 initialText:currentTerminator
						   forWindow:self.window
							callBack:^(NSString *suppliedString) {
								if (suppliedString) {
										// Got a new terminator
									[self changeTerminatorForState:currentState to:suppliedString];
								}
								askTerminatorSheet = nil;
							}];
}

- (void)changeTerminatorSpecifyingState {
	__block AskStateAndTerminatorController *theController = [AskStateAndTerminatorController askStateAndTerminatorController];
	[theController beginInteractionWithWindow:self.window
								  forDocument:self.keyboardLayout
							  completionBlock:^(NSDictionary *dataDict) {
								  if (dataDict) {
										  // Got a valid terminator
									  [self changeTerminatorForState:dataDict[kAskStateAndTerminatorState] to:dataDict[kAskStateAndTerminatorTerminator]];
								  }
								  theController = nil;
							  }];
}

- (IBAction)editKey:(id)sender {
	__block EditKeyWindowController *editKeyWindow = [EditKeyWindowController editKeyWindowController];
	NSDictionary *editKeyData = @{kKeyKeyboardObject: self.keyboardLayout,
								  kKeyKeyboardID: @(self.currentKeyboard),
								  kKeyState: self.currentState,
								  kKeyKeyCode: @(selectedKey),
								  kKeyModifiers: @(self.currentModifiers)};
	[editKeyWindow beginInteractionForWindow:self.window withData:editKeyData action:^(NSDictionary *callbackData) {
		if ([callbackData[kKeyKeyType] isEqualToString:kKeyTypeOutput]) {
				// Output key
			NSDictionary *keyData = @{kKeyKeyboardObject: self.keyboardLayout,
									  kKeyKeyboardID: @(self.currentKeyboard),
									  kKeyState: self.currentState,
									  kKeyModifiers: callbackData[kDeadKeyDataModifiers],
									  kKeyKeyCode: callbackData[kDeadKeyDataKeyCode]};
			BOOL deadKey = [self.keyboardLayout isDeadKey:keyData];
			if (deadKey) {
				[self makeDeadKeyOutput:keyData output:callbackData[kKeyKeyOutput]];
			}
			else {
				BOOL jisOnly = [[ToolboxData sharedToolboxData] JISOnly];
				[self changeOutputForKey:keyData to:callbackData[kKeyKeyOutput] usingBaseMap:!jisOnly];
			}
		}
		else if ([callbackData[kKeyKeyType] isEqualToString:kKeyTypeDead]) {
				// Dead key
			CreateDeadKeyHandler *theHandler = [[CreateDeadKeyHandler alloc]
												initWithCurrentState:internalState[kStateCurrentState]
												modifiers:[internalState[kStateCurrentModifiers] unsignedIntegerValue]
												keyboardID:[internalState[kStateCurrentKeyboard] integerValue]
												keyboardWindow:self
												keyCode:[callbackData[kKeyKeyCode] integerValue]
												nextState:callbackData[kKeyNextState]
												terminator:callbackData[kKeyTerminator]];
			interactionHandler = theHandler;
			[theHandler setCompletionTarget:self];
			[theHandler startHandling];
		}
		editKeyWindow = nil;
	}];
}

- (IBAction)selectKeyByCode:(id)sender {
	__block SelectKeyByCodeController *selectKeySheet = [SelectKeyByCodeController selectKeyByCodeController];
	[selectKeySheet setMajorText:@"Enter the code of the key you want to select. Codes are in the range from 0 to 511, though the usual range is 0 to 127."];
	[selectKeySheet setMinorText:@""];
	[selectKeySheet beginDialogWithWindow:self.window completionBlock:^(NSInteger keyCode) {
		if (keyCode >= 0) {
				// Valid selection
			[self setSelectedKey:keyCode];
		}
		selectKeySheet = nil;
	}];
}

- (void)changeFont:(id)sender {
		// The font has changed in the font panel, so update the window
	UkeleleView *ukeleleView = [self.keyboardView documentView];
	NSDictionary *largeAttributes = [ukeleleView largeAttributes];
	NSDictionary *smallAttributes = [ukeleleView smallAttributes];
	NSFont *oldLargeFont = largeAttributes[NSFontAttributeName];
	NSFont *newLargeFont = [sender convertFont:oldLargeFont];
	NSMutableDictionary *newLargeAttributes = [largeAttributes mutableCopy];
	newLargeAttributes[NSFontAttributeName] = newLargeFont;
	[ukeleleView setLargeAttributes:newLargeAttributes];
	CGFloat largeSize = [newLargeFont pointSize];
	CGFloat smallSize = largeSize * kDefaultSmallFontSize / kDefaultLargeFontSize;
	NSFont *newSmallFont = [sender convertFont:newLargeFont toSize:smallSize];
	NSMutableDictionary *newSmallAttributes = [smallAttributes mutableCopy];
	newSmallAttributes[NSFontAttributeName] = newSmallFont;
	[ukeleleView setSmallAttributes:newSmallAttributes];
}

- (IBAction)cutKey:(id)sender {
	NSInteger keyCode;
	if ([sender isKindOfClass:[KeyCapView class]]) {
			// Came from a contextual menu
		keyCode = [(KeyCapView *)sender keyCode];
	}
	else if (selectedKey != kNoKeyCode) {
			// We have a selected key, so use that
		keyCode = selectedKey;
	}
	else {
			// No selected key, so need to ask for it
		[self setMessageBarText:@"Click or type the key you wish to cut"];
		interactionHandler = [GetKeyCodeHandler getKeyCodeHandler];
		[(GetKeyCodeHandler *)interactionHandler setCompletionTarget:self];
		[(GetKeyCodeHandler *)interactionHandler beginInteractionWithCompletion:^(NSInteger enteredKeyCode) {
			if (enteredKeyCode != kNoKeyCode) {
				[self doCutKey:enteredKeyCode];
			}
			[self setMessageBarText:@""];
		}];
		return;
	}
	[self doCutKey:keyCode];
}

- (IBAction)copyKey:(id)sender {
	NSInteger keyCode;
	if ([sender isKindOfClass:[KeyCapView class]]) {
			// Came from a contextual menu
		keyCode = [(KeyCapView *)sender keyCode];
	}
	else if (selectedKey != kNoKeyCode) {
			// We have a selected key, so use that
		keyCode = selectedKey;
	}
	else {
			// No selected key, so need to ask for it
		[self setMessageBarText:@"Click or type the key you wish to copy"];
		interactionHandler = [GetKeyCodeHandler getKeyCodeHandler];
		[(GetKeyCodeHandler *)interactionHandler setCompletionTarget:self];
		[(GetKeyCodeHandler *)interactionHandler beginInteractionWithCompletion:^(NSInteger enteredKeyCode) {
			if (enteredKeyCode != kNoKeyCode) {
				[self doCopyKey:enteredKeyCode];
			}
			[self setMessageBarText:@""];
		}];
		return;
	}
	[self doCopyKey:keyCode];
}

- (IBAction)pasteKey:(id)sender {
	NSInteger keyCode;
	if ([sender isKindOfClass:[KeyCapView class]]) {
			// Came from a contextual menu
		keyCode = [(KeyCapView *)sender keyCode];
	}
	else if (selectedKey != kNoKeyCode) {
			// We have a selected key, so use that
		keyCode = selectedKey;
	}
	else {
			// No selected key, so need to ask for it
		[self setMessageBarText:@"Click or type the key you wish to paste onto"];
		interactionHandler = [GetKeyCodeHandler getKeyCodeHandler];
		[(GetKeyCodeHandler *)interactionHandler setCompletionTarget:self];
		[(GetKeyCodeHandler *)interactionHandler beginInteractionWithCompletion:^(NSInteger enteredKeyCode) {
			if (enteredKeyCode != kNoKeyCode) {
				[self doPasteKey:enteredKeyCode];
			}
			[self setMessageBarText:@""];
		}];
		return;
	}
	[self doPasteKey:keyCode];
}

- (IBAction)makeOutput:(id)sender {
	NSInteger keyCode = [(KeyCapView *)sender keyCode];
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:self, kKeyDocument,
									 internalState[kStateCurrentKeyboard], kKeyKeyboardID,
									 @(keyCode), kKeyKeyCode,
									 internalState[kStateCurrentModifiers], kKeyModifiers,
									 internalState[kStateCurrentState], kKeyState, nil];
	DoubleClickHandler *handler = [[DoubleClickHandler alloc] initWithData:dataDict
															keyboardLayout:self.keyboardLayout
																	window:self.window];
    [handler setCompletionTarget:self];
	[handler setDeadKeyProcessingType:kDoubleClickDeadKeyChangeToOutput];
	[handler startDoubleClick];
    interactionHandler = handler;
}

- (IBAction)makeDeadKey:(id)sender {
	selectedKey = [(KeyCapView *)sender keyCode];
	[self createDeadKeyState:self];
}

- (IBAction)changeNextState:(id)sender {
	NSInteger keyCode = [(KeyCapView *)sender keyCode];
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:self, kKeyDocument,
									 internalState[kStateCurrentKeyboard], kKeyKeyboardID,
									 @(keyCode), kKeyKeyCode,
									 internalState[kStateCurrentModifiers], kKeyModifiers,
									 internalState[kStateCurrentState], kKeyState, nil];
	DoubleClickHandler *handler = [[DoubleClickHandler alloc] initWithData:dataDict
															keyboardLayout:self.keyboardLayout
																	window:self.window];
    [handler setCompletionTarget:self];
	[handler askNewState];
    interactionHandler = handler;
}

- (IBAction)changeOutput:(id)sender {
	NSInteger keyCode = [(KeyCapView *)sender keyCode];
	[self messageDoubleClick:(int)keyCode];
}

- (IBAction)attachComment:(id)sender {
	NSInteger keyCode = selectedKey;
	if ([sender isKindOfClass:[KeyCapView class]]) {	// From contextual menu
		keyCode = [(KeyCapView *)sender keyCode];
	}
	if (keyCode == kNoKeyCode) {
		return;
	}
	__block AskCommentController *commentController = [AskCommentController askCommentController];
	[commentController askCommentForWindow:self.window completion:^(NSString *commentText) {
		if (commentText != nil && [commentText length] > 0) {
				// Got a non-empty comment
			NSDictionary *dataDict = @{kKeyDocument: self,
									   kKeyKeyboardID: internalState[kStateCurrentKeyboard],
									   kKeyKeyCode: @(keyCode),
									   kKeyModifiers: internalState[kStateCurrentModifiers],
									   kKeyState: internalState[kStateCurrentState]};
			XMLCommentHolderObject *commentHolder = [self.keyboardLayout commentHolderForKey:dataDict];
			[self addComment:commentText toHolder:commentHolder];
		}
		commentController = nil;
	}];
}

	// Install the keyboard layout

- (IBAction)installForCurrentUser:(id)sender {
	[[self parentDocument] installForCurrentUser:self];
}

- (IBAction)installForAllUsers:(id)sender {
	[[self parentDocument] installForAllUsers:self];
}

#pragma mark Messages

- (void)handleKeyCapClick:(KeyCapView *)keyCapView clickCount:(NSInteger)clickCount {
	if (clickCount == 1) {
		[self messageClick:(int)[keyCapView keyCode]];
	}
	else if (clickCount == 2) {
		[self messageDoubleClick:(int)[keyCapView keyCode]];
	}
}

- (void)messageModifiersChanged:(int)modifiers
{
	static NSUInteger lastModifiers = 0;
		// Modifiers have changed, so make note of changes
	BOOL usingStickyModifiers = [[ToolboxData sharedToolboxData] stickyModifiers];
	NSUInteger newCurrentModifiers = modifiers;
	if (usingStickyModifiers) {
		NSUInteger changedModifiers = lastModifiers ^ modifiers;
		static NSUInteger modifierKeys[] = { NSShiftKeyMask, NSCommandKeyMask, NSControlKeyMask, NSAlternateKeyMask };
		static NSInteger numModifierKeys = sizeof(modifierKeys) / sizeof(NSUInteger);
		for (NSUInteger i = 0; i < numModifierKeys; i++) {
				// If it is a key down event, then update the modifiers
			if ((changedModifiers & modifierKeys[i]) && (modifiers & modifierKeys[i])) {
				newCurrentModifiers ^= modifierKeys[i];
			}
		}
		newCurrentModifiers &= ~NSAlphaShiftKeyMask;
		newCurrentModifiers |= NSAlphaShiftKeyMask & modifiers;
	}
    internalState[kStateCurrentModifiers] = @(newCurrentModifiers);
	[self inspectorSetModifiers];
	[self inspectorSetModifierMatch];
	[self updateWindow];
}

- (void)messageMouseEntered:(int)keyCode
{
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	if ([[infoInspector window] isVisible]) {
		NSDictionary *keyDataDict = @{kKeyKeyboardID: internalState[kStateCurrentKeyboard],
									  kKeyKeyCode: @(keyCode),
									  kKeyModifiers: internalState[kStateCurrentModifiers],
									  kKeyState: internalState[kStateCurrentState]};
        NSString *displayText = [self.keyboardLayout getOutputInfoForKey:keyDataDict];
		[[infoInspector outputField] setStringValue:displayText];
	}
}

- (void)messageMouseExited:(int)keyCode
{
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	if ([[infoInspector window] isVisible]) {
		[[infoInspector outputField] setStringValue:@""];
	}
}

- (void)messageKeyDown:(int)keyCode
{
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	if ([[infoInspector window] isVisible]) {
		NSString *keyCodeString = [NSString stringWithFormat:@"%d", keyCode];
		[[infoInspector keyCodeField] setStringValue:keyCodeString];
	}
	if (interactionHandler != nil) {
		NSDictionary *messageDictionary = @{kMessageNameKey: kMessageKeyDown,
											kMessageArgumentKey: @(keyCode)};
		[interactionHandler handleMessage:messageDictionary];
	}
	else {
		[self setSelectedKey:keyCode];
	}
}

- (void)messageKeyUp:(int)keyCode
{
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	if ([[infoInspector window] isVisible]) {
		[[infoInspector keyCodeField] setStringValue:@""];
	}
}

- (void)messageClick:(int)keyCode
{
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	if ([[infoInspector window] isVisible]) {
		NSString *keyCodeString = [NSString stringWithFormat:@"%d", keyCode];
		[[infoInspector keyCodeField] setStringValue:keyCodeString];
	}
	BOOL usingStickyModifiers = [[ToolboxData sharedToolboxData] stickyModifiers];
	BOOL handleClickAsDoubleClick = [[NSUserDefaults standardUserDefaults] boolForKey:UKUsesSingleClickToEdit];
	if ([LayoutInfo getKeyType:keyCode] == kModifierKeyType) {
		if (usingStickyModifiers) {
				// Toggle the modifier key
			NSUInteger modifier = [LayoutInfo getModifierFromKeyCode:keyCode];
			NSUInteger currentModifiers = [internalState[kStateCurrentModifiers] unsignedIntegerValue];
			currentModifiers ^= modifier;
			internalState[kStateCurrentModifiers] = @(currentModifiers);
			[self inspectorSetModifiers];
			[self inspectorSetModifierMatch];
			[self updateWindow];
		}
	}
	else if (interactionHandler != nil) {
			// Allow the interaction handler to deal with this
		NSDictionary *messageDictionary = @{kMessageNameKey: kMessageClick,
											kMessageArgumentKey: @(keyCode)};
		[interactionHandler handleMessage:messageDictionary];
	}
	else if (handleClickAsDoubleClick) {
		[self messageDoubleClick:keyCode];
	}
	else {
		[self setSelectedKey:keyCode];
	}
}

- (void)messageDoubleClick:(int)keyCode
{
	if (interactionHandler != nil) {
			// We're in the midst of an interaction, so we can't start a new one
		return;
	}
	else if ([LayoutInfo getKeyType:keyCode] == kModifierKeyType) {
			// Double-clicking a modifier key should be treated as two clicks
		[self messageClick:keyCode];
		return;
	}
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:self, kKeyDocument,
									 internalState[kStateCurrentKeyboard], kKeyKeyboardID,
									 @(keyCode), kKeyKeyCode,
									 internalState[kStateCurrentModifiers], kKeyModifiers,
									 internalState[kStateCurrentState], kKeyState, nil];
	DoubleClickHandler *handler = [[DoubleClickHandler alloc] initWithData:dataDict
															keyboardLayout:self.keyboardLayout
																	window:self.window];
    [handler setCompletionTarget:self];
	[handler startDoubleClick];
    interactionHandler = handler;
}

- (void)messageDragText:(NSString *)draggedText toKey:(int)keyCode
{
		// Handle drop of text onto a key
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:self, kKeyDocument,
									 internalState[kStateCurrentKeyboard], kKeyKeyboardID,
									 @(keyCode), kKeyKeyCode,
									 internalState[kStateCurrentModifiers], kKeyModifiers,
									 internalState[kStateCurrentState], kKeyState, nil];
	DragTextHandler *handler = [[DragTextHandler alloc] initWithData:dataDict
															dragText:draggedText
															  window:self.window];
    [handler setCompletionTarget:self];
	[handler startDrag];
	interactionHandler = handler;
}

- (void)messageEditPaneClosed
{
	UkeleleView *ukeleleView = [self.keyboardView documentView];
	[[ukeleleView window] makeFirstResponder:ukeleleView];
}

- (void)messageScaleChanged:(CGFloat)newScale
{
	internalState[kStateCurrentScale] = @(newScale);
	[self setViewScaleComboBox];
}

- (void)messageScaleCompleted
{
		// Tell the font panel what font we have
	UkeleleView *ukeleleView = [self.keyboardView documentView];
	NSDictionary *largeAttributes = [ukeleleView largeAttributes];
	NSFont *largeFont = largeAttributes[NSFontAttributeName];
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	[fontManager setSelectedFont:largeFont isMultiple:NO];
    [self calculateSize];
    [self setViewScaleComboBox];
	[self updateWindow];
}

#pragma mark Action routines

- (void)changeOutputForKey:(NSDictionary *)keyDataDict to:(NSString *)newOutput usingBaseMap:(BOOL)usingBaseMap
{
		// Check whether the output is actually different
	NSString *oldOutput = [self.keyboardLayout getCharOutput:keyDataDict isDead:nil nextState:nil];
	if (![oldOutput isEqualToString:newOutput]) {
		[self.keyboardLayout changeOutputForKey:keyDataDict to:newOutput usingBaseMap:usingBaseMap];
		[self updateWindow];
	}
}

- (void)changeTerminatorForState:(NSString *)stateName to:(NSString *)newTerminator
{
		// Check whether the terminator is actually different
	NSString *oldTeminator = [self.keyboardLayout getTerminatorForState:stateName];
	if (![oldTeminator isEqualToString:newTerminator]) {
		[self.keyboardLayout changeTerminatorForState:stateName to:newTerminator];
		[self updateWindow];
	}
}

- (void)makeKeyDeadKey:(NSDictionary *)keyDataDict state:(NSString *)nextState
{
	[self.keyboardLayout makeKeyDeadKey:keyDataDict state:nextState];
	[self updateWindow];
}

- (void)makeDeadKeyOutput:(NSDictionary *)keyDataDict output:(NSString *)newOutput
{
	[self.keyboardLayout makeDeadKeyOutput:keyDataDict output:newOutput];
	[self updateWindow];
}

- (void)unlinkKeyWithKeyCode:(NSInteger)keyCode andModifiers:(NSUInteger)modifierCombination
{
	NSDictionary *keyDataDict = @{kKeyKeyboardID: internalState[kStateCurrentKeyboard],
								  kKeyKeyCode: @(keyCode), kKeyModifiers: @(modifierCombination)};
	if (![self.keyboardLayout isActionElement:keyDataDict]) {
			// It's not an action element, so we can't unlink
		NSString *messageText = NSLocalizedStringFromTable(@"The key you specified is not linked, so cannot be unlinked", @"dialogs", @"Tell the user why it cannot be unlinked");
		NSString *infoText = NSLocalizedStringFromTable(@"A key may be not be linked because it only ever produces one output (e.g. the space bar), or because it never produces any output (e.g. in an empty keyboard layout)", @"dialogs", @"Explain what may produce a key not linked");
		NSAssert(documentAlert == nil, @"Starting an alert when one already exists");
		documentAlert = [[NSAlert alloc] init];
		[documentAlert setAlertStyle:NSInformationalAlertStyle];
		[documentAlert setMessageText:messageText];
		[documentAlert setInformativeText:infoText];
		[documentAlert beginSheetModalForWindow:self.window
								  modalDelegate:self
								 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
									contextInfo:nil];
		return;
	}
	[self doUnlinkKey:keyDataDict];
}

- (void)doUnlinkKey:(NSDictionary *)keyDataDict
{
	NSString *actionName = [_keyboardLayout actionNameForKey:keyDataDict];
	[self.keyboardLayout unlinkKey:keyDataDict];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] doRelinkKey:keyDataDict originalAction:actionName];
	[undoManager setActionName:@"Unlink key"];
	[self updateWindow];
}

- (void)doRelinkKey:(NSDictionary *)keyDataDict originalAction:(NSString *)actionName
{
	[self.keyboardLayout relinkKey:keyDataDict actionName:actionName];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] doUnlinkKey:keyDataDict];
	[undoManager setActionName:@"Unlink key"];
	[self updateWindow];
}

- (void)swapKeyWithCode:(NSInteger)keyCode1 andKeyWithCode:(NSInteger)keyCode2 {
	[self.keyboardLayout swapKeyCode:keyCode1 withKeyCode:keyCode2];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] swapKeyWithCode:keyCode1 andKeyWithCode:keyCode2];
	[undoManager setActionName:@"Swap keys"];
	[self updateWindow];
}

- (void)doCutKey:(NSInteger)keyCode {
	[self.keyboardLayout cutKeyCode:keyCode];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] undoCutKey:keyCode];
	[undoManager setActionName:@"Cut key"];
	[self updateWindow];
}

- (void)undoCutKey:(NSInteger)keyCode {
	[self.keyboardLayout undoCutKeyCode:keyCode];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] doCutKey:keyCode];
	[undoManager setActionName:@"Cut key"];
	[self updateWindow];
}

- (void)doCopyKey:(NSInteger)keyCode {
	[self.keyboardLayout copyKeyCode:keyCode];
}

- (void)doPasteKey:(NSInteger)keyCode {
	[self.keyboardLayout pasteKeyCode:keyCode];
}

#pragma mark Delegate methods

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
	if (self.undoManager == nil) {
		self.undoManager = [[NSUndoManager alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noteUndoAction:) name:NSUndoManagerWillRedoChangeNotification object:self.undoManager];
	}
	return self.undoManager;
}

- (void)documentDidChange {
	[self updateWindow];
}

- (NSMenu *)contextualMenuForData:(NSDictionary *)dataDict {
	NSMenu *theMenu = nil;
	NSInteger keyCode = [dataDict[kKeyKeyCode] integerValue];
	unsigned int keyType = [LayoutInfo getKeyType:(unsigned int)keyCode];
	if (keyType == kModifierKeyType) {
			// Modifier key: No menu
	}
	else if (keyType == kOrdinaryKeyType || keyType == kSpecialKeyType) {
			// Ordinary or special key
		NSDictionary *keyData = @{kKeyKeyboardID: internalState[kStateCurrentKeyboard],
								  kKeyKeyCode: @(keyCode),
								  kKeyModifiers: internalState[kStateCurrentModifiers],
								  kKeyState: internalState[kStateCurrentState]};
		BOOL deadKey = [self.keyboardLayout isDeadKey:keyData];
		if (deadKey) {
				// Contextual menu for a dead key
			theMenu = [self deadKeyContextualMenu];
		}
		else {
				// Contextual menu for a non-dead key
			theMenu = [self nonDeadKeyContextualMenu];
		}
			// Enable menu items
		for (NSMenuItem *menuItem in [theMenu itemArray]) {
			[menuItem setEnabled:[self validateUserInterfaceItem:menuItem]];
		}
	}
	return theMenu;
}

- (void)modifierMapDidChange
{
		// Delegate method to indicate that the modifier map has changed
    [self modifierMapDidChangeImplementation];
}

#pragma mark Notifications

- (void)noteUndoAction:(NSNotification *)theNotification {
		// We have at least one undoable action, so notify the document
	[[self parentDocument] keyboardLayoutDidChange:self.keyboardLayout];
}

@end

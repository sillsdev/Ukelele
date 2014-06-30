//
//  KeyboardPrintView.m
//  Ukelele 3
//
//  Created by John Brownie on 22/11/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "KeyboardPrintView.h"
#import "UkeleleView.h"
#import "UkeleleConstantStrings.h"
#import "UKKeyboardController.h"
#import "UKKeyboardDocument.h"

CGFloat kLabelViewHeight = 20.0;

@interface KeyboardViewPlaceHolder : NSObject

@property (nonatomic, weak) NSView *keyboardView;
@property (nonatomic) NSPoint origin;
@property (nonatomic, copy) NSString *stateName;
@property (nonatomic) NSUInteger modifierCombination;

@end

@implementation KeyboardViewPlaceHolder

- (id)init {
	self = [super init];
	if (self) {
		_keyboardView = nil;
		_origin.x = 0.0;
		_origin.y = 0.0;
		_stateName = @"";
		_modifierCombination = 0;
	}
	return self;
}


@end

@implementation KeyboardPrintView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		_parentDocument = nil;
		keyboardViews = [NSMutableArray array];
		labelViews = [NSMutableArray array];
		_allStates = NO;
		_allModifiers = YES;
		keyboardHeight = 0;
		keyboardPlaceHolders = [NSMutableArray array];
    }
    
    return self;
}


- (void)setAllStates:(BOOL)newAllStates {
	_allStates = newAllStates;
	[self updatePageCount];
}

- (void)setAllModifiers:(BOOL)newAllModifiers {
	_allModifiers = newAllModifiers;
	[self updatePageCount];
}

- (void)setupPageParameters {
	NSPrintInfo *pi = [[[self parentDocument] parentDocument] printInfo];
	if (nil == pi) {
		return;
	}
	NSSize paperSize = [pi paperSize];
	CGFloat pageWidth = paperSize.width - [pi leftMargin] - [pi rightMargin];
	CGFloat pageHeight = paperSize.height - [pi topMargin] - [pi bottomMargin];
	NSView *keyboardView = [[self parentDocument] keyboardView];
	CGFloat keyboardWidth = [keyboardView bounds].size.width;
	CGFloat viewHeight = [keyboardView bounds].size.height;
	CGFloat currentScale = [[self parentDocument] currentScale];
	keyboardScaleValue = pageWidth / (keyboardWidth / currentScale);
	keyboardHeight = (viewHeight / currentScale) * keyboardScaleValue;
	keyboardsPerPage = floor(pageHeight / (keyboardHeight + kLabelViewHeight));
	[self updatePageCount];
}

- (NSInteger)pageCount {
	NSInteger count = ([keyboardPlaceHolders count] + keyboardsPerPage - 1) / keyboardsPerPage;
	return count;
}

- (void)updatePageCount {
	UkeleleKeyboardObject *keyboardObject = [[self parentDocument] keyboardLayout];
	NSUInteger currentKeyboard = [[self parentDocument] currentKeyboard];
	NSArray *modifierIndices = [keyboardObject getModifierIndices];
	NSUInteger keyboardCount = 1;
	if (_allStates) {
			// stateCount leaves out state "none"
		keyboardCount *= [keyboardObject stateCount] + 1;
	}
	if (_allModifiers) {
		keyboardCount *= [modifierIndices count];
	}
	if (keyboardCount == [keyboardPlaceHolders count]) {
			// Nothing to do, as the count has not changed
		return;
	}
		// Get the states and modifiers we will represent
	NSMutableArray *stateNames;
	if (_allStates) {
		stateNames = [NSMutableArray arrayWithObject:kStateNameNone];
		[stateNames addObjectsFromArray:[keyboardObject stateNamesExcept:@""]];
	}
	else {
		stateNames = [NSMutableArray arrayWithObject:[[self parentDocument] currentState]];
	}
	NSMutableArray *modifierCombinations = [NSMutableArray arrayWithCapacity:[modifierIndices count]];
	if (_allModifiers) {
		for (NSNumber *modifierIndex in modifierIndices) {
			NSUInteger index = [modifierIndex unsignedIntegerValue];
			NSUInteger modifierCombination = [keyboardObject modifiersForIndex:index forKeyboard:currentKeyboard];
			[modifierCombinations addObject:@(modifierCombination)];
		}
	}
	else {
		[modifierCombinations addObject:@([[self parentDocument] currentModifiers])];
	}
		// Remove old views
	for (NSInteger i = [keyboardViews count] - 1; i >= 0; i--) {
		NSView *subView = keyboardViews[i];
		[keyboardViews removeObjectAtIndex:i];
		[subView removeFromSuperview];
	}
	for (NSInteger i = [labelViews count] - 1; i >= 0; i--) {
		NSView *subView = labelViews[i];
		[labelViews removeObjectAtIndex:i];
		[subView removeFromSuperview];
	}
		// Build new views
	[self setFrame:NSMakeRect(0, 0, [self bounds].size.width, keyboardCount * (keyboardHeight + kLabelViewHeight))];
	[self setBounds:[self frame]];
	CGFloat pageWidth = [self bounds].size.width;
	CGFloat currentPosition = [self bounds].size.height;
	[keyboardPlaceHolders removeAllObjects];
	for (NSString *stateName in stateNames) {
		for (NSNumber *modifierCombination in modifierCombinations) {
				// Create the placeholder for the keyboard view (which will be created as needed)
			KeyboardViewPlaceHolder *placeHolder = [[KeyboardViewPlaceHolder alloc] init];
			[placeHolder setOrigin:NSMakePoint(0, currentPosition - keyboardHeight)];
			[placeHolder setStateName:stateName];
			[placeHolder setModifierCombination:[modifierCombination unsignedIntegerValue]];
			[keyboardPlaceHolders addObject:placeHolder];
			currentPosition -= keyboardHeight;
				// Create the label view
			NSTextView *labelView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, currentPosition - kLabelViewHeight, pageWidth, kLabelViewHeight)];
			NSString *labelText = [NSString stringWithFormat:@"State: %@", stateName];
			[labelView setString:labelText];
			[labelView setAlignment:NSCenterTextAlignment];
			[self addSubview:labelView];
			[labelViews addObject:labelView];
			currentPosition -= kLabelViewHeight;
		}
	}
}

- (void)setKeyboardOutput:(UkeleleView *)keyboardView
				   withID:(NSUInteger)keyboardID
				 forState:(NSString *)stateName
				modifiers:(NSUInteger)modifiers {
	NSArray *subViews = [keyboardView keyCapViews];
    NSMutableDictionary *keyDataDict = [NSMutableDictionary dictionary];
    keyDataDict[kKeyKeyboardID] = @(keyboardID);
    keyDataDict[kKeyKeyCode] = @0;
    keyDataDict[kKeyModifiers] = @(modifiers);
    keyDataDict[kKeyState] = stateName;
	UkeleleKeyboardObject *keyboardLayout = [[self parentDocument] keyboardLayout];
	for (KeyCapView *keyCapView in subViews) {
		NSInteger keyCode = [keyCapView keyCode];
		if (modifiers & NSNumericPadKeyMask) {
			keyCode = [keyCapView fnKeyCode];
		}
		NSString *output;
		BOOL deadKey;
		NSString *nextState;
        keyDataDict[kKeyKeyCode] = @(keyCode);
		output = [keyboardLayout getCharOutput:keyDataDict isDead:&deadKey nextState:&nextState];
		[keyCapView setOutputString:output];
		[keyCapView setDeadKey:deadKey];
	}
	[keyboardView updateModifiers:(unsigned int)modifiers];
}

- (BOOL)knowsPageRange:(NSRangePointer)range {
	range->location = 1;
	range->length = [self pageCount];
	return YES;
}

- (NSRect)rectForPage:(NSInteger)page {
	ColourTheme *printColourTheme = [ColourTheme defaultPrintTheme];
	NSRect pageRect = [self bounds];
	NSInteger totalPages = [self pageCount];
	NSInteger totalKeyboards = [keyboardPlaceHolders count];
	NSInteger keyboardsThisPage = keyboardsPerPage;
	if (page == totalPages && totalKeyboards % keyboardsPerPage != 0) {
		keyboardsThisPage = totalKeyboards % keyboardsPerPage;
	}
		// See whether we have already created the keyboard views for this page
	NSInteger firstKeyboard = (page - 1) * keyboardsPerPage;
	NSUInteger currentKeyboard = [[self parentDocument] keyboardID];
	CGFloat pageWidth = [self bounds].size.width;
	for (NSInteger i = 0; i < keyboardsThisPage; i++) {
		KeyboardViewPlaceHolder *placeHolder = keyboardPlaceHolders[firstKeyboard + i];
		if (nil == [placeHolder keyboardView]) {
				// Create the keyboard view, as we need it now
			UkeleleView *keyboardView = [[UkeleleView alloc] init];
			[keyboardView setColourTheme:printColourTheme];
			[keyboardView createViewWithKeyboardID:(int)currentKeyboard withScale:1];
			NSRect keyboardFrame = [keyboardView frame];
			[keyboardView scaleViewToScale:pageWidth / keyboardFrame.size.width limited:NO];
			[keyboardView setFrameOrigin:[placeHolder origin]];
			[self addSubview:keyboardView];
			[keyboardViews addObject:keyboardView];
			[placeHolder setKeyboardView:keyboardView];
				// Set the keyboard view to have the correct state and modifiers
			[self setKeyboardOutput:keyboardView withID:currentKeyboard forState:[placeHolder stateName] modifiers:[placeHolder modifierCombination]];
		}
	}
	NSInteger keyboardsBelow = 0;
	if (page < totalPages) {
			// We have the number of keyboards on the last page
		keyboardsBelow = totalKeyboards % keyboardsPerPage;
		if (keyboardsBelow == 0) {
			keyboardsBelow = keyboardsPerPage;
		}
			// And then the number of keyboards per page between our page and the last
		keyboardsBelow += (totalPages - page - 1) * keyboardsPerPage;
	}
	pageRect.origin.y = keyboardsBelow * (keyboardHeight + kLabelViewHeight);
	pageRect.size.height = keyboardsThisPage * (keyboardHeight + kLabelViewHeight);
	return pageRect;
}

@end

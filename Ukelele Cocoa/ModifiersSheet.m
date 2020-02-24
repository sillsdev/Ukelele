//
//  ModifiersSheet.m
//  Ukelele 3
//
//  Created by John Brownie on 18/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "ModifiersSheet.h"

@implementation ModifiersInfo

- (instancetype)init
{
    self = [super init];
    if (self) {
        _keyMapIndex = 0;
        _keyMapSubindex = 0;
        _shiftValue = kModifierNone;
        _capsLockValue = kModifierNotPressed;
        _optionValue = kModifierNone;
        _commandValue = kModifierNotPressed;
        _controlValue = kModifierNone;
        _existingOrNewValue = kModifiersNewIndex;
    }
    return self;
}

- (BOOL)modifiersAreEqualTo:(ModifiersInfo *)compareTo
{
	return [self keyMapIndex] == [compareTo keyMapIndex] &&
        [self keyMapSubindex] == [compareTo keyMapSubindex] &&
        [self shiftValue] == [compareTo shiftValue] &&
		[self capsLockValue] == [compareTo capsLockValue] &&
		[self optionValue] == [compareTo optionValue] &&
		[self commandValue] == [compareTo commandValue] &&
		[self controlValue] == [compareTo controlValue];
}

- (id)copyWithZone:(NSZone *)zone
{
    ModifiersInfo *theCopy = [[ModifiersInfo allocWithZone:zone] init];
    [theCopy setKeyMapIndex:[self keyMapIndex]];
    [theCopy setKeyMapSubindex:[self keyMapSubindex]];
    [theCopy setShiftValue:[self shiftValue]];
    [theCopy setCapsLockValue:[self capsLockValue]];
    [theCopy setOptionValue:[self optionValue]];
    [theCopy setCommandValue:[self commandValue]];
    [theCopy setControlValue:[self controlValue]];
    [theCopy setExistingOrNewValue:[self existingOrNewValue]];
    return theCopy;
}

@end

static NSString *nibWindowName = @"AddModifiersDialog";
static NSString *nibSimplifiedWindowName = @"SimplifiedModifiersDialog";
static NSMenu *choiceMenu = nil;

enum {
	notPressedColumn = 0,
	pressedColumn = 1,
	eitherColumn = 2
};

enum {
	togetherRow = 0,
	separateRow = 1
};

@implementation ModifiersSheet

@synthesize shiftTogether;
@synthesize shiftLeft;
@synthesize shiftRight;
@synthesize capsLock;
@synthesize optionTogether;
@synthesize optionLeft;
@synthesize optionRight;
@synthesize command;
@synthesize controlTogether;
@synthesize controlLeft;
@synthesize controlRight;
@synthesize existingOrNewIndex;
@synthesize shiftPopup;
@synthesize capsLockPopup;
@synthesize optionPopup;
@synthesize commandPopup;
@synthesize controlPopup;
@synthesize existingOrNewIndexSimplified;
@synthesize simplifiedWindow;

#pragma mark Marshal data

- (void)setDoubleModifier:(NSInteger)value
					 left:(NSMatrix *)leftModifier
					right:(NSMatrix *)rightModifier
				 together:(NSMatrix *)togetherRadio
{
	switch (value) {
		case kModifierNone:
		case kModifierAny:
		case kModifierAnyOpt:
			[togetherRadio selectCellAtRow:togetherRow column:0];
			[rightModifier setEnabled:NO];
			break;

		default:
			[togetherRadio selectCellAtRow:separateRow column:0];
			[rightModifier setEnabled:YES];
			break;
	}
	switch (value) {
		case kModifierNone:
			[leftModifier selectCellAtRow:0 column:notPressedColumn];
			break;
			
		case kModifierAny:
			[leftModifier selectCellAtRow:0 column:pressedColumn];
			break;
			
		case kModifierAnyOpt:
			[leftModifier selectCellAtRow:0 column:eitherColumn];
			break;

		case kModifierLeft:
			[leftModifier selectCellAtRow:0 column:pressedColumn];
			[rightModifier selectCellAtRow:0 column:notPressedColumn];
			break;

		case kModifierLeftOpt:
			[leftModifier selectCellAtRow:0 column:eitherColumn];
			[rightModifier selectCellAtRow:0 column:notPressedColumn];
			break;

		case kModifierRight:
			[leftModifier selectCellAtRow:0 column:notPressedColumn];
			[rightModifier selectCellAtRow:0 column:pressedColumn];
			break;

		case kModifierRightOpt:
			[leftModifier selectCellAtRow:0 column:notPressedColumn];
			[rightModifier selectCellAtRow:0 column:eitherColumn];
			break;

		case kModifierLeftRight:
			[leftModifier selectCellAtRow:0 column:pressedColumn];
			[rightModifier selectCellAtRow:0 column:pressedColumn];
			break;

		case kModifierLeftOptRight:
			[leftModifier selectCellAtRow:0 column:eitherColumn];
			[rightModifier selectCellAtRow:0 column:pressedColumn];
			break;

		case kModifierLeftRightOpt:
			[leftModifier selectCellAtRow:0 column:pressedColumn];
			[rightModifier selectCellAtRow:0 column:eitherColumn];
			break;
	}
}

- (void)setSingleModifier:(NSInteger)value radio:(NSMatrix *)radioButton
{
	switch (value) {
		case kModifierEither:
			[radioButton selectCellAtRow:0 column:eitherColumn];
			break;
			
		case kModifierPressed:
			[radioButton selectCellAtRow:0 column:pressedColumn];
			break;
			
		case kModifierNotPressed:
			[radioButton selectCellAtRow:0 column:notPressedColumn];
			break;
	}
}

- (NSInteger)getDoubleModifier:(NSMatrix *)togetherRadio
						  left:(NSMatrix *)leftModifier
						 right:(NSMatrix *)rightModifier
{
	switch ([togetherRadio selectedRow]) {
		case togetherRow:
			switch ([leftModifier selectedColumn]) {
				case pressedColumn:
					return kModifierAny;
					
				case notPressedColumn:
					return kModifierNone;
					
				case eitherColumn:
					return kModifierAnyOpt;
			}
			break;
			
		case separateRow:
			switch ([leftModifier selectedColumn]) {
				case pressedColumn:
					switch ([rightModifier selectedColumn]) {
						case pressedColumn:
							return kModifierLeftRight;
							
						case notPressedColumn:
							return kModifierLeft;
							
						case eitherColumn:
							return kModifierLeftRightOpt;
					}
					break;
					
				case notPressedColumn:
					switch ([rightModifier selectedColumn]) {
						case pressedColumn:
							return kModifierRight;

						case notPressedColumn:
							return kModifierNone;
							
						case eitherColumn:
							return kModifierRightOpt;
					}
					break;
					
				case eitherColumn:
					switch ([rightModifier selectedColumn]) {
						case pressedColumn:
							return kModifierLeftOptRight;

						case notPressedColumn:
							return kModifierLeftOpt;
							
						case eitherColumn:
							return kModifierAnyOpt;
					}
					break;
			}
			break;
	}
	return 0;
}

- (NSInteger)getSingleModifier:(NSMatrix *)radioButton
{
	switch ([radioButton selectedColumn]) {
		case pressedColumn:
			return kModifierPressed;

		case notPressedColumn:
			return kModifierNotPressed;
			
		case eitherColumn:
			return kModifierEither;
	}
	return 0;
}

- (void)setPopupMenuItem:(NSPopUpButton *)button withStatus:(NSInteger)status
{
    switch (status) {
        case kModifierNone:
        case kModifierNotPressed:
            [button selectItemAtIndex:0];
            break;
            
        case kModifierAny:
        case kModifierPressed:
            [button selectItemAtIndex:1];
            break;
            
        case kModifierAnyOpt:
        case kModifierEither:
            [button selectItemAtIndex:2];
            break;
    }
}

- (NSInteger)getSingleModifierFromButton:(NSPopUpButton *)button
{
    NSInteger status = kModifierNotPressed;
    switch ([button indexOfSelectedItem]) {
        case 0:
            status = kModifierNotPressed;
            break;
            
        case 1:
            status = kModifierPressed;
            break;
            
        case 2:
            status = kModifierEither;
            break;
    }
    return status;
}

- (NSInteger)getDoubleModifierFromButton:(NSPopUpButton *)button
{
    NSInteger status = kModifierNone;
    switch ([button indexOfSelectedItem]) {
        case 0:
            status = kModifierNone;
            break;
            
        case 1:
            status = kModifierAny;
            break;
            
        case 2:
            status = kModifierAnyOpt;
            break;
    }
    return status;
}

#pragma mark Initialisation

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:nibWindowName owner:self topLevelObjects:nil];
	self = [super initWithWindowNibName:windowNibName];
	if (self) {
			// Nothing to do?
	}
	return self;
}

+ (ModifiersSheet *)modifiersSheet:(ModifiersInfo *)modifierInfo
{
	ModifiersSheet *theSheet = [[ModifiersSheet alloc] initWithWindowNibName:nibWindowName];
	NSInteger theValue = [modifierInfo shiftValue];
	[theSheet setDoubleModifier:theValue
						   left:theSheet.shiftLeft
						  right:theSheet.shiftRight
					   together:theSheet.shiftTogether];
	theValue = [modifierInfo capsLockValue];
	[theSheet setSingleModifier:theValue radio:theSheet.capsLock];
	theValue = [modifierInfo optionValue];
	[theSheet setDoubleModifier:theValue
						   left:theSheet.optionLeft
						  right:theSheet.optionRight
					   together:theSheet.optionTogether];
	theValue = [modifierInfo commandValue];
	[theSheet setSingleModifier:theValue radio:theSheet.command];
	theValue = [modifierInfo controlValue];
	[theSheet setDoubleModifier:theValue
						   left:theSheet.controlLeft
						  right:theSheet.controlRight
					   together:theSheet.controlTogether];
	theValue = [modifierInfo existingOrNewValue];
    NSMatrix *matrixItem = [theSheet existingOrNewIndex];
	[matrixItem selectCellAtRow:theValue column:0];
    [theSheet setIsSimplified:NO];
	return theSheet;
}

+ (ModifiersSheet *)simplifiedModifiersSheet:(ModifiersInfo *)modifierInfo
{
    ModifiersSheet *theSheet = [[ModifiersSheet alloc] initWithWindowNibName:nibSimplifiedWindowName];
    if (choiceMenu == nil) {
        choiceMenu = [[NSMenu alloc] init];
        [choiceMenu addItemWithTitle:@"Up" action:nil keyEquivalent:@""];
        [choiceMenu addItemWithTitle:@"Down" action:nil keyEquivalent:@""];
        [choiceMenu addItemWithTitle:@"Either Up or Down" action:nil keyEquivalent:@""];
    }
    [theSheet.shiftPopup setMenu:[choiceMenu copy]];
    [theSheet setPopupMenuItem:theSheet.shiftPopup withStatus:[modifierInfo shiftValue]];
    [theSheet.capsLockPopup setMenu:[choiceMenu copy]];
    [theSheet setPopupMenuItem:theSheet.capsLockPopup withStatus:[modifierInfo capsLockValue]];
    [theSheet.optionPopup setMenu:[choiceMenu copy]];
    [theSheet setPopupMenuItem:theSheet.optionPopup withStatus:[modifierInfo optionValue]];
    [theSheet.commandPopup setMenu:[choiceMenu copy]];
    [theSheet setPopupMenuItem:theSheet.commandPopup withStatus:[modifierInfo commandValue]];
    [theSheet.controlPopup setMenu:[choiceMenu copy]];
    [theSheet setPopupMenuItem:theSheet.controlPopup withStatus:[modifierInfo controlValue]];
    [theSheet.existingOrNewIndexSimplified selectCellAtRow:[modifierInfo existingOrNewValue] column:0];
    [theSheet setIsSimplified:YES];
    return theSheet;
}

- (void)beginModifiersSheetWithCallback:(void (^)(ModifiersInfo *))theCallback
								  isNew:(BOOL)creatingNew
						 canBeSameIndex:(BOOL)canBeSame
							  forWindow:(NSWindow *)parentWindow
{
	[existingOrNewIndex setHidden:!creatingNew];
	if (creatingNew) {
		[existingOrNewIndex setEnabled:canBeSame];
	}
	callBack = theCallback;
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (void)beginSimplifiedModifiersSheetWithCallback:(void (^)(ModifiersInfo *))theCallback
											isNew:(BOOL)creatingNew
								   canBeSameIndex:(BOOL)canBeSame
										forWindow:(NSWindow *)parentWindow
{
	[existingOrNewIndexSimplified setHidden:!creatingNew];
	if (creatingNew) {
		[existingOrNewIndexSimplified setEnabled:canBeSame];
	}
	callBack = theCallback;
	[parentWindow beginSheet:[self simplifiedWindow] completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

#pragma mark Actions

- (IBAction)shiftTogetherChoice:(id)sender
{
#pragma unused(sender)
	[shiftRight setEnabled:[shiftTogether selectedRow] == 1];
}

- (IBAction)optionTogetherChoice:(id)sender
{
#pragma unused(sender)
	[optionRight setEnabled:[optionTogether selectedRow] == 1];
}

- (IBAction)controlTogetherChoice:(id)sender
{
#pragma unused(sender)
	[controlRight setEnabled:[controlTogether selectedRow] == 1];
}

- (IBAction)acceptModifiers:(id)sender
{
#pragma unused(sender)
	ModifiersInfo *modifierInfo = [[ModifiersInfo alloc] init];
    if ([self isSimplified]) {
        [modifierInfo setShiftValue:[self getDoubleModifierFromButton:shiftPopup]];
        [modifierInfo setCapsLockValue:[self getSingleModifierFromButton:capsLockPopup]];
        [modifierInfo setOptionValue:[self getDoubleModifierFromButton:optionPopup]];
        [modifierInfo setCommandValue:[self getSingleModifierFromButton:commandPopup]];
        [modifierInfo setControlValue:[self getDoubleModifierFromButton:controlPopup]];
        if ([existingOrNewIndexSimplified isEnabled]) {
            [modifierInfo setExistingOrNewValue:[existingOrNewIndexSimplified selectedRow]];
        }
    }
    else {
        [modifierInfo setShiftValue:[self getDoubleModifier:shiftTogether left:shiftLeft right:shiftRight]];
        [modifierInfo setCapsLockValue:[self getSingleModifier:capsLock]];
        [modifierInfo setOptionValue:[self getDoubleModifier:optionTogether left:optionLeft right:optionRight]];
        [modifierInfo setCommandValue:[self getSingleModifier:command]];
        [modifierInfo setControlValue:[self getDoubleModifier:controlTogether left:controlLeft right:controlRight]];
        if ([existingOrNewIndex isEnabled]) {
            [modifierInfo setExistingOrNewValue:[existingOrNewIndex selectedRow]];
        }
    }
    NSWindow *myWindow = [self isSimplified] ? [self simplifiedWindow] : [self window];
	[myWindow orderOut:self];
	[NSApp endSheet:myWindow];
	callBack(modifierInfo);
}

- (IBAction)cancelModifiers:(id)sender
{
#pragma unused(sender)
    NSWindow *myWindow = [self isSimplified] ? [self simplifiedWindow] : [self window];
	[myWindow orderOut:self];
	[NSApp endSheet:myWindow];
	callBack(nil);
}

@end

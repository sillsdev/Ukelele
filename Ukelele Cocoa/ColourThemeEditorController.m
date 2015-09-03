//
//  ColourThemeEditorController.m
//  Ukelele 3
//
//  Created by John Brownie on 14/11/13.
//
//

#import "ColourThemeEditorController.h"
#import "ColourTheme.h"
#import "UkeleleConstants.h"
#import "UkeleleConstantStrings.h"
#import "UKStyleInfo.h"
#import "AskTextViewController.h"

typedef enum UKKeyTypeStatus: NSUInteger {
	normalUnselectedUp = 0,
	normalUnselectedDown = 1,
	normalSelectedUp = 2,
	normalSelectedDown = 3,
	deadKeyUnselectedUp = 4,
	deadKeyUnselectedDown = 5,
	deadKeySelectedUp = 6,
	deadKeySelectedDown = 7,
	noKeyStatus = 99
} UKKeyTypeStatus;

typedef enum : NSUInteger {
	changingNothing,
	changingInnerColour,
	changingOuterColour,
	changingTextColour
} UKColourThemeChangeStatus;

#define kDefaultFontName	@"Lucida Grande"
#define kDefaultFontSize	18.0

@interface ColourThemeEditorController ()

@end

@implementation ColourThemeEditorController {
	ColourTheme *currentTheme;
	UKKeyTypeStatus currentKeyTypeStatus;
	NSWindow *theWindow;
	void (^completionBlock)(NSString *);
	UKStyleInfo *styleInfo;
	NSUndoManager *undoManager;
//	BOOL hasUndoGroup;
//	UKColourThemeChangeStatus changeStatus;
//	UKKeyTypeStatus changeTarget;
	NSPopover *editPopover;
	AskTextViewController *askTextController;
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"ColourThemeEditor" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
		currentKeyTypeStatus = noKeyStatus;
		currentTheme = nil;
		completionBlock = nil;
		undoManager = [[NSUndoManager alloc] init];
//		hasUndoGroup = NO;
//		changeStatus = changingNothing;
//		changeTarget = noKeyStatus;
		editPopover = nil;
		askTextController = nil;
		_normalUp.tag = 0;
		_deadKeyUp.tag = 1;
		_selectedUp.tag = 2;
		_selectedDeadUp.tag = 3;
		_normalDown.tag = 4;
		_deadKeyDown.tag = 5;
		_selectedDown.tag = 6;
		_selectedDeadDown.tag = 7;
		styleInfo = [[UKStyleInfo alloc] init];
		NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
		NSString *defaultFontName = [theDefaults stringForKey:UKTextFont];
		if (defaultFontName == nil || defaultFontName.length == 0) {
				// Nothing came from the defaults
			defaultFontName = kDefaultFontName;
		}
		CGFloat textSize = [theDefaults floatForKey:UKTextSize];
		if (textSize <= 0) {
				// Nothing came from the defaults
			textSize = kDefaultFontSize;
		}
		CTFontDescriptorRef fontDescriptor = CTFontDescriptorCreateWithNameAndSize((__bridge CFStringRef)defaultFontName, textSize);
		[styleInfo setFontDescriptor:fontDescriptor];
		[self.normalUp setStyleInfo:styleInfo];
		[self.deadKeyUp setStyleInfo:styleInfo];
		[self.selectedUp setStyleInfo:styleInfo];
		[self.selectedDeadUp setStyleInfo:styleInfo];
		[self.normalDown setStyleInfo:styleInfo];
		[self.deadKeyDown setStyleInfo:styleInfo];
		[self.selectedDown setStyleInfo:styleInfo];
		[self.selectedDeadDown setStyleInfo:styleInfo];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

+ (ColourThemeEditorController *)colourThemeEditorController {
	return [[ColourThemeEditorController alloc] initWithWindowNibName:@"ColourThemeEditor"];
}

- (void)showColourThemesWithWindow:(NSWindow *)parentWindow completionBlock:(void (^)(NSString *))theBlock {
	currentTheme = [ColourTheme currentColourTheme];
	if (currentTheme == nil) {
			// No current theme, so use the default one
		NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
		NSString *defaultTheme = [theDefaults stringForKey:UKColourTheme];
		if (defaultTheme == nil || [defaultTheme length] == 0 || ![ColourTheme themeExistsWithName:defaultTheme]) {
			defaultTheme = kDefaultThemeName;
		}
		currentTheme = [ColourTheme colourThemeNamed:defaultTheme];
	}
	NSString *currentColourTheme = [currentTheme themeName];
	[self.themeList removeAllItems];
	NSArray *allThemes = [[ColourTheme allColourThemes] allObjects];
	[self.themeList addItemsWithTitles:[allThemes sortedArrayUsingSelector:@selector(localizedStandardCompare:)]];
	[self.themeList selectItemWithTitle:currentColourTheme];
	theWindow = parentWindow;
	completionBlock = theBlock;
	if (parentWindow) {
			// Run as a sheet
		[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
	}
	else {
			// Run as a window
		[self.window setIsVisible:YES];
	}
	[self activateTheme:currentColourTheme];
	[self.deleteButton setEnabled:!([currentColourTheme isEqualToString:kDefaultThemeName] || [currentColourTheme isEqualToString:kPrintThemeName])];
	[ColourTheme saveCurrentColourThemes];
}

#pragma mark User actions

- (IBAction)selectColourTheme:(id)sender {
	NSString *themeName = [sender title];
	if (![themeName isEqualToString:[currentTheme themeName]]) {
		[self activateTheme:themeName];
	}
	[self.deleteButton setEnabled:!([themeName isEqualToString:kDefaultThemeName] || [themeName isEqualToString:kPrintThemeName])];
}

- (IBAction)newColourTheme:(id)sender {
	if (editPopover == nil) {
		editPopover = [[NSPopover alloc] init];
	}
	if (askTextController == nil) {
		askTextController = [AskTextViewController askViewText];
	}
	[editPopover setDelegate:self];
	[editPopover setContentViewController:askTextController];
	[editPopover setBehavior:NSPopoverBehaviorTransient];
	[askTextController setMyPopover:editPopover];
	__weak ColourThemeEditorController *weakSelf = self;
	[askTextController setupPopoverWithText:@"Enter the name of the new colour theme" callback:^(NSString *nameString) {
		if (nameString) {
				// Accept the name
			[weakSelf createNewThemeNamed:nameString];
		}
	}];
	[editPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
	[askTextController.messageField setStringValue:@"Enter the name of the new colour theme:"];
}

- (IBAction)deleteColourTheme:(id)sender {
#pragma unused(sender)
	NSString *themeName = [self.themeList titleOfSelectedItem];
	if ([themeName isEqualToString:kDefaultThemeName] || [themeName isEqualToString:kPrintThemeName]) {
			// Can't delete the required themes
		return;
	}
	[self deleteThemeNamed:themeName];
}

- (IBAction)renameColourTheme:(id)sender {
	if (editPopover == nil) {
		editPopover = [[NSPopover alloc] init];
	}
	if (askTextController == nil) {
		askTextController = [AskTextViewController askViewText];
	}
	[editPopover setDelegate:self];
	[editPopover setContentViewController:askTextController];
	[editPopover setBehavior:NSPopoverBehaviorTransient];
	[askTextController setMyPopover:editPopover];
	__weak ColourThemeEditorController *weakSelf = self;
	[askTextController setCallBack:^(NSString *themeName) {
		[weakSelf acceptThemeName:themeName];
	}];
	[askTextController setInvalidStrings:[ColourTheme allColourThemes]];
	[askTextController setWarningString:@"That name is in use. Please enter a new name."];
	[editPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
	[askTextController.messageField setStringValue:@"Enter a new name for the colour theme:"];
}

- (IBAction)setGradient:(id)sender {
#pragma unused(sender)
	unsigned int newGradientType = (unsigned int)[[self.gradientType selectedCell] tag];
	[self setNewGradientType:newGradientType forKeyType:currentKeyTypeStatus];
}

- (IBAction)acceptColourTheme:(id)sender {
#pragma unused(sender)
//	if (hasUndoGroup) {
//		[undoManager endUndoGrouping];
//		NSLog(@"End undo group");
//		hasUndoGroup = NO;
//	}
	[self saveTheme];
	[self.window orderOut:self];
	if (theWindow) {
		[NSApp endSheet:self.window];
	}
	completionBlock([currentTheme themeName]);
}

- (IBAction)revertColourThemes:(id)sender {
#pragma unused(sender)
	[self.window orderOut:self];
	if (theWindow) {
		[NSApp endSheet:self.window];
	}
	[ColourTheme restoreColourThemes];
	completionBlock(nil);
}

- (void)acceptThemeName:(NSString *)theName {
	[self renameThemeNamed:[currentTheme themeName] to:theName];
}

#pragma mark Events

- (void)handleKeyCapClick:(KeyCapView *)keyCapView clickCount:(NSInteger)clickCount {
#pragma unused(clickCount)
	[self.normalUpSelection setSelected:NO];
	[self.normalDownSelection setSelected:NO];
	[self.deadKeyUpSelection setSelected:NO];
	[self.deadKeyDownSelection setSelected:NO];
	[self.selectedUpSelection setSelected:NO];
	[self.selectedDownSelection setSelected:NO];
	[self.selectedDeadUpSelection setSelected:NO];
	[self.selectedDeadDownSelection setSelected:NO];
	switch ([keyCapView tag]) {
		case 0:
			[self.normalUpSelection setSelected:YES];
			currentKeyTypeStatus = normalUnselectedUp;
			break;
			
		case 1:
			[self.deadKeyUpSelection setSelected:YES];
			currentKeyTypeStatus = deadKeyUnselectedUp;
			break;
			
		case 2:
			[self.selectedUpSelection setSelected:YES];
			currentKeyTypeStatus = normalSelectedUp;
			break;
			
		case 3:
			[self.selectedDeadUpSelection setSelected:YES];
			currentKeyTypeStatus = deadKeySelectedUp;
			break;
			
		case 4:
			[self.normalDownSelection setSelected:YES];
			currentKeyTypeStatus = normalUnselectedDown;
			break;
			
		case 5:
			[self.deadKeyDownSelection setSelected:YES];
			currentKeyTypeStatus = deadKeyUnselectedDown;
			break;
			
		case 6:
			[self.selectedDownSelection setSelected:YES];
			currentKeyTypeStatus = normalSelectedDown;
			break;
			
		case 7:
			[self.selectedDeadDownSelection setSelected:YES];
			currentKeyTypeStatus = deadKeySelectedDown;
			break;
			
		default:
			NSLog(@"Unknown tag %ld", [keyCapView tag]);
			break;
	}
	[self loadColours];
}

- (IBAction)changeInnerColour:(id)sender {
//	if (hasUndoGroup && (changeStatus != changingInnerColour || changeTarget != currentKeyTypeStatus)) {
//			// We have a set of undos which are for something else, so end it and start a new one
//		[self completeUndoGroup];
//		[undoManager beginUndoGrouping];
//		NSLog(@"Begin undo group");
//		hasUndoGroup = YES;
//		changeStatus = changingInnerColour;
//		changeTarget = currentKeyTypeStatus;
//	}
//	else if (!hasUndoGroup) {
//			// No undo group, start a new one
//		[undoManager beginUndoGrouping];
//		NSLog(@"Begin undo group");
//		hasUndoGroup = YES;
//		changeStatus = changingInnerColour;
//		changeTarget = currentKeyTypeStatus;
//	}
	if (currentKeyTypeStatus != noKeyStatus) {
		[self setNewInnerColour:[sender color] forKeyType:currentKeyTypeStatus];
	}
}

- (IBAction)changeOuterColour:(id)sender {
//	if (hasUndoGroup && (changeStatus != changingOuterColour || changeTarget != currentKeyTypeStatus)) {
//			// We have a set of undos which are for something else, so end it and start a new one
//		[self completeUndoGroup];
//		[undoManager beginUndoGrouping];
//		NSLog(@"Begin undo group");
//		changeStatus = changingOuterColour;
//		changeTarget = currentKeyTypeStatus;
//	}
//	else if (!hasUndoGroup) {
//			// No undo group, start a new one
//		[undoManager beginUndoGrouping];
//		NSLog(@"Begin undo group");
//		hasUndoGroup = YES;
//		changeStatus = changingOuterColour;
//		changeTarget = currentKeyTypeStatus;
//	}
	if (currentKeyTypeStatus != noKeyStatus) {
		[self setNewOuterColour:[sender color] forKeyType:currentKeyTypeStatus];
	}
}

- (IBAction)changeTextColour:(id)sender {
//	if (hasUndoGroup && (changeStatus != changingTextColour || changeTarget != currentKeyTypeStatus)) {
//			// We have a set of undos which are for something else, so end it and start a new one
//		[self completeUndoGroup];
//		[undoManager beginUndoGrouping];
//		NSLog(@"Begin undo group");
//		changeStatus = changingTextColour;
//		hasUndoGroup = YES;
//		changeTarget = currentKeyTypeStatus;
//	}
//	else if (!hasUndoGroup) {
//			// No undo group, start a new one
//		[undoManager beginUndoGrouping];
//		NSLog(@"Begin undo group");
//		changeStatus = changingTextColour;
//		hasUndoGroup = YES;
//		changeTarget = currentKeyTypeStatus;
//	}
	if (currentKeyTypeStatus != noKeyStatus) {
		[self setNewTextColour:[sender color] forKeyType:currentKeyTypeStatus];
	}
}

#pragma mark Undoable actions

- (void)completeUndoGroup {
//	if (hasUndoGroup) {
//		hasUndoGroup = NO;
//		[undoManager endUndoGrouping];
//		NSLog(@"End undo group");
//		switch (changeStatus) {
//			case changingNothing:
//					// Nothing to do
//				break;
//				
//			case changingTextColour:
//			case changingInnerColour:
//			case changingOuterColour:
//				[self saveTheme];
//				break;
//		}
//		changeStatus = changingNothing;
//		changeTarget = noKeyStatus;
//	}
}

- (void)setNewInnerColour:(NSColor *)newColour forKeyType:(NSInteger)keyType {
	NSColor *oldColour = nil;
	NSUInteger theGradientType = gradientTypeRadial;
	switch (keyType) {
		case normalUnselectedUp:
			oldColour = [currentTheme normalUpInnerColour];
			[currentTheme setNormalUpInnerColour:newColour];
			theGradientType = [currentTheme normalGradientType];
			break;
			
		case deadKeyUnselectedUp:
			oldColour = [currentTheme deadKeyUpInnerColour];
			[currentTheme setDeadKeyUpInnerColour:newColour];
			theGradientType = [currentTheme deadKeyGradientType];
			break;
			
		case normalSelectedUp:
			oldColour = [currentTheme selectedUpInnerColour];
			[currentTheme setSelectedUpInnerColour:newColour];
			theGradientType = [currentTheme selectedGradientType];
			break;
			
		case deadKeySelectedUp:
			oldColour = [currentTheme selectedDeadUpInnerColour];
			[currentTheme setSelectedDeadUpInnerColour:newColour];
			theGradientType = [currentTheme selectedDeadGradientType];
			break;
			
		case normalUnselectedDown:
			oldColour = [currentTheme normalDownInnerColour];
			[currentTheme setNormalDownInnerColour:newColour];
			theGradientType = [currentTheme normalDownGradientType];
			break;
			
		case deadKeyUnselectedDown:
			oldColour = [currentTheme deadKeyDownInnerColour];
			[currentTheme setDeadKeyDownInnerColour:newColour];
			theGradientType = [currentTheme deadKeyDownGradientType];
			break;
			
		case normalSelectedDown:
			oldColour = [currentTheme selectedDownInnerColour];
			[currentTheme setSelectedDownInnerColour:newColour];
			theGradientType = [currentTheme selectedDownGradientType];
			break;
			
		case deadKeySelectedDown:
			oldColour = [currentTheme selectedDeadDownInnerColour];
			[currentTheme setSelectedDeadDownInnerColour:newColour];
			theGradientType = [currentTheme selectedDeadDownGradientType];
			break;
			
		default:
			NSLog(@"Unknown key type %ld!", keyType);
			break;
	}
	[self saveTheme];
	[self loadColours];
	[self refreshCurrentKeyCap];
	NSAssert(oldColour != nil, @"Must have the old colour");
	NSString *actionName = @"Set Inner Colour";
	if (theGradientType == gradientTypeNone) {
		actionName = @"Set Fill Colour";
	}
	else if (theGradientType == gradientTypeLinear) {
		actionName = @"Set Top Colour";
	}
	[[undoManager prepareWithInvocationTarget:self] setNewInnerColour:oldColour forKeyType:keyType];
	[undoManager setActionName:actionName];
}

- (void)setNewOuterColour:(NSColor *)newColour forKeyType:(NSInteger)keyType {
	NSColor *oldColour = nil;
	NSUInteger theGradientType = gradientTypeRadial;
	switch (keyType) {
		case normalUnselectedUp:
			oldColour = [currentTheme normalUpOuterColour];
			[currentTheme setNormalUpOuterColour:newColour];
			theGradientType = [currentTheme normalGradientType];
			break;
			
		case deadKeyUnselectedUp:
			oldColour = [currentTheme deadKeyUpOuterColour];
			[currentTheme setDeadKeyUpOuterColour:newColour];
			theGradientType = [currentTheme deadKeyGradientType];
			break;
			
		case normalSelectedUp:
			oldColour = [currentTheme selectedUpOuterColour];
			[currentTheme setSelectedUpOuterColour:newColour];
			theGradientType = [currentTheme selectedGradientType];
			break;
			
		case deadKeySelectedUp:
			oldColour = [currentTheme selectedDeadUpOuterColour];
			[currentTheme setSelectedDeadUpOuterColour:newColour];
			theGradientType = [currentTheme selectedDeadGradientType];
			break;
			
		case normalUnselectedDown:
			oldColour = [currentTheme normalDownOuterColour];
			[currentTheme setNormalDownOuterColour:newColour];
			theGradientType = [currentTheme normalDownGradientType];
			break;
			
		case deadKeyUnselectedDown:
			oldColour = [currentTheme deadKeyDownOuterColour];
			[currentTheme setDeadKeyDownOuterColour:newColour];
			theGradientType = [currentTheme deadKeyDownGradientType];
			break;
			
		case normalSelectedDown:
			oldColour = [currentTheme selectedDownOuterColour];
			[currentTheme setSelectedDownOuterColour:newColour];
			theGradientType = [currentTheme selectedDownGradientType];
			break;
			
		case deadKeySelectedDown:
			oldColour = [currentTheme selectedDeadDownOuterColour];
			[currentTheme setSelectedDeadDownOuterColour:newColour];
			theGradientType = [currentTheme selectedDeadDownGradientType];
			break;
			
		default:
			NSLog(@"Unknown key type %ld!", keyType);
			break;
	}
	[self saveTheme];
	[self loadColours];
	[self refreshCurrentKeyCap];
	NSAssert(oldColour != nil, @"Must have the old colour");
	NSString *actionName = @"Set Outer Colour";
	if (theGradientType == gradientTypeNone) {
		actionName = @"Set Border Colour";
	}
	else if (theGradientType == gradientTypeLinear) {
		actionName = @"Set Bottom Colour";
	}
	[[undoManager prepareWithInvocationTarget:self] setNewOuterColour:oldColour forKeyType:keyType];
	[undoManager setActionName:actionName];
}

- (void)setNewTextColour:(NSColor *)newColour forKeyType:(NSInteger)keyType {
	NSColor *oldColour = nil;
	switch (keyType) {
		case normalUnselectedUp:
			oldColour = [currentTheme normalUpTextColour];
			[currentTheme setNormalUpTextColour:newColour];
			break;
			
		case deadKeyUnselectedUp:
			oldColour = [currentTheme deadKeyUpTextColour];
			[currentTheme setDeadKeyUpTextColour:newColour];
			break;
			
		case normalSelectedUp:
			oldColour = [currentTheme selectedUpTextColour];
			[currentTheme setSelectedUpTextColour:newColour];
			break;
			
		case deadKeySelectedUp:
			oldColour = [currentTheme selectedDeadUpTextColour];
			[currentTheme setSelectedDeadUpTextColour:newColour];
			break;
			
		case normalUnselectedDown:
			oldColour = [currentTheme normalDownTextColour];
			[currentTheme setNormalDownTextColour:newColour];
			break;
			
		case deadKeyUnselectedDown:
			oldColour = [currentTheme deadKeyDownTextColour];
			[currentTheme setDeadKeyDownTextColour:newColour];
			break;
			
		case normalSelectedDown:
			oldColour = [currentTheme selectedDownTextColour];
			[currentTheme setSelectedDownTextColour:newColour];
			break;
			
		case deadKeySelectedDown:
			oldColour = [currentTheme selectedDeadDownTextColour];
			[currentTheme setSelectedDeadDownTextColour:newColour];
			break;
			
		default:
			NSLog(@"Unknown key type %ld!", keyType);
			break;
	}
	[self saveTheme];
	[self loadColours];
	[self refreshCurrentKeyCap];
	NSAssert(oldColour != nil, @"Must have the old colour");
	NSString *actionName = @"Set Text Colour";
	[[undoManager prepareWithInvocationTarget:self] setNewTextColour:oldColour forKeyType:keyType];
	[undoManager setActionName:actionName];
}

- (void)setNewGradientType:(unsigned int)newGradientType forKeyType:(NSInteger)keyType {
//	if (hasUndoGroup) {
//		[self completeUndoGroup];
//	}
	unsigned int oldGradientType = gradientTypeNone;
	switch (keyType) {
		case normalUnselectedUp:
			oldGradientType = [currentTheme normalGradientType];
			[currentTheme setNormalGradientType:newGradientType];
			break;
			
		case deadKeyUnselectedUp:
			oldGradientType = [currentTheme deadKeyGradientType];
			[currentTheme setDeadKeyGradientType:newGradientType];
			break;
			
		case normalSelectedUp:
			oldGradientType = [currentTheme selectedGradientType];
			[currentTheme setSelectedGradientType:newGradientType];
			break;
			
		case deadKeySelectedUp:
			oldGradientType = [currentTheme selectedDeadGradientType];
			[currentTheme setSelectedDeadGradientType:newGradientType];
			break;
			
		case normalUnselectedDown:
			oldGradientType = [currentTheme normalDownGradientType];
			[currentTheme setNormalDownGradientType:newGradientType];
			break;
			
		case deadKeyUnselectedDown:
			oldGradientType = [currentTheme deadKeyDownGradientType];
			[currentTheme setDeadKeyDownGradientType:newGradientType];
			break;
			
		case normalSelectedDown:
			oldGradientType = [currentTheme selectedDownGradientType];
			[currentTheme setSelectedDownGradientType:newGradientType];
			break;
			
		case deadKeySelectedDown:
			oldGradientType = [currentTheme selectedDeadDownGradientType];
			[currentTheme setSelectedDeadDownGradientType:newGradientType];
			break;
			
		default:
			NSLog(@"Unknown key type %ld!", keyType);
			break;
	}
	[self saveTheme];
	[self loadColours];
	NSString *actionName = @"Set GradientType";
	[[undoManager prepareWithInvocationTarget:self] setNewGradientType:oldGradientType forKeyType:keyType];
	[undoManager setActionName:actionName];
}

- (void)createNewThemeNamed:(NSString *)themeName {
	ColourTheme *newTheme = [ColourTheme colourThemeNamed:themeName];
	if (newTheme != nil) {
			// This theme exists already
		return;
	}
	newTheme = [currentTheme copy];
	[newTheme setThemeName:themeName];
	[ColourTheme addTheme:newTheme];
	[[undoManager prepareWithInvocationTarget:self] deleteThemeNamed:themeName];
	[undoManager setActionName:@"Add colour theme"];
		// Add it to the popup
	[self.themeList addItemWithTitle:themeName];
	[self.themeList selectItemWithTitle:themeName];
	[self activateTheme:themeName];
	[self saveTheme];
}

- (void)deleteThemeNamed:(NSString *)themeName {
	ColourTheme *theTheme = [ColourTheme colourThemeNamed:themeName];
	if (theTheme == nil) {
			// Theme did not exist
		return;
	}
	[[undoManager prepareWithInvocationTarget:self] replaceTheme:theTheme];
	[undoManager setActionName:@"Delete colour theme"];
	[ColourTheme deleteThemeNamed:themeName];
		// Remove it from the popup
	NSInteger selectedIndex = [self.themeList indexOfSelectedItem];
	[self.themeList removeItemWithTitle:themeName];
	if (selectedIndex >= [self.themeList numberOfItems]) {
		selectedIndex = [self.themeList numberOfItems] - 1;
	}
	[self.themeList selectItemAtIndex:selectedIndex];
	[self activateTheme:[self.themeList titleOfSelectedItem]];
}

- (void)replaceTheme:(ColourTheme *)colourTheme {
	[[undoManager prepareWithInvocationTarget:self] deleteThemeNamed:[colourTheme themeName]];
//	[undoManager setActionName:@"Replace colour theme"];
	[ColourTheme addTheme:colourTheme];
		// Add it to the popup
	[self.themeList addItemWithTitle:[colourTheme themeName]];
	[self.themeList selectItemWithTitle:[colourTheme themeName]];
	[self activateTheme:[colourTheme themeName]];
}

- (void)renameThemeNamed:(NSString *)oldName to:(NSString *)newName {
	[[undoManager prepareWithInvocationTarget:self] renameThemeNamed:newName to:oldName];
	[undoManager setActionName:@"Rename colour theme"];
	NSAssert([ColourTheme themeExistsWithName:oldName], @"Must have the old theme");
	NSAssert(![ColourTheme themeExistsWithName:newName], @"Must not have the new name");
	ColourTheme *theTheme = [ColourTheme colourThemeNamed:oldName];
	[theTheme renameTheme:newName];
	[self.themeList removeAllItems];
	NSArray *allThemes = [[ColourTheme allColourThemes] allObjects];
	[self.themeList addItemsWithTitles:[allThemes sortedArrayUsingSelector:@selector(localizedStandardCompare:)]];
	[self.themeList selectItemWithTitle:newName];
}

#pragma mark Marshal data

- (void)activateTheme:(NSString *)themeName {
		// New theme chosen
	currentTheme = [ColourTheme colourThemeNamed:themeName];
	[self loadColours];
	[self.normalUp setColourTheme:currentTheme];
	[self.deadKeyUp setColourTheme:currentTheme];
	[self.selectedUp setColourTheme:currentTheme];
	[self.selectedDeadUp setColourTheme:currentTheme];
	[self.normalDown setColourTheme:currentTheme];
	[self.deadKeyDown setColourTheme:currentTheme];
	[self.selectedDown setColourTheme:currentTheme];
	[self.selectedDeadDown setColourTheme:currentTheme];
}

- (void)loadColours {
	if (currentKeyTypeStatus == noKeyStatus) {
			// Don't set anything
		return;
	}
	NSColor *innerColourValue = nil;
	NSColor *outerColourValue = nil;
	NSColor *textColourValue = nil;
	NSInteger gradientTypeValue = -1;
	switch (currentKeyTypeStatus) {
		case normalUnselectedUp:
			innerColourValue = [currentTheme normalUpInnerColour];
			outerColourValue = [currentTheme normalUpOuterColour];
			textColourValue = [currentTheme normalUpTextColour];
			gradientTypeValue = [currentTheme normalGradientType];
			break;
			
		case normalSelectedUp:
			innerColourValue = [currentTheme selectedUpInnerColour];
			outerColourValue = [currentTheme selectedUpOuterColour];
			textColourValue = [currentTheme selectedUpTextColour];
			gradientTypeValue = [currentTheme selectedGradientType];
			break;
			
		case deadKeyUnselectedUp:
			innerColourValue = [currentTheme deadKeyUpInnerColour];
			outerColourValue = [currentTheme deadKeyUpOuterColour];
			textColourValue = [currentTheme deadKeyUpTextColour];
			gradientTypeValue = [currentTheme deadKeyGradientType];
			break;
			
		case deadKeySelectedUp:
			innerColourValue = [currentTheme selectedDeadUpInnerColour];
			outerColourValue = [currentTheme selectedDeadUpOuterColour];
			textColourValue = [currentTheme selectedDeadUpTextColour];
			gradientTypeValue = [currentTheme selectedDeadGradientType];
			break;
			
		case normalUnselectedDown:
			innerColourValue = [currentTheme normalDownInnerColour];
			outerColourValue = [currentTheme normalDownOuterColour];
			textColourValue = [currentTheme normalDownTextColour];
			gradientTypeValue = [currentTheme normalDownGradientType];
			break;
			
		case normalSelectedDown:
			innerColourValue = [currentTheme selectedDownInnerColour];
			outerColourValue = [currentTheme selectedDownOuterColour];
			textColourValue = [currentTheme selectedDownTextColour];
			gradientTypeValue = [currentTheme selectedDownGradientType];
			break;
			
		case deadKeyUnselectedDown:
			innerColourValue = [currentTheme deadKeyDownInnerColour];
			outerColourValue = [currentTheme deadKeyDownOuterColour];
			textColourValue = [currentTheme deadKeyDownTextColour];
			gradientTypeValue = [currentTheme deadKeyDownGradientType];
			break;
			
		case deadKeySelectedDown:
			innerColourValue = [currentTheme selectedDeadDownInnerColour];
			outerColourValue = [currentTheme selectedDeadDownOuterColour];
			textColourValue = [currentTheme selectedDeadDownTextColour];
			gradientTypeValue = [currentTheme selectedDeadDownGradientType];
			break;
			
		default:
			break;
	}
		// Set the colour wells
	[self.innerColour setColor:innerColourValue];
	[self.outerColour setColor:outerColourValue];
	[self.textColour setColor:textColourValue];
		// Set the gradient type
	[self.gradientType selectCellWithTag:gradientTypeValue];
		// Set the colour labels for the gradient type
	switch (gradientTypeValue) {
		case gradientTypeRadial:	// Radial
			[self.innerColourLabel setStringValue:@"Inner colour"];
			[self.outerColourLabel setStringValue:@"Outer colour"];
			break;
			
		case gradientTypeLinear: // Linear
			[self.innerColourLabel setStringValue:@"Bottom colour"];
			[self.outerColourLabel setStringValue:@"Top colour"];
			break;
			
		case gradientTypeNone:	// None
			[self.innerColourLabel setStringValue:@"Fill colour"];
			[self.outerColourLabel setStringValue:@"Border colour"];
			break;
			
		default:
			break;
	}
}

- (void)refreshCurrentKeyCap {
	switch (currentKeyTypeStatus) {
		case noKeyStatus:
			break;
			
		case normalUnselectedUp:
			[self.normalUp setNeedsLayout:YES];
			break;
			
		case normalUnselectedDown:
			[self.normalDown setNeedsLayout:YES];
			break;
			
		case deadKeyUnselectedUp:
			[self.deadKeyUp setNeedsLayout:YES];
			break;
			
		case deadKeyUnselectedDown:
			[self.deadKeyDown setNeedsLayout:YES];
			break;
			
		case normalSelectedUp:
			[self.selectedUp setNeedsLayout:YES];
			break;
			
		case normalSelectedDown:
			[self.selectedDown setNeedsLayout:YES];
			break;
			
		case deadKeySelectedUp:
			[self.selectedDeadUp setNeedsLayout:YES];
			break;
			
		case deadKeySelectedDown:
			[self.selectedDeadDown setNeedsLayout:YES];
			break;
			
		default:
			NSLog(@"Unrecognised key %d", (int)currentKeyTypeStatus);
			break;
	}
}

- (void)saveTheme {
	[ColourTheme saveTheme:currentTheme];
	[self activateTheme:[currentTheme themeName]];
}

#pragma mark Mouse events

- (void)messageMouseEntered:(int)keyCode {
#pragma unused(keyCode)
}

- (void)messageMouseExited:(int)keyCode {
#pragma unused(keyCode)
}

#pragma mark Delegate methods

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
#pragma unused(window)
	return undoManager;
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
#pragma unused(notification)
}

- (void)windowDidResignMain:(NSNotification *)notification {
#pragma unused(notification)
	[self completeUndoGroup];
}

- (void)windowWillClose:(NSNotification *)notification {
#pragma unused(notification)
	[self completeUndoGroup];
}

- (void)popoverWillClose:(NSNotification *)notification {
#pragma unused(notification)
	[askTextController acceptText:self];
}

@end

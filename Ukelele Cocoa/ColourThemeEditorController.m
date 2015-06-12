//
//  ColourThemeEditorController.m
//  Ukelele 3
//
//  Created by John Brownie on 14/11/13.
//
//

#import "ColourThemeEditorController.h"
#import "ColourTheme.h"
#import "UkeleleConstantStrings.h"

typedef enum UKKeyTypeStatus: NSUInteger {
	normalUnselectedUp = 0,
	normalUnselectedDown = 1,
	normalSelectedUp = 2,
	normalSelectedDown = 3,
	deadKeyUnselectedUp = 4,
	deadKeyUnselectedDown = 5,
	deadKeySelectedUp = 6,
	deadKeySelectedDown = 7
} UKKeyTypeStatus;

@interface ColourThemeEditorController ()

@end

@implementation ColourThemeEditorController {
	ColourTheme *currentTheme;
	UKKeyTypeStatus currentKeyTypeStatus;
	void (^completionBlock)(NSString *);
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
		currentKeyTypeStatus = normalUnselectedUp;
		currentTheme = nil;
		completionBlock = nil;
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

+ (ColourThemeEditorController *)colourThemeEditorController {
	return [[[ColourThemeEditorController alloc] initWithWindowNibName:@"ColourThemeEditor"] autorelease];
}

//- (void)startEditingTheme:(ColourTheme *)colourTheme
//			   withWindow:(NSWindow *)parentWindow
//		  completionBlock:(void (^)(ColourTheme *))theBlock {
//	currentTheme = [colourTheme copy];
//	completionBlock = theBlock;
//	if (parentWindow) {
//			// Run as a sheet
//		[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
//	}
//	else {
//			// Run as a window
//		[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
//	}
//}

- (void)showColourThemesWithWindow:(NSWindow *)parentWindow completionBlock:(void (^)(NSString *))theBlock {
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *colourThemeDict = [[theDefaults dictionaryForKey:UKColourThemes] mutableCopy];
	NSString *currentColourTheme = [theDefaults stringForKey:UKColourTheme];
	currentTheme = [colourThemeDict objectForKey:currentColourTheme];
	[self.themeList removeAllItems];
	[self.themeList addItemsWithTitles:[colourThemeDict keysSortedByValueUsingSelector:@selector(compare:)]];
	[self.themeList selectItemWithTitle:currentColourTheme];
	completionBlock = theBlock;
	if (parentWindow) {
			// Run as a sheet
		[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
	}
	else {
			// Run as a window
		[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
	}
}

- (IBAction)newColourTheme:(id)sender {
#pragma unused(sender)
	
}

- (IBAction)editColourTheme:(id)sender {
#pragma unused(sender)
	
}

- (IBAction)duplicateColourTheme:(id)sender {
#pragma unused(sender)
	
}

- (IBAction)deleteColourTheme:(id)sender {
#pragma unused(sender)
	
}

- (IBAction)renameColourTheme:(id)sender {
#pragma unused(sender)
	
}

- (IBAction)acceptColourTheme:(id)sender {
#pragma unused(sender)
	[[self window] orderOut:self];
	completionBlock([currentTheme themeName]);
	[NSApp endSheet:[self window]];
}

- (IBAction)cancelColourTheme:(id)sender {
#pragma unused(sender)
	[[self window] orderOut:self];
	completionBlock(nil);
	[NSApp endSheet:[self window]];
}

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
			break;
	}
}

- (void)loadColours {
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
			gradientTypeValue = [currentTheme normalGradientType];
			break;
			
		case normalSelectedDown:
			innerColourValue = [currentTheme selectedDownInnerColour];
			outerColourValue = [currentTheme selectedDownOuterColour];
			textColourValue = [currentTheme selectedDownTextColour];
			gradientTypeValue = [currentTheme selectedGradientType];
			break;
			
		case deadKeyUnselectedDown:
			innerColourValue = [currentTheme deadKeyDownInnerColour];
			outerColourValue = [currentTheme deadKeyDownOuterColour];
			textColourValue = [currentTheme deadKeyDownTextColour];
			gradientTypeValue = [currentTheme deadKeyGradientType];
			break;
			
		case deadKeySelectedDown:
			innerColourValue = [currentTheme selectedDeadDownInnerColour];
			outerColourValue = [currentTheme selectedDeadDownOuterColour];
			textColourValue = [currentTheme selectedDeadDownTextColour];
			gradientTypeValue = [currentTheme selectedDeadGradientType];
			break;
			
		default:
			break;
	}
		// Set the colour wells
	[self.innerColour setColor:innerColourValue];
	[self.outerColour setColor:outerColourValue];
	[self.textColour setColor:textColourValue];
		// Set the gradient type
	[self.gradientType selectCellAtRow:gradientTypeValue column:0];
		// Set the colour labels for the gradient type
	switch (gradientTypeValue) {
		case 0:	// Radial
			[self.innerColourLabel setStringValue:@"Inner colour"];
			[self.outerColourLabel setStringValue:@"Outer colour"];
			break;
			
		case 1: // Linear
			[self.innerColourLabel setStringValue:@"Top colour"];
			[self.outerColourLabel setStringValue:@"Bottom colour"];
			break;
			
		case 2:	// None
			[self.innerColourLabel setStringValue:@"Fill colour"];
			[self.outerColourLabel setStringValue:@"Border colour"];
			break;
			
		default:
			break;
	}
}

- (IBAction)changeInnerColour:(id)sender {
	switch (currentKeyTypeStatus) {
		case normalUnselectedUp:
			[currentTheme setNormalUpInnerColour:[sender color]];
			break;
			
		case deadKeyUnselectedUp:
			[currentTheme setDeadKeyUpInnerColour:[sender color]];
			break;
			
		case normalSelectedUp:
			[currentTheme setSelectedUpInnerColour:[sender color]];
			break;
			
		case deadKeySelectedUp:
			[currentTheme setSelectedDeadUpInnerColour:[sender color]];
			break;
			
		case normalUnselectedDown:
			[currentTheme setNormalDownInnerColour:[sender color]];
			break;
			
		case deadKeyUnselectedDown:
			[currentTheme setDeadKeyDownInnerColour:[sender color]];
			break;
			
		case normalSelectedDown:
			[currentTheme setSelectedDownInnerColour:[sender color]];
			break;
			
		case deadKeySelectedDown:
			[currentTheme setSelectedDeadDownInnerColour:[sender color]];
			break;
	}
}

- (IBAction)changeOuterColour:(id)sender {
	switch (currentKeyTypeStatus) {
		case normalUnselectedUp:
			[currentTheme setNormalUpOuterColour:[sender color]];
			break;
			
		case deadKeyUnselectedUp:
			[currentTheme setDeadKeyUpOuterColour:[sender color]];
			break;
			
		case normalSelectedUp:
			[currentTheme setSelectedUpOuterColour:[sender color]];
			break;
			
		case deadKeySelectedUp:
			[currentTheme setSelectedDeadUpOuterColour:[sender color]];
			break;
			
		case normalUnselectedDown:
			[currentTheme setNormalDownOuterColour:[sender color]];
			break;
			
		case deadKeyUnselectedDown:
			[currentTheme setDeadKeyDownOuterColour:[sender color]];
			break;
			
		case normalSelectedDown:
			[currentTheme setSelectedDownOuterColour:[sender color]];
			break;
			
		case deadKeySelectedDown:
			[currentTheme setSelectedDeadDownOuterColour:[sender color]];
			break;
	}
}

- (IBAction)changeTextColour:(id)sender {
	switch (currentKeyTypeStatus) {
		case normalUnselectedUp:
			[currentTheme setNormalUpTextColour:[sender color]];
			break;
			
		case deadKeyUnselectedUp:
			[currentTheme setDeadKeyUpTextColour:[sender color]];
			break;
			
		case normalSelectedUp:
			[currentTheme setSelectedUpTextColour:[sender color]];
			break;
			
		case deadKeySelectedUp:
			[currentTheme setSelectedDeadUpTextColour:[sender color]];
			break;
			
		case normalUnselectedDown:
			[currentTheme setNormalDownTextColour:[sender color]];
			break;
			
		case deadKeyUnselectedDown:
			[currentTheme setDeadKeyDownTextColour:[sender color]];
			break;
			
		case normalSelectedDown:
			[currentTheme setSelectedDownTextColour:[sender color]];
			break;
			
		case deadKeySelectedDown:
			[currentTheme setSelectedDeadDownTextColour:[sender color]];
			break;
	}
}

@end

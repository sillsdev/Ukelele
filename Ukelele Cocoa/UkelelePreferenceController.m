//
//  UkelelePreferenceController.m
//  Ukelele 3
//
//  Created by John Brownie on 17/12/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import "UkelelePreferenceController.h"
#import "UkeleleConstantStrings.h"
#import "UkeleleConstants.h"
#import "ViewScale.h"
#import "UKDiacriticDisplay.h"

#define kMinZoom 0.5
#define kMaxZoom 5.0

@interface ScaleTransformer : NSValueTransformer

@end

@implementation ScaleTransformer

+ (BOOL)allowsReverseTransformation {
	return YES;
}

+ (Class)transformedValueClass {
	return [NSString class];
}

- (id)transformedValue:(id)value {
	NSAssert([value isKindOfClass:[NSNumber class]], @"Must be a number");
	NSString *theValue;
	if ([value floatValue] < 0) {
		theValue = @"Fit Width";
	}
	else {
		theValue = [NSString stringWithFormat:@"%.0f%%", [value floatValue] * 100.0];
	}
	return theValue;
}

- (id)reverseTransformedValue:(id)value {
	NSAssert([value isKindOfClass:[NSString class]], @"Must be a string");
	NSNumber *returnValue;
	if ([value isEqualToString:@"Fit Width"]) {
		returnValue = @(-1);
	}
	else {
		CGFloat floatValue = [value floatValue];
		returnValue = @(floatValue / 100.0);
	}
	return returnValue;
}

@end

@interface DiacriticTransformer : NSValueTransformer

@end

@implementation DiacriticTransformer

+ (Class)transformedValueClass {
	return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
	return YES;
}

- (id)transformedValue:(id)value {
	NSAssert([value isKindOfClass:[NSNumber class]], @"Must be a number");
	UKDiacriticDisplay *diacriticDisplay = [UKDiacriticDisplay getInstance];
	NSUInteger theIndex = [diacriticDisplay indexForDiacritic:(UniChar)[value unsignedIntValue]];
	return [diacriticDisplay textForIndex:theIndex];
}

- (id)reverseTransformedValue:(id)value {
	NSAssert([value isKindOfClass:[NSString class]], @"Must be a string");
	NSNumber *result;
	NSString *diacriticString = @" ";
	UKDiacriticDisplay *diacriticDisplay = [UKDiacriticDisplay getInstance];
	if ([value isEqualToString:[diacriticDisplay textForIndex:UKDiacriticSquare]]) {
		diacriticString = [diacriticDisplay diacriticForIndex:UKDiacriticSquare];
	}
	else if ([value isEqualToString:[diacriticDisplay textForIndex:UKDiacriticDottedSquare]]) {
		diacriticString = [diacriticDisplay diacriticForIndex:UKDiacriticDottedSquare];
	}
	else if ([value isEqualToString:[diacriticDisplay textForIndex:UKDiacriticCircle]]) {
		diacriticString = [diacriticDisplay diacriticForIndex:UKDiacriticCircle];
	}
	else if ([value isEqualToString:[diacriticDisplay textForIndex:UKDiacriticDottedCircle]]) {
		diacriticString = [diacriticDisplay diacriticForIndex:UKDiacriticDottedCircle];
	}
	else if ([value isEqualToString:[diacriticDisplay textForIndex:UKDiacriticSpace]]) {
		diacriticString = [diacriticDisplay diacriticForIndex:UKDiacriticSpace];
	}
	result = @([diacriticString characterAtIndex:0]);
	return result;
}

@end

@interface UKIntervalTransformer : NSValueTransformer

@end

@implementation UKIntervalTransformer

+ (Class)transformedValueClass {
	return [NSString class];
}

+ (BOOL)allowsReverseTransformation {
	return YES;
}

#define DailySeconds	60 * 60 * 24
#define WeeklySeconds	DailySeconds * 7
#define MonthlySeconds	DailySeconds * 30
#define DailyString		@"Daily"
#define WeeklyString	@"Weekly"
#define MonthlyString	@"Monthly"

- (id)transformedValue:(id)value {
	NSInteger secondsValue = [value integerValue];
	NSString *stringValue = @"";
	if (secondsValue == DailySeconds) {
		stringValue = @"Daily";
	}
	else if (secondsValue == WeeklySeconds) {
		stringValue = @"Weekly";
	}
	else if (secondsValue == MonthlySeconds) {
		stringValue = @"Monthly";
	}
	return stringValue;
}

- (id)reverseTransformedValue:(id)value {
	NSInteger secondsValue = 0;
	if ([value isEqualToString:DailyString]) {
		secondsValue = DailySeconds;
	}
	else if ([value isEqualToString:WeeklyString]) {
		secondsValue = WeeklySeconds;
	}
	else if ([value isEqualToString:MonthlyString]) {
		secondsValue = MonthlySeconds;
	}
	return @(secondsValue);
}

@end

@interface UkelelePreferenceController ()
@property (strong) NSMutableArray *scalesList;
@end

@implementation UkelelePreferenceController

static NSString *nibFileName = @"UkelelePreferences";
static NSString *nibWindow = @"Preferences";

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:nibFileName owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
		keyboardResources = [KeyboardResourceList getInstance];
		[_arrayController setContent:[keyboardResources keyboardTypeTable]];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString *fontName = [defaults stringForKey:UKTextFont];
		float fontSize = [defaults floatForKey:UKTextSize];
		_currentFont = [NSFont fontWithName:fontName size:fontSize];
		_scalesList = [ViewScale standardScales];
		[_defaultZoom removeAllItems];
		for (ViewScale *scale in _scalesList) {
			[_defaultZoom addItemWithObjectValue:[scale scaleLabel]];
		}
		NSUserDefaults *sharedDefaults = [NSUserDefaults standardUserDefaults];
		BOOL codeNonAscii = [sharedDefaults boolForKey:UKCodeNonAscii];
		[_xmlHasCharacters setState:codeNonAscii ? NSControlStateValueOff : NSControlStateValueOn];
		[_xmlHasCodePoints setState:codeNonAscii ? NSControlStateValueOn : NSControlStateValueOff];
    }
    
    return self;
}

+ (UkelelePreferenceController *)getInstance
{
	static UkelelePreferenceController *theInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		theInstance = [[UkelelePreferenceController alloc] initWithWindowNibName:nibWindow];
	});
	return theInstance;
}

- (IBAction)returnToDefaults:(id)sender {
#pragma unused(sender)
	[[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:self];
	[self syncPreferences];
}

- (IBAction)changeDefaultFont:(id)sender {
#pragma unused(sender)
	if ([[self window] makeFirstResponder:nil]) {
		NSFontManager *fontManager = [NSFontManager sharedFontManager];
			// Set the font
		[fontManager setSelectedFont:[self currentFont] isMultiple:NO];
		[fontManager orderFrontFontPanel:self];
	}
}

- (void)changeFont:(id)fontManager {
	NSFont *newFont = [fontManager convertFont:_currentFont];
		// Set the font
	[self setCurrentFont:newFont];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[self.currentFont displayName] forKey:UKTextFont];
	[defaults setObject:@([self.currentFont pointSize]) forKey:UKTextSize];
}

- (void)runPreferences {
	[self syncPreferences];
	[[NSFontManager sharedFontManager] setSelectedFont:self.currentFont isMultiple:NO];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *fontName = [defaults stringForKey:UKTextFont];
	float fontSize = [defaults floatForKey:UKTextSize];
	self.currentFont = [NSFont fontWithName:fontName size:fontSize];
	[self showWindow:[self window]];
}

	// Ensure that the interface shows the correct preferences
- (void)syncPreferences {
	NSUserDefaults *sharedDefaults = [NSUserDefaults standardUserDefaults];
		// Set the keyboard type menus
	NSInteger keyboardType = [sharedDefaults integerForKey:UKDefaultLayoutID];
	NSDictionary *typeIndices = [keyboardResources indicesForResourceID:keyboardType];
	[self.keyboardType selectItemAtIndex:[typeIndices[kKeyNameIndex] integerValue]];
	[self.arrayController setSelectionIndex:[typeIndices[kKeyNameIndex] integerValue]];
	[self.keyboardCoding selectItemAtIndex:[typeIndices[kKeyCodingIndex] integerValue] - 1];
		// Set the zoom combo button
	float zoomLevel = [sharedDefaults floatForKey:UKScaleFactor];
	if (zoomLevel <= 0.0) {
			// This is "fit width"
		[self.defaultZoom setStringValue:@"Fit Width"];
	}
	else {
		[self.defaultZoom setStringValue:[NSString stringWithFormat:@"%.0f%%", zoomLevel * 100.0]];
	}
}

- (IBAction)resetWarnings:(id)sender {
#pragma unused(sender)
	NSUserDefaults *sharedDefaults = [NSUserDefaults standardUserDefaults];
	[sharedDefaults setBool:NO forKey:UKDontShowWarningDialog];
}

- (IBAction)toggleCodeNonAscii:(id)sender {
	NSUserDefaults *sharedDefaults = [NSUserDefaults standardUserDefaults];
	if (sender == self.xmlHasCharacters) {
		[sharedDefaults setBool:NO forKey:UKCodeNonAscii];
	}
	else {
		[sharedDefaults setBool:YES forKey:UKCodeNonAscii];
	}
}

- (void)windowWillClose:(NSNotification *)notification {
#pragma unused(notification)
		// Note the default keyboard type
	NSInteger selectedType = [self.keyboardType indexOfSelectedItem];
	NSInteger selectedCoding = [self.keyboardCoding indexOfSelectedItem];
	if (selectedType != -1 && selectedCoding != -1) {
		NSInteger keyboardType = [keyboardResources resourceForType:selectedType code:selectedCoding];
		[[NSUserDefaults standardUserDefaults] setInteger:keyboardType forKey:UKDefaultLayoutID];
	}
	
		// Note the zoom level
	CGFloat zoomLevel = [self.defaultZoom floatValue] / 100.0;
	if (zoomLevel <= 0) {
			// Fit width
		zoomLevel = -1.0f;
	}
	else if (zoomLevel < kMinZoom) {
			// Too small
		zoomLevel = kMinZoom;
	}
	else if (zoomLevel > kMaxZoom) {
			// Too big
		zoomLevel = kMaxZoom;
	}
	[[NSUserDefaults standardUserDefaults] setDouble:zoomLevel forKey:UKScaleFactor];
}

@end

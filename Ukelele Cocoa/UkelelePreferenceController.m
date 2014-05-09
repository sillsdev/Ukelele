//
//  UkelelePreferenceController.m
//  Ukelele 3
//
//  Created by John Brownie on 17/12/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import "UkelelePreferenceController.h"
#import "UkeleleConstantStrings.h"

@implementation UkelelePreferenceController

static NSString *nibFileName = @"UkelelePreferences";
static NSString *nibWindow = @"Preferences";

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[NSBundle loadNibNamed:nibFileName owner:self];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
		keyboardResources = [KeyboardResourceList getInstance];
		[_arrayController setContent:[keyboardResources keyboardTypeTable]];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString *fontName = [defaults stringForKey:UKTextFont];
		float fontSize = [defaults floatForKey:UKTextSize];
		_currentFont = [NSFont fontWithName:fontName size:fontSize];
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
	[[NSUserDefaultsController sharedUserDefaultsController] revertToInitialValues:self];
	[self syncPreferences];
}

- (IBAction)changeDefaultFont:(id)sender {
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
	[self.keyboardType selectItemAtIndex:[[typeIndices valueForKey:kKeyNameIndex] integerValue]];
	[self.arrayController setSelectionIndex:[[typeIndices valueForKey:kKeyNameIndex] integerValue]];
	[self.keyboardCoding selectItemAtIndex:[[typeIndices valueForKey:kKeyCodingIndex] integerValue] - 1];
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

- (void)windowWillClose:(NSNotification *)notification {
		// Note the default keyboard type
	NSInteger selectedType = [self.keyboardType indexOfSelectedItem];
	NSInteger selectedCoding = [self.keyboardCoding indexOfSelectedItem];
	if (selectedType != -1 && selectedCoding != -1) {
		NSInteger keyboardType = [keyboardResources resourceForType:selectedType code:selectedCoding];
		[[NSUserDefaults standardUserDefaults] setInteger:keyboardType forKey:UKDefaultLayoutID];
	}
	
		// Note the zoom level
	float zoomLevel = [self.defaultZoom floatValue] / 100.0;
	if (zoomLevel <= 0) {
			// Fit width
		zoomLevel = -1.0f;
	}
	else if (zoomLevel < 0.5) {
			// Too small
		zoomLevel = 0.5;
	}
	else if (zoomLevel > 5.0) {
			// Too big
		zoomLevel = 5.0;
	}
	[[NSUserDefaults standardUserDefaults] setFloat:zoomLevel forKey:UKScaleFactor];
}

@end

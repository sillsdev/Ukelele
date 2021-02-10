//
//  UkelelePreferenceController.h
//  Ukelele 3
//
//  Created by John Brownie on 17/12/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KeyboardResourceList.h"

@interface UkelelePreferenceController : NSWindowController<NSWindowDelegate> {
	KeyboardResourceList *keyboardResources;
}

@property (strong) IBOutlet NSPopUpButton *keyboardType;
@property (strong) IBOutlet NSPopUpButton *keyboardCoding;
@property (strong) IBOutlet NSPopUpButton *colourTheme;
@property (strong) IBOutlet NSComboBox *defaultZoom;
@property (strong) IBOutlet NSPopUpButton *diacriticDisplay;
@property (strong) IBOutlet NSPopUpButton *updateInterval;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSTextField *fontDisplay;
@property (strong) IBOutlet NSFont *currentFont;
@property (strong) IBOutlet NSButton *xmlHasCharacters;
@property (strong) IBOutlet NSButton *xmlHasCodePoints;

+ (UkelelePreferenceController *)getInstance;

- (IBAction)returnToDefaults:(id)sender;
- (IBAction)changeDefaultFont:(id)sender;
- (IBAction)resetWarnings:(id)sender;
- (IBAction)toggleCodeNonAscii:(id)sender;

- (void)runPreferences;
- (void)changeFont:(id)fontManager;		// Sent by font panel

@end

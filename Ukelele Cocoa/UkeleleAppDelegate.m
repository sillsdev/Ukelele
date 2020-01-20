//
//  UkeleleAppDelegate.m
//  Ukelele 3
//
//  Created by John Brownie on 26/08/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "UkeleleAppDelegate.h"
#import "UkeleleConstants.h"
#import "UkeleleConstantStrings.h"
#import "UkeleleErrorCodes.h"
#import "UKKeyboardDocument.h"
#import "ColourTheme.h"
#import "ToolboxController.h"
#import "InspectorWindowController.h"
#import "UnicodeTable.h"
#import "UkelelePreferenceController.h"
#import "UKKeyboardController.h"
#import "UKKeyboardDocument.h"
#import "ColourThemeEditorController.h"
#import "UKNewKeyboardLayoutController.h"
#include <ServiceManagement/ServiceManagement.h>
#import "Ukelele-Swift.h"

#define UkeleleManualName	@"Ukelele Manual"
#define UkeleleWebSite		@"http://scripts.sil.org/ukelele"
#define UkeleleUsersGroup	@"http://groups.google.com/group/ukelele-users"

@interface UkeleleAppDelegate () {
	AuthorizationRef _authRef;
	UKOrganiserController *organiserController;
}

@end

@implementation UkeleleAppDelegate

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
		organiserController = nil;
    }
//	[NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *inEvent){
//		NSString *characters = [inEvent characters];
//		NSString *charsWithoutModifiers = [inEvent charactersIgnoringModifiers];
//		NSUInteger modifiers = [NSEvent modifierFlags];
//		NSLog(@"Characters '%@', without modifiers '%@', modifiers %lx", characters, charsWithoutModifiers, modifiers);
//		return inEvent;
//	}];
    
    return self;
}

static NSDictionary *defaultValues() {
	static NSDictionary *dict = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		ColourTheme *defaultTheme = [ColourTheme defaultColourTheme];
		NSData *defaultThemeData = [NSKeyedArchiver archivedDataWithRootObject:defaultTheme requiringSecureCoding:NO error:nil];
		ColourTheme *printTheme = [ColourTheme defaultPrintTheme];
		NSData *printThemeData = [NSKeyedArchiver archivedDataWithRootObject:printTheme requiringSecureCoding:NO error:nil];
		NSDictionary *colourThemes = @{kDefaultThemeName: defaultThemeData,
								 kPrintThemeName: printThemeData};
		dict = @{UKScaleFactor:					@1.25f,
				 UKTextSize:					@(kDefaultLargeFontSize),
				 UKTextFont:					@"Lucida Grande",
				 UKUsesSingleClickToEdit:		@NO,
				 UKDefaultLayoutID:				@(gestaltUSBAndyANSIKbd),
				 UKAlwaysUsesDefaultLayout:		@NO,
				 UKStateNameBase:				@"Dead Key State",
				 UKDiacriticDisplayCharacter:	@(UKDiacriticSpace),
				 UKUsesPopover:					@YES,
				 UKTigerCompatibleBundles:		@NO,
				 UKCodeNonAscii:				@NO,
				 UKColourThemes:				colourThemes,
				 UKColourTheme:					kDefaultThemeName,
				 UKUpdateEditingComment:		@YES,
				 UKDontShowWarningDialog:		@NO,
				 UKStickyModifiers:				@NO,
				 UKJISOnly:						@NO,
				 UKShowCodePoints:				@YES
				 };
	});
	return dict;
}

- (NSError *)application:(NSApplication *)application willPresentError:(NSError *)error
{
#pragma unused(application)
    if ([[error domain] isEqualToString:kDomainUkelele]) {
		NSError *underlyingError = [error userInfo][NSUnderlyingErrorKey];
        return underlyingError == nil ? error : underlyingError;
    }
    return error;
}

- (IBAction)doPreferences:(id)sender {
#pragma unused(sender)
		// Create (if necessary) and run the preference window
	UkelelePreferenceController *thePrefsController = [UkelelePreferenceController getInstance];
	[thePrefsController runPreferences];
}

- (IBAction)newBundle:(id)sender {
#pragma unused(sender)
	NSError *theError;
	UKKeyboardDocument *theDocument = [[NSDocumentController sharedDocumentController]
										 makeUntitledDocumentOfType:(NSString *)kUTTypeBundle error:&theError];
	if (nil != theDocument) {
			// Got a document
		[[NSDocumentController sharedDocumentController] addDocument:theDocument];
		[theDocument makeWindowControllers];
		[theDocument showWindows];
	}
}

- (IBAction)newFromCurrentInput:(id)sender {
#pragma unused(sender)
	NSError *theError;
	UKKeyboardDocument *theDocument = [[NSDocumentController sharedDocumentController]
									   makeUntitledDocumentOfType:(NSString *)kUTTypeBundle error:&theError];
	if (nil != theDocument) {
		NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
		[documentController addDocument:theDocument];
		[theDocument makeWindowControllers];
		[theDocument showWindows];
		[theDocument captureInputSource:self];
	}
}

- (IBAction)newKeyboardLayout:(id)sender {
#pragma unused(sender)
	__block UKNewKeyboardLayoutController *theController = [UKNewKeyboardLayoutController createController];
	[theController runDialog:nil withCompletion:^(NSString *keyboardName, NSUInteger baseLayout, NSUInteger commandLayout, NSUInteger capsLockLayout) {
			// Check whether we have a valid layout
		if (baseLayout != kStandardLayoutNone) {
				// Create a keyboard with the given layout types
			NSAssert(commandLayout != kStandardLayoutNone, @"Must have a command layout specified");
			NSAssert(capsLockLayout != kStandardLayoutNone, @"Must have a caps lock layout specified");
			UkeleleKeyboardObject *keyboardObject = [[UkeleleKeyboardObject alloc] initWithName:keyboardName base:baseLayout command:commandLayout capsLock:capsLockLayout];
			UKKeyboardDocument *theDocument = [[UKKeyboardDocument alloc] initWithKeyboardObject:keyboardObject];
			if (nil != theDocument) {
				[[NSDocumentController sharedDocumentController] addDocument:theDocument];
				[theDocument makeWindowControllers];
				[theDocument showWindows];
			}
		}
		theController = nil;
	}];
}

- (IBAction)toggleToolbox:(id)sender {
	ToolboxController *toolboxController = [ToolboxController sharedToolboxController];
	NSWindow *toolboxWindow = [toolboxController window];
	NSAssert(toolboxWindow, @"Window should not be nil");
	if ([toolboxWindow isVisible]) {
		[toolboxWindow orderOut:sender];
	}
	else {
		[toolboxController showWindow:self];
	}
}

- (IBAction)toggleStickyModifiers:(id)sender {
#pragma unused(sender)
	ToolboxData *toolboxData = [ToolboxData sharedToolboxData];
	NSAssert(toolboxData, @"Toolbox data cannot be nil");
	[toolboxData setStickyModifiers:![toolboxData stickyModifiers]];
}

- (IBAction)showHideInspector:(id)sender
{
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	NSAssert(infoInspector, @"Info Inspector must not be nil");
	if ([[infoInspector window] isVisible]) {
		[[infoInspector window] orderOut:sender];
	}
	else {
		[infoInspector showWindow:sender];
		NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
		NSWindowController *mainController = [mainWindow windowController];
		if ([mainController isKindOfClass:[UKKeyboardController class]]) {
			[(UKKeyboardController *)mainController inspectorDidAppear];
		}
		else if ([[mainController windowNibName] isEqualToString:@"UKKeyboardLayoutBundle"]) {
			UKKeyboardDocument *theDocument = [mainController document];
			[theDocument inspectorDidAppear];
		}
	}
}

- (IBAction)showHideOrganiser:(id)sender {
	if (organiserController == nil) {
		// Create the organiser
		UKUserLibrary *library = [[UKUserLibrary alloc] init];
		[library userLibraryWithCompletion:^(NSURL * _Nullable theLibrary) {
			if (theLibrary != nil) {
				self->organiserController = [[UKOrganiserController alloc] initWithWindowNibName:@"Organise"];
				[[self->organiserController window] makeKeyAndOrderFront:sender];
			}
		}];
		return;
	}
	if ([[organiserController window] isVisible]) {
		[[organiserController window] orderOut:sender];
	}
	else {
		[[organiserController window] makeKeyAndOrderFront:sender];
	}
}

- (IBAction)install:(id)sender {
	if (organiserController == nil) {
		organiserController = [[UKOrganiserController alloc] initWithWindowNibName:@"Organiser"];
	}
	[[organiserController window] makeKeyAndOrderFront:sender];
}

- (IBAction)toggleShowCodePoints:(id)sender {
#pragma unused(sender)
	ToolboxData *toolboxData = [ToolboxData sharedToolboxData];
	NSAssert(toolboxData, @"Toolbox data cannot be nil");
	[toolboxData setShowCodePoints:![toolboxData showCodePoints]];
	BOOL show = [toolboxData showCodePoints];
	// Tell the current windows to update the show code points value
	for (NSWindow *window in [[NSApplication sharedApplication] windows]) {
		NSWindowController *controller = [window windowController];
		if ([controller isKindOfClass:[UKKeyboardController class]]) {
			[(UKKeyboardController *)controller setShowCodePoints:show];
		}
	}
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
#pragma unused(notification)
		// Register defaults
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues()];
#ifdef DEBUG
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"NSConstraintBasedLayoutVisualizeMutuallyExclusiveConstraints"];
#endif
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues()];
	
		// Set up the Unicode table
	[UnicodeTable setup];
	
		// Activate the default colour theme
	NSString *defaultTheme = [[NSUserDefaults standardUserDefaults] stringForKey:UKColourTheme];
	if (defaultTheme == nil || [defaultTheme length] == 0 || ![ColourTheme themeExistsWithName:defaultTheme]) {
		defaultTheme = kDefaultThemeName;
	}
	[ColourTheme setCurrentColourTheme:defaultTheme];
	
		// Create our connection to the authorization system.
		//
		// If we can't create an authorization reference then the app is not going to be able
		// to do anything requiring authorization.  Generally this only happens when you launch
		// the app in some wacky, and typically unsupported, way.  In the debug build we flag that
		// with an assert.  In the release build we continue with self->_authRef as NULL, which will
		// cause all authorized operations to fail.
    
    OSStatus err = AuthorizationCreate(NULL, NULL, 0, &self->_authRef);
	AuthorizationExternalForm extForm;
    if (err == errAuthorizationSuccess) {
        err = AuthorizationMakeExternalForm(self->_authRef, &extForm);
    }
    if (err == errAuthorizationSuccess) {
        self.authorization = [[NSData alloc] initWithBytes:&extForm length:sizeof(extForm)];
    }
    assert(err == errAuthorizationSuccess);
    
		// If we successfully connected to Authorization Services, add definitions for our default
		// rights (unless they're already in the database).
    
}

- (void)applicationWillTerminate:(NSNotification *)notification {
#pragma unused(notification)
		// Save the state of toolbox data
	ToolboxData *toolBoxData = [ToolboxData sharedToolboxData];
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:[toolBoxData stickyModifiers] forKey:UKStickyModifiers];
	[userDefaults setBool:[toolBoxData JISOnly] forKey:UKJISOnly];
	[userDefaults setBool:[toolBoxData showCodePoints] forKey:UKShowCodePoints];
	[userDefaults synchronize];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	SEL action = [menuItem action];
	if (action == @selector(toggleStickyModifiers:)) {
		ToolboxData *toolboxData = [ToolboxData sharedToolboxData];
		NSAssert(toolboxData, @"Toolbox data must not be nil");
		[menuItem setState:[toolboxData stickyModifiers] ? NSControlStateValueOn : NSControlStateValueOff];
		return YES;
	}
	else if (action == @selector(toggleShowCodePoints:)) {
		ToolboxData *toolboxData = [ToolboxData sharedToolboxData];
		NSAssert(toolboxData, @"Toolbox data must not be nil");
		[menuItem setState:[toolboxData showCodePoints] ? NSControlStateValueOn : NSControlStateValueOff];
		return YES;
	}
	else if (action == @selector(toggleToolbox:)) {
		ToolboxController *toolboxController = [ToolboxController sharedToolboxController];
		NSWindow *toolboxWindow = [toolboxController window];
		NSAssert(toolboxWindow, @"Toolbox window must not be nil");
		if ([toolboxWindow isVisible]) {
			[menuItem setTitle:@"Hide Toolbox"];
		}
		else {
			[menuItem setTitle:@"Show Toolbox"];
		}
		return YES;
	}
	else if (action == @selector(showHideInspector:)) {
		InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
		NSAssert(infoInspector && [infoInspector window], @"Info inspector must not be nil");
		if ([[infoInspector window] isVisible]) {
			[menuItem setTitle:@"Hide Inspector"];
		}
		else {
			[menuItem setTitle:@"Show Inspector"];
		}
		return YES;
	}
	else if (action == @selector(showHideOrganiser:)) {
		if (organiserController == nil || ![[organiserController window] isVisible]) {
			[menuItem setTitle:@"Show Organiser"];
		}
		else {
			[menuItem setTitle:@"Hide Organiser"];
		}
		return YES;
	}
	else if (action == @selector(colourThemes:) || (action == @selector(newFromCurrentInput:)) ||
			 (action == @selector(install:))) {
		return YES;
	}
	return YES;
}

- (IBAction)openManual:(id)sender {
#pragma unused(sender)
	NSBundle *myBundle = [NSBundle mainBundle];
	NSString *manualPath = [myBundle pathForResource:UkeleleManualName ofType:@"pdf"];
	[[NSWorkspace sharedWorkspace] openFile:manualPath];
}

- (IBAction)openWebSite:(id)sender {
#pragma unused(sender)
	NSURL *groupURL = [NSURL URLWithString:UkeleleWebSite];
	[[NSWorkspace sharedWorkspace] openURL:groupURL];
}

- (IBAction)openUkeleleUsersGroup:(id)sender {
#pragma unused(sender)
	NSURL *groupURL = [NSURL URLWithString:UkeleleUsersGroup];
	[[NSWorkspace sharedWorkspace] openURL:groupURL];
}

- (IBAction)colourThemes:(id)sender {
#pragma unused(sender)
	__block ColourThemeEditorController *theController = [ColourThemeEditorController colourThemeEditorController];
	[theController showColourThemesWithWindow:nil completionBlock:^(NSString *theTheme) {
		if (theTheme) {
				// Set the current theme
			[ColourTheme setCurrentColourTheme:theTheme];
			[self updateWindowsWithColourThemes];
		}
		theController = nil;
	}];
}

- (void)updateWindowsWithColourThemes {
	NSArray *allWindows = [[NSApplication sharedApplication] windows];
	for (NSWindow *theWindow in allWindows) {
			// Look for a window which is a keyboard window
		if ([[theWindow windowController] isKindOfClass:[UKKeyboardController class]]) {
				// Have a keyboard window
			UKKeyboardController *theController = [theWindow windowController];
			[theController updateColourThemes];
		}
	}
}

- (void)menuNeedsUpdate:(NSMenu *)menu {
		// We only use this for the colour themes menu
	NSAssert([[menu title] isEqualToString:@"Colour Themes"], @"Must have the right menu");
	NSArray *colourThemes = [[[ColourTheme allColourThemes] allObjects] sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
	[menu removeAllItems];
	ColourTheme *currentTheme = [ColourTheme currentColourTheme];
	NSString *currentThemeName = [currentTheme themeName];
	for (NSUInteger i = 0; i < [colourThemes count]; i++) {
		NSString *themeName = colourThemes[i];
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:themeName action:@selector(chooseColourTheme:) keyEquivalent:@""];
		if ([currentThemeName isEqualTo:themeName]) {
				// The current theme, so mark it
			[menuItem setState:NSControlStateValueOn];
		}
		[menu addItem:menuItem];
	}
		// Add the separator and the editor item
	[menu addItem:[NSMenuItem separatorItem]];
	[menu addItemWithTitle:@"Edit Themes…" action:@selector(colourThemes:) keyEquivalent:@""];
}

- (IBAction)chooseColourTheme:(id)sender {
	[ColourTheme setCurrentColourTheme:[sender title]];
}

@end

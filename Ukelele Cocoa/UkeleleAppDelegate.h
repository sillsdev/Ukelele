//
//  UkeleleAppDelegate.h
//  Ukelele 3
//
//  Created by John Brownie on 26/08/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UkeleleAppDelegate : NSObject<NSApplicationDelegate, NSMenuDelegate>

- (IBAction)doPreferences:(id)sender;
- (IBAction)newBundle:(id)sender;
- (IBAction)newFromCurrentInput:(id)sender;
- (IBAction)newKeyboardLayout:(id)sender;
- (IBAction)toggleToolbox:(id)sender;
- (IBAction)toggleStickyModifiers:(id)sender;
- (IBAction)showHideInspector:(id)sender;
- (IBAction)openManual:(id)sender;
- (IBAction)openWebSite:(id)sender;
- (IBAction)openUkeleleUsersGroup:(id)sender;
- (IBAction)colourThemes:(id)sender;
- (IBAction)chooseColourTheme:(id)sender;

@property (atomic, copy,   readwrite) NSData *authorization;
@property (atomic, strong, readwrite) NSXPCConnection *helperToolConnection;

@end

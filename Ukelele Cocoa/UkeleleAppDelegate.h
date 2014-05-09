//
//  UkeleleAppDelegate.h
//  Ukelele 3
//
//  Created by John Brownie on 26/08/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UkeleleAppDelegate : NSObject<NSApplicationDelegate>

- (IBAction)doPreferences:(id)sender;
- (IBAction)newBundle:(id)sender;
- (IBAction)newFromCurrentInput:(id)sender;
- (IBAction)toggleToolbox:(id)sender;
- (IBAction)toggleStickyModifiers:(id)sender;
- (IBAction)showHideInspector:(id)sender;

- (void)connectAndExecuteCommandBlock:(void(^)(NSError *))commandBlock;
- (BOOL)installHelperTool;

@property (atomic, copy,   readwrite) NSData *authorization;
@property (atomic, strong, readwrite) NSXPCConnection *helperToolConnection;

@end

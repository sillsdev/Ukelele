//
//  KeyboardLayoutBundle.h
//  Ukelele 3
//
//  Created by John Brownie on 3/09/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface KeyboardLayoutBundle : NSDocument<NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate> {
	IBOutlet NSTableView *keyboardLayoutsTable;
	IBOutlet NSButton *languageButton;
	IBOutlet NSButton *removeKeyboardButton;
}

@property (nonatomic, strong) NSString *bundleVersion;
@property (nonatomic, strong) NSString *buildVersion;
@property (nonatomic, strong) NSString *sourceVersion;
@property (strong) NSString *bundleIdentifier;
@property (nonatomic, strong) NSString *bundleName;

- (IBAction)addOpenDocument:(id)sender;
- (IBAction)showVersionInfo:(id)sender;
- (IBAction)addKeyboardLayout:(id)sender;
- (IBAction)removeKeyboardLayout:(id)sender;
- (IBAction)openKeyboardLayout:(id)sender;
- (IBAction)chooseIntendedLanguage:(id)sender;
- (IBAction)captureInputSource:(id)sender;

- (NSArray *)keyboardLayouts;

- (void)notifyNewName:(NSString *)newName forDocument:(id)keyboardDocument;

- (void)inspectorDidActivateTab:(NSString *)tabIdentifier;

@end

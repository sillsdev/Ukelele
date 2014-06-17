//
//  UKKeyboardDocument.h
//  Ukelele Cocoa
//
//  Created by John Brownie on 13/06/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class UkeleleKeyboardObject;

@interface UKKeyboardDocument : NSDocument<NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate> {
	IBOutlet NSTableView *keyboardLayoutsTable;
	IBOutlet NSButton *languageButton;
	IBOutlet NSButton *removeKeyboardButton;
}

@property (nonatomic, strong) NSString *bundleVersion;
@property (nonatomic, strong) NSString *buildVersion;
@property (nonatomic, strong) NSString *sourceVersion;
@property (strong) NSString *bundleIdentifier;
@property (nonatomic, strong) NSString *bundleName;
@property (nonatomic) BOOL isBundle;
@property (strong, nonatomic) UkeleleKeyboardObject *keyboardLayout;

- (IBAction)addOpenDocument:(id)sender;
- (IBAction)showVersionInfo:(id)sender;
- (IBAction)addKeyboardLayout:(id)sender;
- (IBAction)removeKeyboardLayout:(id)sender;
- (IBAction)openKeyboardLayout:(id)sender;
- (IBAction)chooseIntendedLanguage:(id)sender;
- (IBAction)captureInputSource:(id)sender;

- (NSArray *)keyboardLayouts;

- (void)inspectorDidActivateTab:(NSString *)tabIdentifier;

@end

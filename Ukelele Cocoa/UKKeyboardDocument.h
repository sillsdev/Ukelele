//
//  UKKeyboardDocument.h
//  Ukelele Cocoa
//
//  Created by John Brownie on 13/06/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class UkeleleKeyboardObject;
@class UKKeyboardController;

@interface IconImageTransformer : NSValueTransformer

@end

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
@property (nonatomic, strong) NSMutableArray *keyboardLayouts;
@property (strong) IBOutlet NSArrayController *keyboardLayoutsController;

- (IBAction)addOpenDocument:(id)sender;
- (IBAction)showVersionInfo:(id)sender;
- (IBAction)addKeyboardLayout:(id)sender;
- (IBAction)removeKeyboardLayout:(id)sender;
- (IBAction)openKeyboardLayout:(id)sender;
- (IBAction)chooseIntendedLanguage:(id)sender;
- (IBAction)captureInputSource:(id)sender;
- (IBAction)openKeyboardFile:(id)sender;
- (IBAction)attachIconFile:(id)sender;
- (IBAction)askKeyboardIdentifiers:(id)sender;
- (IBAction)installForCurrentUser:(id)sender;
- (IBAction)installForAllUsers:(id)sender;

- (void)notifyNewName:(NSString *)newName forDocument:(id)keyboardDocument;
- (void)inspectorDidActivateTab:(NSString *)tabIdentifier;
- (void)keyboardLayoutDidChange:(UkeleleKeyboardObject *)keyboardObject;

- (UKKeyboardController *)controllerForCurrentEntry;

@end

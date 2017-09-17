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
@class KeyboardLayoutInformation;

@interface IconImageTransformer : NSValueTransformer

@end

@interface UKKeyboardDocument : NSDocument<NSWindowDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTabViewDelegate>

@property (strong) IBOutlet NSTableView *keyboardLayoutsTable;
@property (strong) IBOutlet NSButton *languageButton;
@property (strong) IBOutlet NSButton *removeKeyboardButton;
@property (strong) IBOutlet NSTabView *tabView;
@property (strong) IBOutlet NSTableView *localisationsTable;
@property (strong) IBOutlet NSButton *removeLocaleButton;

@property (nonatomic, strong) NSString *bundleVersion;
@property (nonatomic, strong) NSString *buildVersion;
@property (nonatomic, strong) NSString *sourceVersion;
@property (strong) NSString *bundleIdentifier;
@property (nonatomic, strong) NSString *bundleName;
@property (nonatomic) BOOL isBundle;
@property (strong, nonatomic) UkeleleKeyboardObject *keyboardLayout;
@property (nonatomic, strong) NSMutableArray *keyboardLayouts;
@property (strong) IBOutlet NSArrayController *keyboardLayoutsController;
@property (NS_NONATOMIC_IOSONLY, readonly, strong) UKKeyboardController *controllerForCurrentEntry;
@property (nonatomic, strong) NSMutableArray *localisations;
@property (strong) IBOutlet NSArrayController *localisationsController;

- (instancetype)initWithKeyboardObject:(UkeleleKeyboardObject *)keyboardObject;

- (IBAction)addOpenDocument:(id)sender;
- (IBAction)showVersionInfo:(id)sender;
- (IBAction)addKeyboardLayout:(id)sender;
- (IBAction)removeKeyboardLayout:(id)sender;
- (IBAction)openKeyboardLayout:(id)sender;
- (IBAction)chooseIntendedLanguage:(id)sender;
- (IBAction)removeIntendedLanguage:(id)sender;
- (IBAction)captureInputSource:(id)sender;
- (IBAction)openKeyboardFile:(id)sender;
- (IBAction)attachIconFile:(id)sender;
- (IBAction)removeIcon:(id)sender;
- (IBAction)askKeyboardIdentifiers:(id)sender;
- (IBAction)localiseKeyboardName:(id)sender;
- (IBAction)installForCurrentUser:(id)sender;
- (IBAction)installForAllUsers:(id)sender;
- (IBAction)duplicateKeyboardLayout:(id)sender;
- (IBAction)exportKeyboardLayout:(id)sender;
- (IBAction)addLocale:(id)sender;
- (IBAction)removeLocale:(id)sender;
- (IBAction)editLocale:(id)sender;
- (UKKeyboardController *)createControllerForEntry:(KeyboardLayoutInformation *)keyboardEntry;

- (void)notifyNewName:(NSString *)newName forDocument:(id)keyboardDocument withOldName:(NSString *)oldName;
- (void)inspectorDidAppear;
- (void)inspectorDidActivateTab:(NSString *)tabIdentifier;
- (void)keyboardLayoutDidChange:(UkeleleKeyboardObject *)keyboardObject;

@end

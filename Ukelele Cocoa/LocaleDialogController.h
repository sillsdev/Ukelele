//
//  LocaleDialogController.h
//  Ukelele
//
//  Created by John Brownie on 20/10/16.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LanguageRegistry.h"

@interface LocaleDialogController : NSWindowController<NSTableViewDelegate, NSTableViewDataSource>

@property (weak) IBOutlet NSSearchField *languageSearch;
@property (weak) IBOutlet NSTableView *languageTable;
@property (weak) IBOutlet NSTextField *languageMissingWarning;
@property (weak) IBOutlet NSSearchField *scriptSearch;
@property (weak) IBOutlet NSTableView *scriptTable;
@property (weak) IBOutlet NSSearchField *regionSearch;
@property (weak) IBOutlet NSTableView *regionTable;
@property (weak) IBOutlet NSTextField *localeUsedWarning;

+ (LocaleDialogController *)localeDialog;
- (void)beginLocaleDialog:(LocaleCode *)initialCode
				forWindow:(NSWindow *)theWindow
				 callBack:(BOOL (^)(LocaleCode *))theCallBack;

- (IBAction)acceptLocale:(id)sender;
- (IBAction)cancelLocale:(id)sender;
- (IBAction)searchLanguage:(id)sender;
- (IBAction)searchScript:(id)sender;
- (IBAction)searchRegion:(id)sender;

@end

//
//  IntendedLanguageSheet.h
//  Ukelele 3
//
//  Created by John Brownie on 14/10/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LanguageRegistry.h"

@interface IntendedLanguageSheet : NSWindowController<NSTableViewDataSource> {
	LanguageRegistry *languageRegistry;
	NSArray *languageList;
	NSArray *scriptList;
	NSArray *regionList;
	NSArray *variantList;
	NSWindow *parentWindow;
	void (^callBack)(LanguageCode *);
}

@property (strong) IBOutlet NSSearchField *languageSearch;
@property (strong) IBOutlet NSSearchField *scriptSearch;
@property (strong) IBOutlet NSSearchField *regionSearch;
@property (strong) IBOutlet NSSearchField *variantSearch;
@property (strong) IBOutlet NSTextField *languageRequired;
@property (strong) IBOutlet NSTableView *languageTable;
@property (strong) IBOutlet NSTableView *scriptTable;
@property (strong) IBOutlet NSTableView *regionTable;
@property (strong) IBOutlet NSTableView *variantTable;

+ (IntendedLanguageSheet *)intendedLanguageSheet;
- (void)beginIntendedLanguageSheet:(LanguageCode *)initialCode
						 forWindow:(NSWindow *)parentWindow
						  callBack:(void (^)(LanguageCode *))theCallBack;

- (IBAction)acceptLanguage:(id)sender;
- (IBAction)cancelLanguage:(id)sender;
- (IBAction)searchLanguage:(id)sender;
- (IBAction)searchScript:(id)sender;
- (IBAction)searchRegion:(id)sender;
- (IBAction)searchVariant:(id)sender;

@end

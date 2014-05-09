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

@property (weak, readonly) IBOutlet NSSearchField *languageSearch;
@property (weak, readonly) IBOutlet NSSearchField *scriptSearch;
@property (weak, readonly) IBOutlet NSSearchField *regionSearch;
@property (weak, readonly) IBOutlet NSSearchField *variantSearch;
@property (weak, readonly) IBOutlet NSTextField *languageRequired;
@property (weak, readonly) IBOutlet NSTableView *languageTable;
@property (weak, readonly) IBOutlet NSTableView *scriptTable;
@property (weak, readonly) IBOutlet NSTableView *regionTable;
@property (weak, readonly) IBOutlet NSTableView *variantTable;

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

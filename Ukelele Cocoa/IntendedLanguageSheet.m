//
//  IntendedLanguageSheet.m
//  Ukelele 3
//
//  Created by John Brownie on 14/10/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "IntendedLanguageSheet.h"

@interface IntendedLanguageSheet ()

@end

@implementation IntendedLanguageSheet

@synthesize languageTable;
@synthesize languageSearch;
@synthesize languageRequired;
@synthesize scriptTable;
@synthesize scriptSearch;
@synthesize regionTable;
@synthesize regionSearch;
@synthesize variantTable;
@synthesize variantSearch;

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:@"IntendedLanguageSheet"];
    if (self) {
        // Initialization code here.
		languageRegistry = [LanguageRegistry getInstance];
		languageList = [languageRegistry searchLanguage:nil];
		scriptList = [languageRegistry searchScript:nil];
		regionList = [languageRegistry searchRegion:nil];
		variantList = [languageRegistry searchVariant:nil];
		callBack = nil;
    }
    
    return self;
}

+ (IntendedLanguageSheet *)intendedLanguageSheet {
	return [[IntendedLanguageSheet alloc] initWithWindowNibName:@"IntendedLanguageSheet"];
}


- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[languageTable reloadData];
	[scriptTable reloadData];
	[regionTable reloadData];
	[variantTable reloadData];
}

- (void)beginIntendedLanguageSheet:(LanguageCode *)initialCode
						 forWindow:(NSWindow *)theWindow
						  callBack:(void (^)(LanguageCode *))theCallBack {
	parentWindow = theWindow;
	callBack = theCallBack;
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
	[self setSelection:initialCode];
}

#pragma mark Action methods

- (IBAction)acceptLanguage:(id)sender {
	if ([languageTable selectedRow] == -1) {
			// No selection!
		[languageRequired setHidden:NO];
		return;
	}
	LanguageCode *selectedCode = [self getSelectedLanguage];
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(selectedCode);
}

- (IBAction)cancelLanguage:(id)sender {
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(nil);
}

#pragma mark Table methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	if (tableView == languageTable) {
		return [languageList count];
	}
	else if (tableView == scriptTable) {
		return [scriptList count];
	}
	else if (tableView == regionTable) {
		return [regionList count];
	}
	else if (tableView == variantTable) {
		return [variantList count];
	}
	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	LanguageRegistryEntry *languageEntry;
	if (tableView == languageTable) {
		languageEntry = languageList[row];
		return [languageEntry valueForKey:[tableColumn identifier]];
	}
	else if (tableView == scriptTable) {
		languageEntry = scriptList[row];
		return [languageEntry valueForKey:[tableColumn identifier]];
	}
	else if (tableView == regionTable) {
		languageEntry = regionList[row];
		return [languageEntry valueForKey:[tableColumn identifier]];
	}
	else if (tableView == variantTable) {
		languageEntry = variantList[row];
		return [languageEntry valueForKey:[tableColumn identifier]];
	}
	return @"";
}

#pragma mark Filter methods

- (IBAction)searchLanguage:(id)sender {
	NSInteger selectedRow = [languageTable selectedRow];
	LanguageRegistryEntry *selectedLanguage = nil;
	if (selectedRow >= 0) {
		selectedLanguage = languageList[selectedRow];
	}
	NSString *searchString = [languageSearch stringValue];
	NSArray *filteredLanguages = [languageRegistry searchLanguage:searchString];
	languageList = filteredLanguages;
	[languageTable reloadData];
	if (selectedRow >= 0) {
			// Restore selection
		NSUInteger languageCount = [languageList count];
		selectedRow = -1;
		for (NSUInteger i = 0; i < languageCount; i++) {
			if ([selectedLanguage isEqualTo:languageList[i]]) {
				selectedRow = i;
				break;
			}
		}
		if (selectedRow >= 0) {
			[languageTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
			[languageTable scrollRowToVisible:selectedRow];
		}
		else {
			[languageTable deselectAll:self];
		}
	}
}

- (IBAction)searchScript:(id)sender {
	NSInteger selectedRow = [scriptTable selectedRow];
	LanguageRegistryEntry *selectedScript = nil;
	if (selectedRow >= 0) {
		selectedScript = scriptList[selectedRow];
	}
	NSString *searchString = [scriptSearch stringValue];
	NSArray *filteredScripts = [languageRegistry searchScript:searchString];
	scriptList = filteredScripts;
	[scriptTable reloadData];
	if (selectedRow >= 0) {
			// Restore selection
		NSUInteger scriptCount = [scriptList count];
		selectedRow = -1;
		for (NSUInteger i = 0; i < scriptCount; i++) {
			if ([selectedScript isEqualTo:scriptList[i]]) {
				selectedRow = i;
				break;
			}
		}
		if (selectedRow >= 0) {
			[scriptTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
			[scriptTable scrollRowToVisible:selectedRow];
		}
		else {
			[scriptTable deselectAll:self];
		}
	}
}

- (IBAction)searchRegion:(id)sender {
	NSInteger selectedRow = [regionTable selectedRow];
	LanguageRegistryEntry *selectedRegion = nil;
	if (selectedRow >= 0) {
		selectedRegion = regionList[selectedRow];
	}
	NSString *searchString = [regionSearch stringValue];
	NSArray *filteredRegions = [languageRegistry searchRegion:searchString];
	regionList = filteredRegions;
	[regionTable reloadData];
	if (selectedRow >= 0) {
			// Restore selection
		NSUInteger regionCount = [regionList count];
		selectedRow = -1;
		for (NSUInteger i = 0; i < regionCount; i++) {
			if ([selectedRegion isEqualTo:regionList[i]]) {
				selectedRow = i;
				break;
			}
		}
		if (selectedRow >= 0) {
			[regionTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
			[regionTable scrollRowToVisible:selectedRow];
		}
		else {
			[regionTable deselectAll:self];
		}
	}
}

- (IBAction)searchVariant:(id)sender {
	NSInteger selectedRow = [variantTable selectedRow];
	LanguageRegistryEntry *selectedVariant = nil;
	if (selectedRow >= 0) {
		selectedVariant = variantList[selectedRow];
	}
	NSString *searchString = [variantSearch stringValue];
	NSArray *filteredVariants = [languageRegistry searchVariant:searchString];
	variantList = filteredVariants;
	[variantTable reloadData];
	if (selectedRow >= 0) {
			// Restore selection
		NSUInteger variantCount = [variantList count];
		selectedRow = -1;
		for (NSUInteger i = 0; i < variantCount; i++) {
			if ([selectedVariant isEqualTo:variantList[i]]) {
				selectedRow = i;
				break;
			}
		}
		if (selectedRow >= 0) {
			[variantTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
			[variantTable scrollRowToVisible:selectedRow];
		}
		else {
			[variantTable deselectAll:self];
		}
	}
}

#pragma mark Selection handling

- (void)setSelection:(LanguageCode *)languageCode {
	NSString *language = [languageCode languageCode];
	[languageTable deselectAll:self];
	if (language && ![language isEqualToString:@""]) {
			// Find the code in the list
		NSUInteger languageCount = [languageList count];
		NSInteger languageIndex = -1;
		for (NSUInteger i = 0; i < languageCount; i++) {
			LanguageRegistryEntry *languageEntry = languageList[i];
			if ([language compare:[languageEntry code] options:NSCaseInsensitiveSearch] == NSOrderedSame) {
				languageIndex = i;
				break;
			}
		}
		if (languageIndex >= 0) {
			NSIndexSet *selectionSet = [NSIndexSet indexSetWithIndex:languageIndex];
			[languageTable selectRowIndexes:selectionSet byExtendingSelection:NO];
			[languageTable scrollRowToVisible:languageIndex];
		}
	}
	NSString *script = [languageCode scriptCode];
	[scriptTable deselectAll:self];
	if (script && ![script isEqualToString:@""]) {
			// Find the code in the list
		NSUInteger scriptCount = [scriptList count];
		NSInteger scriptIndex = -1;
		for (NSUInteger i = 0; i < scriptCount; i++) {
			LanguageRegistryEntry *scriptEntry = scriptList[i];
			if ([script compare:[scriptEntry code] options:NSCaseInsensitiveSearch] == NSOrderedSame) {
				scriptIndex = i;
				break;
			}
		}
		if (scriptIndex >= 0) {
			NSIndexSet *selectionSet = [NSIndexSet indexSetWithIndex:scriptIndex];
			[scriptTable selectRowIndexes:selectionSet byExtendingSelection:NO];
			[scriptTable scrollRowToVisible:scriptIndex];
		}
	}
	NSString *region = [languageCode regionCode];
	[regionTable deselectAll:self];
	if (region && ![region isEqualToString:@""]) {
			// Find the code in the list
		NSUInteger regionCount = [regionList count];
		NSInteger regionIndex = -1;
		for (NSUInteger i = 0; i < regionCount; i++) {
			LanguageRegistryEntry *regionEntry = regionList[i];
			if ([region compare:[regionEntry code] options:NSCaseInsensitiveSearch] == NSOrderedSame) {
				regionIndex = i;
				break;
			}
		}
		if (regionIndex >= 0) {
			NSIndexSet *selectionSet = [NSIndexSet indexSetWithIndex:regionIndex];
			[regionTable selectRowIndexes:selectionSet byExtendingSelection:NO];
			[regionTable scrollRowToVisible:regionIndex];
		}
	}
	NSString *variant = [languageCode variantCode];
	[variantTable deselectAll:self];
	if (variant && ![variant isEqualToString:@""]) {
			// Find the code in the list
		NSUInteger variantCount = [variantList count];
		NSInteger variantIndex = -1;
		for (NSUInteger i = 0; i < variantCount; i++) {
			LanguageRegistryEntry *variantEntry = variantList[i];
			if ([variant compare:[variantEntry code] options:NSCaseInsensitiveSearch] == NSOrderedSame) {
				variantIndex = i;
				break;
			}
		}
		if (variantIndex >= 0) {
			NSIndexSet *selectionSet = [NSIndexSet indexSetWithIndex:variantIndex];
			[variantTable selectRowIndexes:selectionSet byExtendingSelection:NO];
			[variantTable scrollRowToVisible:variantIndex];
		}
	}
}

- (LanguageCode *)getSelectedLanguage {
	LanguageCode *languageCode = [[LanguageCode alloc] init];
	NSInteger selectionIndex = [languageTable selectedRow];
	if (selectionIndex >= 0) {
		LanguageRegistryEntry *languageEntry = languageList[selectionIndex];
		[languageCode setLanguageCode:[languageEntry code]];
	}
	selectionIndex = [scriptTable selectedRow];
	if (selectionIndex >= 0) {
		LanguageRegistryEntry *scriptEntry = scriptList[selectionIndex];
		[languageCode setScriptCode:[scriptEntry code]];
	}
	selectionIndex = [regionTable selectedRow];
	if (selectionIndex >= 0) {
		LanguageRegistryEntry *regionEntry = regionList[selectionIndex];
		[languageCode setRegionCode:[regionEntry code]];
	}
	selectionIndex = [variantTable selectedRow];
	if (selectionIndex >= 0) {
		LanguageRegistryEntry *variantEntry = variantList[selectionIndex];
		[languageCode setVariantCode:[variantEntry code]];
	}
	return [languageRegistry normaliseLanguageCode:languageCode];
}

@end

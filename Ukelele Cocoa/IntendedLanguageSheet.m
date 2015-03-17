//
//  IntendedLanguageSheet.m
//  Ukelele 3
//
//  Created by John Brownie on 14/10/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "IntendedLanguageSheet.h"

@implementation IntendedLanguageSheet

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
	[self.languageTable reloadData];
	[self.scriptTable reloadData];
	[self.regionTable reloadData];
	[self.variantTable reloadData];
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
	if ([self.languageTable selectedRow] == -1) {
			// No selection!
		[self.languageRequired setHidden:NO];
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
	if (tableView == self.languageTable) {
		return [languageList count];
	}
	else if (tableView == self.scriptTable) {
		return [scriptList count];
	}
	else if (tableView == self.regionTable) {
		return [regionList count];
	}
	else if (tableView == self.variantTable) {
		return [variantList count];
	}
	return 0;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	LanguageRegistryEntry *languageEntry;
	if (tableView == self.languageTable) {
		languageEntry = languageList[row];
		return [languageEntry valueForKey:[tableColumn identifier]];
	}
	else if (tableView == self.scriptTable) {
		languageEntry = scriptList[row];
		return [languageEntry valueForKey:[tableColumn identifier]];
	}
	else if (tableView == self.regionTable) {
		languageEntry = regionList[row];
		return [languageEntry valueForKey:[tableColumn identifier]];
	}
	else if (tableView == self.variantTable) {
		languageEntry = variantList[row];
		return [languageEntry valueForKey:[tableColumn identifier]];
	}
	return @"";
}

#pragma mark Filter methods

- (IBAction)searchLanguage:(id)sender {
	NSInteger selectedRow = [self.languageTable selectedRow];
	LanguageRegistryEntry *selectedLanguage = nil;
	if (selectedRow >= 0) {
		selectedLanguage = languageList[selectedRow];
	}
	NSString *searchString = [self.languageSearch stringValue];
	NSArray *filteredLanguages = [languageRegistry searchLanguage:searchString];
	languageList = filteredLanguages;
	[self.languageTable reloadData];
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
			[self.languageTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
			[self.languageTable scrollRowToVisible:selectedRow];
		}
		else {
			[self.languageTable deselectAll:self];
		}
	}
}

- (IBAction)searchScript:(id)sender {
	NSInteger selectedRow = [self.scriptTable selectedRow];
	LanguageRegistryEntry *selectedScript = nil;
	if (selectedRow >= 0) {
		selectedScript = scriptList[selectedRow];
	}
	NSString *searchString = [self.scriptSearch stringValue];
	NSArray *filteredScripts = [languageRegistry searchScript:searchString];
	scriptList = filteredScripts;
	[self.scriptTable reloadData];
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
			[self.scriptTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
			[self.scriptTable scrollRowToVisible:selectedRow];
		}
		else {
			[self.scriptTable deselectAll:self];
		}
	}
}

- (IBAction)searchRegion:(id)sender {
	NSInteger selectedRow = [self.regionTable selectedRow];
	LanguageRegistryEntry *selectedRegion = nil;
	if (selectedRow >= 0) {
		selectedRegion = regionList[selectedRow];
	}
	NSString *searchString = [self.regionSearch stringValue];
	NSArray *filteredRegions = [languageRegistry searchRegion:searchString];
	regionList = filteredRegions;
	[self.regionTable reloadData];
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
			[self.regionTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
			[self.regionTable scrollRowToVisible:selectedRow];
		}
		else {
			[self.regionTable deselectAll:self];
		}
	}
}

- (IBAction)searchVariant:(id)sender {
	NSInteger selectedRow = [self.variantTable selectedRow];
	LanguageRegistryEntry *selectedVariant = nil;
	if (selectedRow >= 0) {
		selectedVariant = variantList[selectedRow];
	}
	NSString *searchString = [self.variantSearch stringValue];
	NSArray *filteredVariants = [languageRegistry searchVariant:searchString];
	variantList = filteredVariants;
	[self.variantTable reloadData];
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
			[self.variantTable selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
			[self.variantTable scrollRowToVisible:selectedRow];
		}
		else {
			[self.variantTable deselectAll:self];
		}
	}
}

#pragma mark Selection handling

- (void)setSelection:(LanguageCode *)languageCode {
	NSString *language = [languageCode languageCode];
	[self.languageTable deselectAll:self];
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
			[self.languageTable selectRowIndexes:selectionSet byExtendingSelection:NO];
			[self.languageTable scrollRowToVisible:languageIndex];
		}
	}
	NSString *script = [languageCode scriptCode];
	[self.scriptTable deselectAll:self];
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
			[self.scriptTable selectRowIndexes:selectionSet byExtendingSelection:NO];
			[self.scriptTable scrollRowToVisible:scriptIndex];
		}
	}
	NSString *region = [languageCode regionCode];
	[self.regionTable deselectAll:self];
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
			[self.regionTable selectRowIndexes:selectionSet byExtendingSelection:NO];
			[self.regionTable scrollRowToVisible:regionIndex];
		}
	}
	NSString *variant = [languageCode variantCode];
	[self.variantTable deselectAll:self];
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
			[self.variantTable selectRowIndexes:selectionSet byExtendingSelection:NO];
			[self.variantTable scrollRowToVisible:variantIndex];
		}
	}
}

- (LanguageCode *)getSelectedLanguage {
	LanguageCode *languageCode = [[LanguageCode alloc] init];
	NSInteger selectionIndex = [self.languageTable selectedRow];
	if (selectionIndex >= 0) {
		LanguageRegistryEntry *languageEntry = languageList[selectionIndex];
		[languageCode setLanguageCode:[languageEntry code]];
	}
	selectionIndex = [self.scriptTable selectedRow];
	if (selectionIndex >= 0) {
		LanguageRegistryEntry *scriptEntry = scriptList[selectionIndex];
		[languageCode setScriptCode:[scriptEntry code]];
	}
	selectionIndex = [self.regionTable selectedRow];
	if (selectionIndex >= 0) {
		LanguageRegistryEntry *regionEntry = regionList[selectionIndex];
		[languageCode setRegionCode:[regionEntry code]];
	}
	selectionIndex = [self.variantTable selectedRow];
	if (selectionIndex >= 0) {
		LanguageRegistryEntry *variantEntry = variantList[selectionIndex];
		[languageCode setVariantCode:[variantEntry code]];
	}
	return [languageRegistry normaliseLanguageCode:languageCode];
}

@end

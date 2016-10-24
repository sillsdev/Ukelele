//
//  LocaleDialogController.m
//  Ukelele
//
//  Created by John Brownie on 20/10/16.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#import "LocaleDialogController.h"

@interface LocaleDialogController ()

@end

@implementation LocaleDialogController {
	LanguageRegistry *languageRegistry;
	NSArray *languageList;
	NSArray *scriptList;
	NSArray *regionList;
	NSWindow *parentWindow;
	void (^callBack)(LocaleCode *);
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner {
	[[NSBundle mainBundle] loadNibNamed:@"LocaleDialog" owner:self topLevelObjects:nil];
	self = [super initWithWindowNibName:windowNibName owner:owner];
	if (self) {
		languageRegistry = [LanguageRegistry getInstance];
		languageList = [languageRegistry searchLanguage:nil];
		scriptList = [languageRegistry searchScript:nil];
		regionList = [languageRegistry searchRegion:nil];
		parentWindow = nil;
		callBack = nil;
	}
	return self;
}

+ (LocaleDialogController *)localeDialog {
	return [[LocaleDialogController alloc] initWithWindowNibName:@"LocaleDialog" owner:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[self.languageTable reloadData];
	[self.scriptTable reloadData];
	[self.regionTable reloadData];
}

- (void)beginLocaleDialog:(LocaleCode *)initialCode
				forWindow:(NSWindow *)theWindow
				 callBack:(void (^)(LocaleCode *))theCallBack {
	parentWindow = theWindow;
	callBack = theCallBack;
	[NSApp beginSheet:self.window modalForWindow:parentWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
	[self.languageSearch setStringValue:@""];
	[self.scriptSearch setStringValue:@""];
	[self.regionSearch setStringValue:@""];
	[self setSelection:initialCode];
}

#pragma mark Action methods

- (IBAction)acceptLocale:(id)sender {
#pragma unused(sender)
	if ([self.languageTable selectedRow] == -1) {
			// No selection!
		[self.languageMissingWarning setHidden:NO];
		return;
	}
	LocaleCode *selectedCode = [self getSelectedLocale];
	[self.window orderOut:self];
	[NSApp endSheet:self.window];
	callBack(selectedCode);
}

- (IBAction)cancelLocale:(id)sender {
#pragma unused(sender)
	[self.window orderOut:self];
	[NSApp endSheet:self.window];
	callBack(nil);
}

#pragma mark Table methods

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSTableCellView *view = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:self];
	if (view == nil) {
		view = [[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, [tableColumn width], 10)];
		[view setIdentifier:[tableColumn identifier]];
	}
	[view.textField setStringValue:[self tableView:tableView objectValueForTableColumn:tableColumn row:row]];
	return view;
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
#pragma unused(tableView)
#pragma unused(tableColumn)
#pragma unused(row)
	return NO;
}


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
	return @"";
}

#pragma mark Filter methods

- (IBAction)searchLanguage:(id)sender {
#pragma unused(sender)
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
			[self.languageTable scrollRowToVisible:0];
		}
	}
}

- (IBAction)searchScript:(id)sender {
#pragma unused(sender)
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
			[self.scriptTable scrollRowToVisible:0];
		}
	}
}

- (IBAction)searchRegion:(id)sender {
#pragma unused(sender)
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
			[self.regionTable scrollRowToVisible:0];
		}
	}
}

#pragma mark Selection Handling

- (void)setSelection:(LocaleCode *)localeCode {
	NSString *language = [localeCode languageCode];
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
		else {
			[self.languageTable scrollRowToVisible:0];
		}
	}
	else {
		languageList = [languageRegistry searchLanguage:@""];
		[self.languageTable reloadData];
		[self.languageTable scrollRowToVisible:0];
	}
	NSString *script = [localeCode scriptCode];
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
		else {
			[self.scriptTable scrollRowToVisible:0];
		}
	}
	else {
		scriptList = [languageRegistry searchScript:@""];
		[self.scriptTable reloadData];
		[self.scriptTable scrollRowToVisible:0];
	}
	NSString *region = [localeCode regionCode];
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
		else {
			[self.regionTable scrollRowToVisible:0];
		}
	}
	else {
		regionList = [languageRegistry searchRegion:@""];
		[self.regionTable reloadData];
		[self.regionTable scrollRowToVisible:0];
	}
}

- (LocaleCode *)getSelectedLocale {
	LocaleCode *localeCode = [[LocaleCode alloc] init];
	NSInteger selectionIndex = [self.languageTable selectedRow];
	if (selectionIndex >= 0) {
		LanguageRegistryEntry *languageEntry = languageList[selectionIndex];
		[localeCode setLanguageCode:[languageEntry code]];
	}
	selectionIndex = [self.scriptTable selectedRow];
	if (selectionIndex >= 0) {
		LanguageRegistryEntry *scriptEntry = scriptList[selectionIndex];
		[localeCode setScriptCode:[scriptEntry code]];
	}
	selectionIndex = [self.regionTable selectedRow];
	if (selectionIndex >= 0) {
		LanguageRegistryEntry *regionEntry = regionList[selectionIndex];
		[localeCode setRegionCode:[regionEntry code]];
	}
	return localeCode;
}

@end

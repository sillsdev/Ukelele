//
//  LocalisationsWindowController.m
//  Ukelele
//
//  Created by John Brownie on 12/10/16.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#import "LocalisationsWindowController.h"
#import "LanguageRegistry.h"
#import "LocaleDialogController.h"

@interface LocalisationsWindowController ()

@property (strong) NSMutableArray *currentLocalisations;

@end

@implementation LocalisationsWindowController {
    LanguageRegistry *languageRegistry;
	LocaleDialogController *localeDialog;
    void (^callback)(NSString *, NSString *);
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName {
    [[NSBundle mainBundle] loadNibNamed:@"LocalisationsWindow" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        self.currentLocalisations = [NSMutableArray array];
        self.localeList = [NSMutableArray array];
        self.localeDescriptionList = [NSMutableArray array];
        languageRegistry = [LanguageRegistry getInstance];
		localeDialog = nil;
        callback = nil;
    }
    return self;
}

+ (LocalisationsWindowController *)localisationsWindowWithLocalisations:(NSArray *)localisations {
    LocalisationsWindowController *theController = [[LocalisationsWindowController alloc] initWithWindowNibName:@"LocalisationsWindow"];
    theController.currentLocalisations = [localisations mutableCopy];
    [theController readLocales];
    return theController;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)beginLocalisationsForCollection:(NSString *)collectionName withCallback:(void (^)(NSString *, NSString *))theCallback {
	NSString *windowName = [NSString stringWithFormat:@"%@ Localisations", collectionName];
	[self.window setTitle:windowName];
    callback = theCallback;
	[self.window makeKeyAndOrderFront:self];
}

- (void)displayWindow {
	[self.window makeKeyAndOrderFront:self];
}

- (IBAction)editLocalisation:(id)sender {
#pragma unused(sender)
	if (localeDialog == nil) {
		localeDialog = [LocaleDialogController localeDialog];
	}
	NSInteger selectedRow = [self.localisationsTable clickedRow];
	NSAssert(selectedRow != -1, @"Must have a selected row");
	__block LocaleCode *currentLocale = [LocaleCode localeCodeFromString:self.localeList[selectedRow]];
	[localeDialog beginLocaleDialog:currentLocale forWindow:self.window callBack:^(LocaleCode *theLocale) {
		if (theLocale != nil) {
				// Got an edited locale
			self.localeList[selectedRow] = [theLocale stringRepresentation];
			self.localeDescriptionList[selectedRow] = [languageRegistry descriptionForLocaleCode:theLocale];
			callback([currentLocale stringRepresentation], [theLocale stringRepresentation]);
			[self.localisationsTable reloadData];
		}
	}];
}

- (IBAction)addLocalisation:(id)sender {
#pragma unused(sender)
	if (localeDialog == nil) {
		localeDialog = [LocaleDialogController localeDialog];
	}
	__block LocaleCode *currentLocale = [LocaleCode localeCodeFromString:@""];
	[localeDialog beginLocaleDialog:currentLocale forWindow:self.window callBack:^(LocaleCode *theLocale) {
		if (theLocale != nil) {
				// Got a new locale
			[self.localeList addObject:[theLocale stringRepresentation]];
			[self.localeDescriptionList addObject:[languageRegistry descriptionForLocaleCode:theLocale]];
			callback(nil, [theLocale stringRepresentation]);
			[self.localisationsTable reloadData];
		}
	}];
}

- (IBAction)removeLocalisation:(id)sender {
#pragma unused(sender)
    NSAssert([self.localisationsTable selectedRow] != -1, @"Must have a selected row");
    NSInteger selectedRow = [self.localisationsTable selectedRow];
	NSString *oldLocale = self.localeList[selectedRow];
    [self.localeList removeObjectAtIndex:selectedRow];
    [self.localeDescriptionList removeObjectAtIndex:selectedRow];
    [self.localisationsTable reloadData];
	callback(oldLocale, nil);
}

- (IBAction)endLocalisations:(id)sender {
#pragma unused(sender)
    [self.window orderOut:self];
    callback(nil, nil);
}

#pragma mark Manage locales

- (void)readLocales {
    [self.localeList removeAllObjects];
    [self.localeDescriptionList removeAllObjects];
    for (NSUInteger i = 0; i < [self.currentLocalisations count]; i++) {
        NSString *theLocale = self.currentLocalisations[i];
        LocaleCode *localeCode = [LocaleCode localeCodeFromString:theLocale];
        if (localeCode != nil) {
            [self.localeList addObject:[localeCode stringRepresentation]];
            [self.localeDescriptionList addObject:[languageRegistry descriptionForLocaleCode:localeCode]];
        }
    }
}

#pragma mark Table Delegate Methods

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

#pragma mark Table Data Source Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
#pragma unused(tableView)
    return [self.localeList count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
#pragma unused(tableView)
    if ([[tableColumn identifier] isEqualToString:@"LocaleCode"]) {
        return self.localeList[row];
    }
    else if ([[tableColumn identifier] isEqualToString:@"LocaleName"]) {
        return self.localeDescriptionList[row];
    }
    else {
        return nil;
    }
}

@end

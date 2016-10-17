//
//  LocalisationsDialogController.m
//  Ukelele
//
//  Created by John Brownie on 12/10/16.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#import "LocalisationsDialogController.h"
#import "LanguageRegistry.h"

@interface LocalisationsDialogController ()

@property (strong) NSMutableArray *currentLocalisations;

@end

@implementation LocalisationsDialogController {
    NSWindow *parentWindow;
    LanguageRegistry *languageRegistry;
    void (^callback)(NSArray *);
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName {
    [[NSBundle mainBundle] loadNibNamed:@"LocalisationsDialog" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        self.currentLocalisations = [NSMutableArray array];
        self.localeList = [NSMutableArray array];
        self.localeDescriptionList = [NSMutableArray array];
        parentWindow = nil;
        languageRegistry = [LanguageRegistry getInstance];
        callback = nil;
    }
    return self;
}

+ (LocalisationsDialogController *)localisationsDialogWithLocalisations:(NSArray *)localisations {
    LocalisationsDialogController *theController = [[LocalisationsDialogController alloc] initWithWindowNibName:@"LocalisationsDialog"];
    theController.currentLocalisations = [localisations mutableCopy];
    [theController readLocales];
    return theController;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)beginLocalisationsForWindow:(NSWindow *)theParentWindow withCallback:(void (^)(NSArray *))theCallback {
    parentWindow = theParentWindow;
    callback = theCallback;
    [NSApp beginSheet:self.window modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)editLocalisation:(id)sender {
#pragma unused(sender)
    
}

- (IBAction)addLocalisation:(id)sender {
#pragma unused(sender)
}

- (IBAction)removeLocalisation:(id)sender {
#pragma unused(sender)
    NSAssert([self.localisationsTable selectedRow] != -1, @"Must have a selected row");
    NSInteger selectedRow = [self.localisationsTable selectedRow];
    [self.localeList removeObjectAtIndex:selectedRow];
    [self.localeDescriptionList removeObjectAtIndex:selectedRow];
    [self.localisationsTable reloadData];
}

- (IBAction)acceptLocalisations:(id)sender {
#pragma unused(sender)
    [self writeLocales];
    [self.window orderOut:self];
    [NSApp endSheet:self.window];
    callback(self.currentLocalisations);
}

- (IBAction)cancelLocalisations:(id)sender {
#pragma unused(sender)
    [self.window orderOut:self];
    [NSApp endSheet:self.window];
    callback(nil);
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

- (void)writeLocales {
    [self.currentLocalisations removeAllObjects];
    for (NSUInteger i = 0; i < [self.localeList count]; i++) {
        [self.currentLocalisations addObject:self.localeList[i]];
    }
}

#pragma mark Table Delegate Methods

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
#pragma unused(row)
    return [tableView makeViewWithIdentifier:[tableColumn identifier] owner:self];
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

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
    LanguageRegistry *languageRegistry;
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName {
    [[NSBundle mainBundle] loadNibNamed:@"LocalisationsDialog" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        self.currentLocalisations = [NSMutableArray array];
        languageRegistry = [LanguageRegistry getInstance];
    }
    return self;
}

+ (LocalisationsDialogController *)localisationsDialogWithLocalisations:(NSArray *)localisations {
    LocalisationsDialogController *theController = [[LocalisationsDialogController alloc] initWithWindowNibName:@"LocalisationsDialog"];
    theController.currentLocalisations = [localisations mutableCopy];
    [theController updateLocales];
    return theController;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)editLocalisation:(id)sender {
#pragma unused(sender)
    
}

- (IBAction)addLocalisation:(id)sender {
#pragma unused(sender)
}

- (IBAction)removeLocalisation:(id)sender {
#pragma unused(sender)
    
}

- (IBAction)acceptLocalisations:(id)sender {
#pragma unused(sender)
    
}

- (IBAction)cancelLocalisations:(id)sender {
#pragma unused(sender)
    
}

#pragma mark Manage locales

- (void)updateLocales {
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
    if ([[tableColumn identifier] isEqualToString:@"LanguageCode"]) {
        return self.localeList[row];
    }
    else if ([[tableColumn identifier] isEqualToString:@"LanguageName"]) {
        return self.localeDescriptionList[row];
    }
    else {
        return nil;
    }
}

@end

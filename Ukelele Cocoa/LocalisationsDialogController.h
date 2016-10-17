//
//  LocalisationsDialogController.h
//  Ukelele
//
//  Created by John Brownie on 12/10/16.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LocalisationsDialogController : NSWindowController<NSTableViewDelegate, NSTableViewDataSource>

@property (strong) NSMutableArray *localeList;
@property (strong) NSMutableArray *localeDescriptionList;

@property (weak) IBOutlet NSTableView *localisationsTable;
@property (weak) IBOutlet NSButton *removeLocaleButton;

- (IBAction)editLocalisation:(id)sender;
- (IBAction)addLocalisation:(id)sender;
- (IBAction)removeLocalisation:(id)sender;
- (IBAction)acceptLocalisations:(id)sender;
- (IBAction)cancelLocalisations:(id)sender;

+ (LocalisationsDialogController *)localisationsDialogWithLocalisations:(NSArray *)localisations;

@end

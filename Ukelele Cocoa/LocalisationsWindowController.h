//
//  LocalisationsDialogController.h
//  Ukelele
//
//  Created by John Brownie on 12/10/16.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LocalisationsWindowController : NSWindowController<NSTableViewDelegate, NSTableViewDataSource>

@property (strong) NSMutableArray *localeList;
@property (strong) NSMutableArray *localeDescriptionList;

@property (weak) IBOutlet NSTableView *localisationsTable;
@property (weak) IBOutlet NSButton *removeLocaleButton;

- (IBAction)editLocalisation:(id)sender;
- (IBAction)addLocalisation:(id)sender;
- (IBAction)removeLocalisation:(id)sender;
- (IBAction)endLocalisations:(id)sender;

+ (LocalisationsWindowController *)localisationsWindowWithLocalisations:(NSArray *)localisations;

- (void)beginLocalisationsForCollection:(NSString *)collectionName withCallback:(void (^)(NSString *, NSString *))theCallback;
- (void)displayWindow;

@end

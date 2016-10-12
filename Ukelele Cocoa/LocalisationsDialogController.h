//
//  LocalisationsDialogController.h
//  Ukelele
//
//  Created by John Brownie on 12/10/16.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LocalisationsDialogController : NSWindowController

@property (weak) IBOutlet NSTableView *localisationsTable;

- (IBAction)addLocalisation:(id)sender;
- (IBAction)removeLocalisation:(id)sender;

@end

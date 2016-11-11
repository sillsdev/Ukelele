//
//  LocaliseKeyboardController.h
//  Ukelele
//
//  Created by John Brownie on 10/11/16.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LocaliseKeyboardController : NSWindowController

@property (strong) IBOutlet NSTableView *localisationsTable;
@property (strong) IBOutlet NSDictionaryController *dictionaryController;

@property (strong) NSMutableDictionary *localisationsDictionary;

- (IBAction)acceptLocalisations:(id)sender;
- (IBAction)cancelLocalisations:(id)sender;

+ (LocaliseKeyboardController *)localiseKeyboardController;
- (void)beginDialogWithWindow:(NSWindow *)theWindow forLocalisations:(NSDictionary *)initialLocalisations withCallback:(void (^)(NSDictionary *))theCallback;

@end

//
//  AskImportState.h
//  Ukelele
//
//  Created by John Brownie on 16/07/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AskImportState : NSWindowController
@property (strong) IBOutlet NSTextField *ChooseStateText;
@property (strong) IBOutlet NSPopUpButton *ChooseStatePopup;
@property (strong) IBOutlet NSTextField *AskStateNameText;
@property (strong) IBOutlet NSTextField *AskStateNameField;
@property (strong) IBOutlet NSTextField *NameErrorText;
@property (strong) NSString *importPrompt;
@property (strong) NSString *destinationStatePrompt;

- (IBAction)acceptState:(id)sender;
- (IBAction)cancelState:(id)sender;

+ (AskImportState *)askImportState;

- (void)askImportFromState:(NSArray *)sourceStates excludingStates:(NSArray *)destinationStates withWindow:(NSWindow *)parentWindow completionBlock:(void (^)(NSString *, NSString *))callback;

@end

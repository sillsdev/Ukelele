//
//  UKKeyboardController+Comments.h
//  Ukelele Cocoa
//
//  Created by John Brownie on 12/06/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import "UKKeyboardController.h"

@interface UKKeyboardController (Comments)

- (IBAction)firstComment:(id)sender;
- (IBAction)previousComment:(id)sender;
- (IBAction)nextComment:(id)sender;
- (IBAction)lastComment:(id)sender;
- (IBAction)addComment:(id)sender;
- (IBAction)removeComment:(id)sender;

- (void)addCreationComment;
- (void)updateCommentFields;
- (void)saveUnsavedComment;
- (void)addComment:(NSString *)commentText toHolder:(XMLCommentHolderObject *)commentHolder;

@end

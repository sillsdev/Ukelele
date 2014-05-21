//
//  UkeleleDocument+Comments.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 21/05/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import "UkeleleDocument+Comments.h"

@implementation UkeleleDocument (Comments)

#pragma mark === Comments tab ===

- (void)addCreationComment {
	[self.keyboardLayout addCreationComment];
}

- (IBAction)addComment:(id)sender
{
    if (commentChanged) {
		[self saveUnsavedComment];
	}
    XMLCommentHolderObject *commentHolder = [self.keyboardLayout currentCommentHolder];
	if (!commentHolder) {
		commentHolder = [self.keyboardLayout documentCommentHolder];
	}
	[self addComment:@"" toHolder:commentHolder];
	[self updateCommentFields];
}

- (IBAction)removeComment:(id)sender
{
    XMLCommentHolderObject *commentHolder = [self.keyboardLayout currentCommentHolder];
	NSString *commentText = [self.keyboardLayout currentComment];
	[self removeComment:commentText fromHolder:commentHolder];
	if ([self.keyboardLayout currentComment]) {
			// There is a new current comment
		[self updateCommentFields];
	}
	else {
			// No more comments left
		[self clearCommentFields];
	}
}

- (IBAction)firstComment:(id)sender
{
    if (commentChanged) {
		[self saveUnsavedComment];
	}
	NSString *commentText = [self.keyboardLayout firstComment];
	[commentPane setString:commentText];
	[self updateCommentFields];
}

- (IBAction)previousComment:(id)sender
{
    if (commentChanged) {
		[self saveUnsavedComment];
	}
	NSString *commentText = [self.keyboardLayout previousComment];
	[commentPane setString:commentText];
	[self updateCommentFields];
}

- (IBAction)nextComment:(id)sender
{
    if (commentChanged) {
		[self saveUnsavedComment];
	}
	NSString *commentText = [self.keyboardLayout nextComment];
	[commentPane setString:commentText];
	[self updateCommentFields];
}

- (IBAction)lastComment:(id)sender
{
    if (commentChanged) {
		[self saveUnsavedComment];
	}
	NSString *commentText = [self.keyboardLayout lastComment];
	[commentPane setString:commentText];
	[self updateCommentFields];
}

- (void)updateCommentFields {
	if (commentChanged) {
			// Save the changed comment
		commentChanged = NO;
	}
		// Set the comment text pane
	NSString *commentText = [self.keyboardLayout currentComment];
	if (commentText) {
		[commentPane setString:commentText];
	}
		// Set the XML statement pane
	NSString *holderText = [self.keyboardLayout currentHolderText];
	if (holderText) {
		[commentBindingPane setStringValue:holderText];
	}
		// Set the button states
	if ([self.keyboardLayout isFirstComment]) {
		[firstCommentButton setEnabled:NO];
		[previousCommentButton setEnabled:NO];
	}
	else {
		[firstCommentButton setEnabled:YES];
		[previousCommentButton setEnabled:YES];
	}
	if ([self.keyboardLayout isLastComment]) {
		[lastCommentButton setEnabled:NO];
		[nextCommentButton setEnabled:NO];
	}
	else {
		[lastCommentButton setEnabled:YES];
		[nextCommentButton setEnabled:YES];
	}
	if ([self.keyboardLayout isEditableComment]) {
		[removeCommentButton setEnabled:YES];
		[commentPane setEditable:YES];
	}
	else {
		[removeCommentButton setEnabled:NO];
		[commentPane setEditable:NO];
	}
}

- (void)clearCommentFields {
	[commentPane setString:@""];
	[commentBindingPane setStringValue:@""];
	[firstCommentButton setEnabled:NO];
	[previousCommentButton setEnabled:NO];
	[nextCommentButton setEnabled:NO];
	[lastCommentButton setEnabled:NO];
	[removeCommentButton setEnabled:NO];
}

- (void)saveUnsavedComment {
	NSString *existingComment = [self.keyboardLayout currentComment];
	NSString *commentPaneContents = [[commentPane string] copy];
	XMLCommentHolderObject *currentHolder = [self.keyboardLayout currentCommentHolder];
	if (![commentPaneContents isEqualToString:existingComment]) {
		[self changeCommentTextFrom:existingComment to:commentPaneContents forHolder:currentHolder];
	}
	commentChanged = NO;
}

#pragma mark Undo routines

- (void)changeCommentTextFrom:(NSString *)oldText
						   to:(NSString *)newText
					forHolder:(XMLCommentHolderObject *)commentHolder {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] changeCommentTextFrom:newText to:oldText forHolder:commentHolder];
	[undoManager setActionName:@"Change comment"];
	[self.keyboardLayout changeCommentText:oldText to:newText forHolder:commentHolder];
	[self updateCommentFields];
}

- (void)addComment:(NSString *)commentText toHolder:(XMLCommentHolderObject *)commentHolder {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeComment:commentText fromHolder:commentHolder];
	[undoManager setActionName:[undoManager isUndoing] ? @"Remove comment" : @"Add comment"];
	[self.keyboardLayout addComment:commentText toHolder:commentHolder];
	[self updateCommentFields];
}

- (void)removeComment:(NSString *)commentText fromHolder:(XMLCommentHolderObject *)commentHolder {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] addComment:commentText toHolder:commentHolder];
	[undoManager setActionName:[undoManager isUndoing] ? @"Add comment" : @"Remove comment"];
	[self.keyboardLayout removeComment:commentText fromHolder:commentHolder];
	[self updateCommentFields];
}

#pragma mark Delegate methods

- (void)textDidChange:(NSNotification *)notification {
	commentChanged = YES;
}

@end

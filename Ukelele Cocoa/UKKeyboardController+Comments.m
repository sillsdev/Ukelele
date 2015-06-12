//
//  UKKeyboardController+Comments.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 12/06/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import "UKKeyboardController+Comments.h"
#import "XMLCocoaUtilities.h"

@implementation UKKeyboardController (Comments)

#pragma mark === Comments tab ===

- (void)addCreationComment {
	[self.keyboardLayout addCreationComment];
}

- (IBAction)addComment:(id)sender
{
#pragma unused(sender)
   if (commentChanged) {
		[self saveUnsavedComment];
	}
    XMLCommentHolderObject *commentHolder = [self.keyboardLayout currentCommentHolder];
	if (!commentHolder) {
		commentHolder = [self.keyboardLayout documentCommentHolder];
	}
	NSAssert(commentHolder, @"Must have a comment holder");
	[self addComment:@"" toHolder:commentHolder];
	[self updateCommentFields];
}

- (IBAction)removeComment:(id)sender
{
#pragma unused(sender)
    XMLCommentHolderObject *commentHolder = [self.keyboardLayout currentCommentHolder];
	NSAssert(commentHolder, @"Must have a comment holder");
	NSString *commentText = [self.keyboardLayout currentComment];
	NSAssert(commentText, @"Must have comment text");
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
#pragma unused(sender)
   if (commentChanged) {
		[self saveUnsavedComment];
	}
	NSString *commentText = [self.keyboardLayout firstComment];
	NSAssert(commentText, @"Must have comment text");
	[self.commentPane setString:[XMLCocoaUtilities convertEncodedString:commentText]];
	[self updateCommentFields];
}

- (IBAction)previousComment:(id)sender
{
#pragma unused(sender)
    if (commentChanged) {
		[self saveUnsavedComment];
	}
	NSString *commentText = [self.keyboardLayout previousComment];
	NSAssert(commentText, @"Must have comment text");
	[self.commentPane setString:[XMLCocoaUtilities convertEncodedString:commentText]];
	[self updateCommentFields];
}

- (IBAction)nextComment:(id)sender
{
#pragma unused(sender)
    if (commentChanged) {
		[self saveUnsavedComment];
	}
	NSString *commentText = [self.keyboardLayout nextComment];
	NSAssert(commentText, @"Must have comment text");
	[self.commentPane setString:[XMLCocoaUtilities convertEncodedString:commentText]];
	[self updateCommentFields];
}

- (IBAction)lastComment:(id)sender
{
#pragma unused(sender)
    if (commentChanged) {
		[self saveUnsavedComment];
	}
	NSString *commentText = [self.keyboardLayout lastComment];
	NSAssert(commentText, @"Must have comment text");
	[self.commentPane setString:[XMLCocoaUtilities convertEncodedString:commentText]];
	[self updateCommentFields];
}

- (void)updateCommentFields {
	if (commentChanged) {
			// Save the changed comment
		[self saveUnsavedComment];
	}
	NSAssert(commentChanged == NO, @"Comment still changed after saving");
		// Set the comment text pane
	NSString *commentText = [self.keyboardLayout currentComment];
	if (commentText) {
		[self.commentPane setString:[XMLCocoaUtilities convertEncodedString:commentText]];
	}
		// Set the XML statement pane
	NSString *holderText = [self.keyboardLayout currentHolderText];
	if (holderText) {
		[self.commentBindingPane setStringValue:holderText];
	}
		// Set the button states
	if ([self.keyboardLayout isFirstComment]) {
		[self.firstCommentButton setEnabled:NO];
		[self.previousCommentButton setEnabled:NO];
	}
	else {
		[self.firstCommentButton setEnabled:YES];
		[self.previousCommentButton setEnabled:YES];
	}
	if ([self.keyboardLayout isLastComment]) {
		[self.lastCommentButton setEnabled:NO];
		[self.nextCommentButton setEnabled:NO];
	}
	else {
		[self.lastCommentButton setEnabled:YES];
		[self.nextCommentButton setEnabled:YES];
	}
	if ([self.keyboardLayout isEditableComment]) {
		[self.removeCommentButton setEnabled:YES];
		[self.commentPane setEditable:YES];
	}
	else {
		[self.removeCommentButton setEnabled:NO];
		[self.commentPane setEditable:NO];
	}
}

- (void)clearCommentFields {
	[self.commentPane setString:@""];
	[self.commentBindingPane setStringValue:@""];
	[self.firstCommentButton setEnabled:NO];
	[self.previousCommentButton setEnabled:NO];
	[self.nextCommentButton setEnabled:NO];
	[self.lastCommentButton setEnabled:NO];
	[self.removeCommentButton setEnabled:NO];
}

- (void)saveUnsavedComment {
	NSString *existingComment = [self.keyboardLayout currentComment];
	NSAssert(existingComment, @"Must have an existing comment");
	NSString *commentPaneContents = [XMLCocoaUtilities makeXMLString:[self.commentPane string] codingNonAscii:NO];
	XMLCommentHolderObject *currentHolder = [self.keyboardLayout currentCommentHolder];
	NSAssert(currentHolder, @"Must have a current comment holder");
	if (![commentPaneContents isEqualToString:existingComment]) {
		[self changeCommentTextFrom:existingComment to:commentPaneContents forHolder:currentHolder];
	}
	commentChanged = NO;
}

#pragma mark Undo routines

- (void)changeCommentTextFrom:(NSString *)oldText
						   to:(NSString *)newText
					forHolder:(XMLCommentHolderObject *)commentHolder {
	NSAssert(commentHolder, @"Comment holder must not be nil");
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] changeCommentTextFrom:newText to:oldText forHolder:commentHolder];
	[undoManager setActionName:@"Change comment"];
	[self.keyboardLayout changeCommentText:oldText to:newText forHolder:commentHolder];
	[self updateCommentFields];
}

- (void)addComment:(NSString *)commentText toHolder:(XMLCommentHolderObject *)commentHolder {
	NSAssert(commentHolder, @"Comment holder must not be nil");
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeComment:commentText fromHolder:commentHolder];
	[undoManager setActionName:[undoManager isUndoing] ? @"Remove comment" : @"Add comment"];
	[self.keyboardLayout addComment:commentText toHolder:commentHolder];
	[self updateCommentFields];
}

- (void)removeComment:(NSString *)commentText fromHolder:(XMLCommentHolderObject *)commentHolder {
	NSAssert(commentHolder, @"Comment holder must not be nil");
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] addComment:commentText toHolder:commentHolder];
	[undoManager setActionName:[undoManager isUndoing] ? @"Add comment" : @"Remove comment"];
	[self.keyboardLayout removeComment:commentText fromHolder:commentHolder];
	[self updateCommentFields];
}

#pragma mark Delegate methods

- (void)textDidChange:(NSNotification *)notification {
#pragma unused(notification)
	commentChanged = YES;
}

@end

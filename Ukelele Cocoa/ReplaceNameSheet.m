//
//  ReplaceNameSheet.m
//  Ukelele 3
//
//  Created by John Brownie on 15/06/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "ReplaceNameSheet.h"

@implementation ReplaceNameSheet

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"ReplaceNameSheet" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
		verifyCallBack = nil;
		acceptCallBack = nil;
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

+ (ReplaceNameSheet *)createReplaceNameSheet
{
	return [[ReplaceNameSheet alloc] initWithWindowNibName:@"ReplaceNameSheet"];
}

- (void)beginReplaceNameSheetWithText:(NSString *)infoText
							forWindow:(NSWindow *)parentWindow
							withNames:(NSArray *)nameList
					   verifyCallBack:(BOOL (^)(NSString *))theVerifyCallBack
					   acceptCallBack:(void (^)(NSString *, NSString *))theAcceptCallBack
{
	[chooseField setStringValue:infoText];
	[nameButton removeAllItems];
	[nameButton addItemsWithTitles:nameList];
	[replacementNameField setStringValue:@""];
	verifyCallBack = theVerifyCallBack;
	acceptCallBack = theAcceptCallBack;
	[errorField setHidden:YES];
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)acceptChoice:(id)sender
{
#pragma unused(sender)
	if (!verifyCallBack([replacementNameField stringValue])) {
			// Doesn't work!
		[errorField setHidden:NO];
		return;
	}
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	acceptCallBack([[nameButton selectedItem] title], [replacementNameField stringValue]);
}

- (IBAction)cancelChoice:(id)sender
{
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	acceptCallBack(nil, nil);
}

@end

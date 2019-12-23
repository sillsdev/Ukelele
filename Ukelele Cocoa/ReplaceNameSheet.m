//
//  ReplaceNameSheet.m
//  Ukelele 3
//
//  Created by John Brownie on 15/06/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "ReplaceNameSheet.h"
#import "XMLCocoaUtilities.h"

@implementation ReplaceNameSheet

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
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
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (IBAction)acceptChoice:(id)sender
{
#pragma unused(sender)
	NSString *replacementString = [XMLCocoaUtilities convertToXMLString:[replacementNameField stringValue] codingNonAscii:NO];
	if (!verifyCallBack(replacementString)) {
			// Doesn't work!
		[errorField setHidden:NO];
		return;
	}
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	acceptCallBack([[nameButton selectedItem] title], replacementString);
}

- (IBAction)cancelChoice:(id)sender
{
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	acceptCallBack(nil, nil);
}

@end

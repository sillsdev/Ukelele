//
//  AskReplaceDeadKeySheet.m
//  Ukelele 3
//
//  Created by John Brownie on 16/11/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import "AskReplaceDeadKeySheet.h"

NSString *kAskReplaceDeadKeyAccept = @"Accept";
NSString *kAskReplaceDeadKeyReject = @"Reject";

static NSString *nibFileName = @"AskReplaceDeadKeySheet";
static NSString *windowName = @"AskReplace";

@implementation AskReplaceDeadKeySheet

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:nibFileName owner:self topLevelObjects:nil];
	if (self = [super initWithWindowNibName:windowNibName]) {
		callBack = nil;
	}
	return self;
}

+ (AskReplaceDeadKeySheet *)askReplaceDeadKeySheet
{
	return [[AskReplaceDeadKeySheet alloc] initWithWindowNibName:windowName];
}

- (void)setMessage:(NSString *)messageText
{
	[messageField setStringValue:messageText];
}

- (void)beginSheetWithCallBack:(void (^)(NSString *))theCallBack
					 forWindow:(NSWindow *)parentWindow
{
	callBack = theCallBack;
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (IBAction)acceptChange:(id)sender
{
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(kAskReplaceDeadKeyAccept);
}

- (IBAction)rejectChange:(id)sender
{
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(kAskReplaceDeadKeyReject);
}

- (IBAction)cancelChange:(id)sender
{
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(nil);
}

@end

//
//  AskKeyCode.m
//  Ukelele 3
//
//  Created by John Brownie on 7/12/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import "AskKeyCode.h"

static NSString *nibFileName = @"AskKeyCode";
static NSString *nibWindowName = @"AskKeyCode";

@implementation AskKeyCode

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:nibFileName owner:self topLevelObjects:nil];
	if (self = [super initWithWindowNibName:windowNibName]) {
		parentWindow = nil;
		callBack = nil;
	}
	return self;
}

+ (AskKeyCode *)askKeyCode
{
	return [[AskKeyCode alloc] initWithWindowNibName:nibWindowName];
}

- (void)beginDialogForWindow:(NSWindow *)theWindow
					callBack:(void (^)(NSNumber *))theCallBack
{
	parentWindow = theWindow;
	callBack = theCallBack;
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (void)setMajorText:(NSString *)majorText
{
	[majorTextField setStringValue:majorText];
}

- (void)setMinorText:(NSString *)minorText
{
	[minorTextField setStringValue:minorText];
}

- (IBAction)acceptKeyCode:(id)sender
{
#pragma unused(sender)
	if ([[self window] firstResponder] == keyCodeField) {
		[[self window] endEditingFor:keyCodeField];
	}
	[[self window] orderOut:self];
	NSNumber *keyCode = [keyCodeField objectValue];
	[NSApp endSheet:[self window]];
	callBack(keyCode);
}

- (IBAction)cancelKeyCode:(id)sender
{
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(nil);
}

- (BOOL)control:(NSControl *)control didFailToFormatString:(NSString *)string errorDescription:(NSString *)error
{
#pragma unused(control)
#pragma unused(string)
	[errorField setStringValue:error];
	NSBeep();
	return NO;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
#pragma unused(control)
#pragma unused(fieldEditor)
	[errorField setStringValue:@""];
	return YES;
}

@end

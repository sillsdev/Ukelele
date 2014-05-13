//
//  ConfirmStateNameSheet.m
//  Ukelele 3
//
//  Created by John Brownie on 28/11/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import "ConfirmStateNameSheet.h"

static NSString *nibFileName = @"ConfirmStateName";
static NSString *nibWindowName = @"ConfirmStateName";

NSString *kConfirmStateType = @"Type";
NSString *kConfirmStateNew = @"New";
NSString *kConfirmStateExisting = @"Existing";
NSString *kConfirmStateName = @"Name";

@implementation ConfirmStateNameSheet

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:nibFileName owner:self topLevelObjects:nil];
	if ([super initWithWindowNibName:windowNibName]) {
		callBack = nil;
		parentWindow = nil;
	}
	return self;
}

+ (ConfirmStateNameSheet *)confirmStateNameSheet
{
	return [[ConfirmStateNameSheet alloc] initWithWindowNibName:nibWindowName];
}

- (IBAction)useExistingState:(id)sender
{
	[[self window] orderOut:self];
	NSDictionary *dataDictionary = @{kConfirmStateType: kConfirmStateExisting};
	[NSApp endSheet:[self window]];
	callBack(dataDictionary);
}

- (IBAction)useNewState:(id)sender
{
	[[self window] orderOut:self];
	NSDictionary *dataDictionary = @{kConfirmStateType: kConfirmStateNew,
									kConfirmStateName: [newStateField stringValue]};
	[NSApp endSheet:[self window]];
	callBack(dataDictionary);
}

- (IBAction)cancelDialog:(id)sender
{
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(nil);
}

- (void)setMessage:(NSString *)messageText
{
	[messageField setStringValue:messageText];
}

- (void)setMinorText:(NSString *)messageText
{
	[minorTextField setStringValue:messageText];
}

- (void)startInteractionWithWindow:(NSWindow *)theWindow callBack:(void (^)(NSDictionary *))theCallBack
{
	callBack = theCallBack;
	parentWindow = theWindow;
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

@end

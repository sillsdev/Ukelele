//
//  AskTextSheet.m
//  Ukelele 3
//
//  Created by John Brownie on 30/04/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "AskTextSheet.h"

@implementation AskTextSheet {
	NSSet *unacceptableStrings;
}

static NSString *nibFileName = @"AskText";
static NSString *windowName = @"AskTextSheet";

- (instancetype)initWithWindowNibName:(NSString *)nibName
{
		//	[NSBundle loadNibNamed:nibFileName owner:self];
	[[NSBundle mainBundle] loadNibNamed:nibFileName owner:self topLevelObjects:nil];
	self = [super initWithWindowNibName:nibName];
	if (self) {
		askTextCallBack = nil;
	}
	return self;
}

+ (AskTextSheet *)askTextSheet
{
	AskTextSheet *theSheet = [[AskTextSheet alloc] initWithWindowNibName:windowName];
	return theSheet;
}

- (void)beginAskText:(NSString *)theMajorText
		   minorText:(NSString *)theMinorText
		 initialText:(NSString *)theInitialText
		   forWindow:(NSWindow *)parentWindow
			callBack:(UKSheetCompletionBlock)theCallBack
{
	[askTextMajorText setStringValue:theMajorText];
	[askTextMinorText setStringValue:theMinorText];
	[askTextField setStringValue:theInitialText];
	unacceptableStrings = [NSSet set];
	askTextCallBack = theCallBack;
	[parentWindow beginSheet:askTextSheet completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (void)beginAskValidatedText:(NSString *)theMajorText
				   notFromSet:(NSSet *)stopList
					errorText:(NSString *)errorText
				  initialText:(NSString *)theInitialText
					forWindow:(NSWindow *)parentWindow
					 callBack:(UKSheetCompletionBlock)theCallBack {
	[askTextMajorText setStringValue:theMajorText];
	[askTextMinorText setStringValue:errorText];
	[askTextMinorText setHidden:YES];
	unacceptableStrings = stopList;
	askTextCallBack = theCallBack;
	[askTextField setStringValue:theInitialText];
	[parentWindow beginSheet:askTextSheet completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (IBAction)acceptAskText:(id)sender
{
#pragma unused(sender)
	NSString *theText = [askTextField stringValue];
	if ([unacceptableStrings containsObject:theText]) {
			// Unacceptable string
		[askTextMinorText setHidden:NO];
		return;
	}
	[askTextSheet orderOut:self];
	[NSApp endSheet:askTextSheet];
	askTextCallBack(theText);
}

- (IBAction)cancelAskText:(id)sender
{
#pragma unused(sender)
	[askTextSheet orderOut:self];
	[NSApp endSheet:askTextSheet];
	askTextCallBack(nil);
}

@end

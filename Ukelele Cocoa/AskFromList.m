//
//  AskFromList.m
//  Ukelele 3
//
//  Created by John Brownie on 29/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "AskFromList.h"


@implementation AskFromList

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"AskFromList" owner:self topLevelObjects:nil];
	self = [super initWithWindowNibName:windowNibName];
	if (self) {
		callBack = nil;
	}
	return self;
}

+ (AskFromList *)askFromList
{
	return [[AskFromList alloc] initWithWindowNibName:@"AskFromList"];
}

- (void)beginAskFromListWithText:(NSString *)infoText
						withMenu:(NSArray *)menuItems
					   forWindow:(NSWindow *)parentWindow
						callBack:(void (^)(NSString *))theCallBack
{
	callBack = theCallBack;
	[listButton removeAllItems];
	[listButton addItemsWithTitles:menuItems];
	[informationText setStringValue:infoText];
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (IBAction)acceptChoice:(id)sender
{
#pragma unused(sender)
	[[self window] orderOut:self];
	NSString *chosenItem = [listButton titleOfSelectedItem];
	[NSApp endSheet:[self window]];
	callBack(chosenItem);
}

- (IBAction)cancelChoice:(id)sender
{
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(nil);
}

@end

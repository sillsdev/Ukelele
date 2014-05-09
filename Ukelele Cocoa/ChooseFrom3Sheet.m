//
//  ChooseFrom3Sheet.m
//  Ukelele 3
//
//  Created by John Brownie on 1/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "ChooseFrom3Sheet.h"


@implementation ChooseFrom3Sheet

static NSString *nibName = @"ChooseFrom3Sheet";
static NSString *windowName = @"ChooseFrom3Sheet";

- (id)init
{
	[NSBundle loadNibNamed:nibName owner:self];
	self = [super initWithWindowNibName:windowName];
	return self;
}

+ (ChooseFrom3Sheet *)chooseFrom3Sheet
{
	return [[ChooseFrom3Sheet alloc] init];
}

- (void)beginChooseOption1:(NSString *)option1
				   option2:(NSString *)option2
				   option3:(NSString *)option3
				   message:(NSString *)messageText
					window:(NSWindow *)parentWindow
				  callBack:(void (^)(int))theCallBack
{
	[infoText setStringValue:messageText];
	NSArray *cellArray = [radioButtons cells];
	[cellArray[0] setTitle:option1];
	[cellArray[1] setTitle:option2];
	if (option3 == nil) {
		[radioButtons removeRow:2];
	}
	else {
		[cellArray[2] setTitle:option3];
	}
	callBack = theCallBack;
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (void)acceptChoice:(id)sender
{
	[chooseSheet orderOut:self];
	NSInteger chosenRow = [radioButtons selectedRow];
	[NSApp endSheet:chooseSheet];
	callBack(chosenRow);
}

- (void)cancelChoice:(id)sender
{
	[chooseSheet orderOut:self];
	[NSApp endSheet:chooseSheet];
	callBack(-1);
}

@end

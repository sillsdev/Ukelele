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

- (instancetype)init
{
	[[NSBundle mainBundle] loadNibNamed:nibName owner:self topLevelObjects:nil];
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
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (void)acceptChoice:(id)sender
{
#pragma unused(sender)
	[chooseSheet orderOut:self];
	NSInteger chosenRow = [radioButtons selectedRow];
	[NSApp endSheet:chooseSheet];
	callBack((int)chosenRow);
}

- (void)cancelChoice:(id)sender
{
#pragma unused(sender)
	[chooseSheet orderOut:self];
	[NSApp endSheet:chooseSheet];
	callBack(-1);
}

@end

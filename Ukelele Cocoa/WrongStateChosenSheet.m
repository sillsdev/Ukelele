//
//  WrongStateChosenSheet.m
//  Ukelele 3
//
//  Created by John Brownie on 17/11/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import "WrongStateChosenSheet.h"
#import "DeadKeyConstants.h"

NSString *nibFileName = @"WrongStateChosenSheet";
NSString *nibWindowName = @"WrongState";

	// Data dictionary keys
NSString *kWrongStateType = @"WrongStateType";
NSString *kWrongStateName = @"WrongStateName";

@implementation WrongStateChosenSheet

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[NSBundle loadNibNamed:nibFileName owner:self];
    if ([super initWithWindowNibName:windowNibName]) {
		callBack = nil;
    }
    return self;
}

+ (WrongStateChosenSheet *)wrongStateChosenSheet
{
	return [[WrongStateChosenSheet alloc] initWithWindowNibName:nibWindowName];
}

- (void)beginInteractionForWindow:(NSWindow *)theWindow
					   withStates:(NSArray *)stateNames
						 callBack:(void (^)(NSDictionary *))theCallBack
{
	[existingStateButton removeAllItems];
	[existingStateButton addItemsWithTitles:stateNames];
	if ([stateNames count] == 0) {
		NSCell *theCell = [stateChoice cellAtRow:0 column:0];
		[theCell setEnabled:NO];
	}
	callBack = theCallBack;
	parentWindow = theWindow;
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (void)setMessage:(NSString *)messageText
{
	[messageField setStringValue:messageText];
}

- (IBAction)acceptNewState:(id)sender
{
	[[self window] orderOut:self];
	NSInteger stateType = [stateChoice selectedRow] == 0 ? kDeadKeyTypeExisting : kDeadKeyTypeNew;
	NSString *stateName = nil;
	if (stateType == kDeadKeyTypeExisting) {
		stateName = [existingStateButton stringValue];
	}
	else {
		stateName = [newStateField stringValue];
	}
	NSDictionary *resultData = @{kWrongStateType: @(stateType),
								kWrongStateName: stateName};
	[NSApp endSheet:[self window]];
	callBack(resultData);
}

- (IBAction)cancelNewState:(id)sender
{
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(nil);
}

- (IBAction)chooseStateType:(id)sender
{
	switch ([stateChoice selectedRow]) {
		case 0:
				// Existing state
			[existingStateButton setEnabled:YES];
			[newStateField setEnabled:NO];
			break;
			
		case 1:
				// New state
			[existingStateButton setEnabled:NO];
			[newStateField setEnabled:YES];
			break;
	}
}

@end

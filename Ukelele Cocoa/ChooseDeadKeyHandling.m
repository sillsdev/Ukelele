//
//  ChooseDeadKeyHandling.m
//  Ukelele 3
//
//  Created by John Brownie on 7/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "ChooseDeadKeyHandling.h"

@implementation ChooseDeadKeyHandling

- (instancetype)init
{
	self = [super init];
	if (self) {
		parentWindow = nil;
		callBack = nil;
        completionTarget = nil;
        chooseSheet = nil;
	}
	return self;
}


- (void)setCompletionTarget:(id<UKInteractionCompletion>)target
{
    completionTarget = target;
}

- (void)startWithWindow:(NSWindow *)theWindow
			   callBack:(void (^)(NSInteger))theCallBack
				choices:(int)choices
{
	parentWindow = theWindow;
	callBack = theCallBack;
    if (!chooseSheet) {
        chooseSheet = [ChooseFrom3Sheet chooseFrom3Sheet];
    }
	NSString *option1String = NSLocalizedStringFromTable(@"Change terminator",
														 @"dialogs", @"Change terminator of dead key state");
	NSString *option2String = NSLocalizedStringFromTable(@"Change to ouptut",
														 @"dialogs", @"Change the dead key to output");
	NSString *option3String = choices == 3 ?
	NSLocalizedStringFromTable(@"Enter dead key state", @"dialogs", @"Enter the dead key state") : nil;
	NSString *messageText = NSLocalizedStringFromTable(@"This is a dead key. What do you want to do?",
													   @"dialogs", @"Main text for asking what to do with a dead key");
	[chooseSheet beginChooseOption1:option1String
							option2:option2String
							option3:option3String
							message:messageText
							 window:parentWindow
						   callBack:^(int choice) {
							   [self interactionCompleted];
							   self->callBack(choice);
						   }];
}

- (void)interactionCompleted
{
    [completionTarget interactionDidComplete:self];
}

- (void)handleMessage:(NSDictionary *)messageData
{
#pragma unused(messageData)
		// We don't handle any messages at this point
}

- (void)cancelInteraction {
	[self interactionCompleted];
}

@end

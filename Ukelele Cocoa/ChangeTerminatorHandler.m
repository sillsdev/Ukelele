//
//  ChangeTerminatorHandler.m
//  Ukelele 3
//
//  Created by John Brownie on 1/01/13.
//  Copyright (c) 2013 SIL. All rights reserved.
//

#import "ChangeTerminatorHandler.h"

@implementation ChangeTerminatorHandler

- (id)initWithData:(NSDictionary *)dataDictionary keyboardLayout:(UkeleleKeyboardObject *)keyboardLayout window:(NSWindow *)window {
	self = [super init];
	if (self) {
		stateDictionary = dataDictionary;
		keyboardObject = keyboardLayout;
		parentWindow = window;
	}
	return self;
}

- (void)setCompletionTarget:(id<UKInteractionCompletion>)target {
	completionTarget = target;
}

- (void)beginChangeTerminator {
	askTextSheet = [AskTextSheet askTextSheet];
}

- (void)interactionCompleted {
	
}

- (void)handleMessage:(NSDictionary *)messageData {
	
}

@end

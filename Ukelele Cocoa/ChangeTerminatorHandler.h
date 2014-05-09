//
//  ChangeTerminatorHandler.h
//  Ukelele 3
//
//  Created by John Brownie on 1/01/13.
//  Copyright (c) 2013 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UkeleleKeyboardObject.h"
#import "UKInteractionHandler.h"
#import "UKInteractionCompletion.h"
#import "AskTextSheet.h"

@interface ChangeTerminatorHandler : NSObject<NSTextFieldDelegate, UKInteractionHandler> {
	NSDictionary *stateDictionary;
	UkeleleKeyboardObject *keyboardObject;
	NSWindow *parentWindow;
    id<UKInteractionCompletion> completionTarget;
    AskTextSheet *askTextSheet;
}

- (id)initWithData:(NSDictionary *)dataDictionary
	keyboardLayout:(UkeleleKeyboardObject *)keyboardLayout
			window:(NSWindow *)window;
- (void)setCompletionTarget:(id<UKInteractionCompletion>)target;
- (void)beginChangeTerminator;

@end

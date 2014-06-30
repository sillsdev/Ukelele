//
//  CreateDeadKeyHandler.h
//  Ukelele 3
//
//  Created by John Brownie on 14/11/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKInteractionHandler.h"
#import "UKInteractionCompletion.h"

@class UKKeyboardController;

#define kCreateDeadKeySelectedKeyCode	@"CreateDeadKeySelectedKeyCode"

typedef enum CreateDeadKeyHandlerType : NSInteger {
	kCreateDeadKeyHandlerNoParams = 0,
	kCreateDeadKeyHandlerKeyCode = 1,
	kCreateDeadKeyHandlerKeyCodeState = 2
} CreateDeadKeyHandlerType;

@interface CreateDeadKeyHandler : NSObject<UKInteractionHandler>

- (id)initWithCurrentState:(NSString *)stateName
				 modifiers:(NSUInteger)theModifiers
				keyboardID:(NSInteger)keyboardID
			keyboardWindow:(UKKeyboardController *)theDocument
				   keyCode:(NSInteger)keyCode
				 nextState:(NSString *)nextStateName
				terminator:(NSString *)theTerminator;
- (void)startHandling;
- (void)setCompletionTarget:(id<UKInteractionCompletion>)theTarget;

@end

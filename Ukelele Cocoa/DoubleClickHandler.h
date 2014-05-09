//
//  DoubleClickHandler.h
//  Ukelele 3
//
//  Created by John Brownie on 30/04/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKInteractionHandler.h"
#import "UKInteractionCompletion.h"
#import "AskTextSheet.h"
#import "EditKeyPopoverController.h"

@class UkeleleKeyboardObject;

typedef enum DoubleClickDeadKeyType : NSInteger {
	kDoubleClickDeadKeyAsk,
	kDoubleClickDeadKeyChangeState,
	kDoubleClickDeadKeyChangeTerminator,
	kDoubleClickDeadKeyChangeToOutput
} DoubleClickDeadKeyType;

@interface DoubleClickHandler : NSObject<NSTextFieldDelegate, UKInteractionHandler, UKInteractionCompletion, NSPopoverDelegate>

- (id)initWithData:(NSMutableDictionary *)dataDict
	keyboardLayout:(UkeleleKeyboardObject *)keyboardLayout
			window:(NSWindow *)window;
- (void)setCompletionTarget:(id<UKInteractionCompletion>)target;
- (void)startDoubleClick;
- (void)setDeadKeyProcessingType:(DoubleClickDeadKeyType)theType;
- (void)askNewOutput;
- (void)askNewTerminator;
- (void)askNewState;

@end

//
//  UnlinkKeyHandler.h
//  Ukelele 3
//
//  Created by John Brownie on 8/12/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKInteractionHandler.h"
#import "UKInteractionCompletion.h"
#import "AskKeyCode.h"

@class UKKeyboardController;

typedef enum UnlinkKeyType : NSInteger {
	kUnlinkKeyTypeAskCode,
	kUnlinkKeyTypeAskKey,
	kUnlinkKeyTypeSelectedKey
} UnlinkKeyType;

@interface UnlinkKeyHandler : NSObject<UKInteractionHandler>

+ (UnlinkKeyHandler *)unlinkKeyHandler:(UKKeyboardController *)theDocumentWindow;
- (void)beginInteraction:(UnlinkKeyType)keyCodeType;
- (void)setCompletionTarget:(id<UKInteractionCompletion>)theTarget;
- (void)setSelectedKeyCode:(NSInteger)keyCode;

@end

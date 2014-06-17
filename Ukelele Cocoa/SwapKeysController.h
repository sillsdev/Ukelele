//
//  SwapKeysController.h
//  Ukelele 3
//
//  Created by John Brownie on 11/08/13.
//
//

#import <Foundation/Foundation.h>
#import "UKInteractionHandler.h"
#import "UKInteractionCompletion.h"

@class UKKeyboardWindow;

@interface SwapKeysController : NSObject<UKInteractionHandler>

+ (SwapKeysController *)swapKeysController:(UKKeyboardWindow *)theDocumentWindow;
- (void)beginInteraction:(BOOL)askingKeyCode;
- (void)setCompletionTarget:(id<UKInteractionCompletion>)theTarget;

@end

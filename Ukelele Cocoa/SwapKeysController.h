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

@class UkeleleDocument;

@interface SwapKeysController : NSObject<UKInteractionHandler>

+ (SwapKeysController *)swapKeysController:(UkeleleDocument *)theDocument window:(NSWindow *)theWindow;
- (void)beginInteraction:(BOOL)askingKeyCode;
- (void)setCompletionTarget:(id<UKInteractionCompletion>)theTarget;

@end

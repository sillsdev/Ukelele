//
//  UnlinkModifierSetHandler.h
//  Ukelele 3
//
//  Created by John Brownie on 10/05/13.
//
//

#import <Cocoa/Cocoa.h>
#import "UKInteractionHandler.h"
#import "UKInteractionCompletion.h"
#import "UnlinkModifiersController.h"

@class UKKeyboardController;

@interface UnlinkModifierSetHandler : NSObject<UKInteractionHandler>

+ (UnlinkModifierSetHandler *)unlinkModifierSetHandler:(UKKeyboardController *)theDocumentWindow;
- (void)beginInteractionWithCallback:(void (^)(NSInteger))theCallBack;
- (void)setCompletionTarget:(id<UKInteractionCompletion>)theTarget;

@end

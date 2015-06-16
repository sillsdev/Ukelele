//
//  UKKeyStrokeLookupInteractionHandler.h
//  Ukelele Cocoa
//
//  Created by John Brownie on 27/01/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKInteractionHandler.h"
#import "UKInteractionCompletion.h"

@class UKKeyboardController;

@interface UKKeyStrokeLookupInteractionHandler : NSObject<UKInteractionHandler>

@property (weak) id<UKInteractionCompletion> completionTarget;

- (void)beginInteractionWithKeyboard:(UKKeyboardController *)theKeyboard;

@end

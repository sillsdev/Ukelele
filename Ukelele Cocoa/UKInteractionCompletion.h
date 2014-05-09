//
//  UKInteractionCompletion.h
//  Ukelele 3
//
//  Created by John Brownie on 8/08/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UKInteractionHandler.h"

@protocol UKInteractionCompletion <NSObject>

- (void)interactionDidComplete:(id<UKInteractionHandler>)handler;

@end

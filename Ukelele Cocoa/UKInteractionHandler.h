//
//  UKInteractionHandler.h
//  Ukelele 3
//
//  Created by John Brownie on 8/08/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol UKInteractionHandler <NSObject>

- (void)interactionCompleted;
- (void)handleMessage:(NSDictionary *)messageData;
- (void)cancelInteraction;

@end

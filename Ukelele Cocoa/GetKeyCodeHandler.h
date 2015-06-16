//
//  GetKeyCodeHandler.h
//  Ukelele 3
//
//  Created by John Brownie on 28/09/13.
//
//

#import <Foundation/Foundation.h>
#import "UKInteractionHandler.h"
#import "UKInteractionCompletion.h"

@interface GetKeyCodeHandler : NSObject<UKInteractionHandler>

@property (weak, nonatomic) id<UKInteractionCompletion> completionTarget;

+ (GetKeyCodeHandler *)getKeyCodeHandler;

- (void)beginInteractionWithCompletion:(void (^)(NSInteger))completionBlock;

@end

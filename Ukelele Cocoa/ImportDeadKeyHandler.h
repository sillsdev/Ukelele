//
//  ImportDeadKeyHandler.h
//  Ukelele 3
//
//  Created by John Brownie on 4/10/13.
//
//

#import <Cocoa/Cocoa.h>
#import "UKInteractionHandler.h"
#import "UKInteractionCompletion.h"

@class UkeleleDocument;

@interface ImportDeadKeyHandler : NSObject<UKInteractionHandler>

@property (weak, nonatomic) id<UKInteractionCompletion> completionTarget;

+ (ImportDeadKeyHandler *)importDeadKeyHandler;

- (void)beginInteractionForWindow:(NSWindow *)theWindow
					 withDocument:(UkeleleDocument *)theDocument;

@end

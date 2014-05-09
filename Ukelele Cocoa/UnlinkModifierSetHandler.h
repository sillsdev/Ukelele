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

@class UkeleleDocument;

@interface UnlinkModifierSetHandler : NSObject<UKInteractionHandler> {
	UkeleleDocument *parentDocument;
	NSWindow *parentWindow;
	void (^callback)(NSInteger);
    id<UKInteractionCompletion> completionTarget;
	UnlinkModifiersController *unlinkModifiersController;
}

+ (UnlinkModifierSetHandler *)unlinkModifierSetHandler:(UkeleleDocument *)theDocument window:(NSWindow *)theWindow;
- (void)beginInteractionWithCallback:(void (^)(NSInteger))theCallBack;
- (void)setCompletionTarget:(id<UKInteractionCompletion>)theTarget;

@end

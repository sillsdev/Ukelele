//
//  ChooseDeadKeyHandling.h
//  Ukelele 3
//
//  Created by John Brownie on 7/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKInteractionHandler.h"
#import "UKInteractionCompletion.h"
#import "ChooseFrom3Sheet.h"

@interface ChooseDeadKeyHandling : NSObject<UKInteractionHandler> {
	NSWindow *parentWindow;
	void (^callBack)(NSInteger);
    ChooseFrom3Sheet *chooseSheet;
    id<UKInteractionCompletion> completionTarget;
}

- (void)startWithWindow:(NSWindow *)theWindow
			   callBack:(void (^)(NSInteger))theCallBack
				choices:(int)choices;
- (void)setCompletionTarget:(id<UKInteractionCompletion>)target;

@end

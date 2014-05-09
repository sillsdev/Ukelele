//
//  DragTextHandler.h
//  Ukelele 3
//
//  Created by John Brownie on 8/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKInteractionHandler.h"
#import "UKInteractionCompletion.h"

@interface DragTextHandler : NSObject<UKInteractionHandler, UKInteractionCompletion> {
	NSMutableDictionary *keyDataDict;
	NSString *dragText;
	NSString *currentOutput;
	NSString *nextState;
	NSWindow *parentWindow;
    id<UKInteractionCompletion> completionTarget;
    id<UKInteractionHandler> subsidiaryHandler;
}

- (id)initWithData:(NSMutableDictionary *)dataDict dragText:(NSString *)draggedText window:(NSWindow *)theWindow;
- (void)setCompletionTarget:(id<UKInteractionCompletion>)target;
- (void)startDrag;

@end

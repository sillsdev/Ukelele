//
//  DragTextHandler.m
//  Ukelele 3
//
//  Created by John Brownie on 8/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "DragTextHandler.h"
#import "UKKeyboardController.h"
#import "ChooseDeadKeyHandling.h"
#import "UkeleleConstantStrings.h"
#import "ToolboxData.h"

@implementation DragTextHandler

- (instancetype)initWithData:(NSMutableDictionary *)dataDict dragText:(NSString *)draggedText window:(NSWindow *)theWindow
{
	self = [super init];
	if (self) {
		keyDataDict = dataDict;
		dragText = draggedText;
		parentWindow = theWindow;
		currentOutput = nil;
		nextState = nil;
        completionTarget = nil;
        subsidiaryHandler = nil;
	}
	return self;
}

- (void)setCompletionTarget:(id<UKInteractionCompletion>)target
{
    completionTarget = target;
}


- (void)startDrag
{
	BOOL deadKey;
	NSString *nextDeadKeyState = nil;
    UKKeyboardController *theDocumentWindow = [keyDataDict valueForKey:kKeyDocument];
	currentOutput = [[theDocumentWindow keyboardLayout] getCharOutput:keyDataDict
                                                          isDead:&deadKey
                                                       nextState:&nextDeadKeyState];
	if (deadKey) {
		nextState = nextDeadKeyState;
		ChooseDeadKeyHandling *handler = [[ChooseDeadKeyHandling alloc] init];
        [handler setCompletionTarget:self];
		[handler startWithWindow:parentWindow callBack:^(NSInteger theChoice) {
			switch (theChoice) {
				case -1:	// User cancelled
					break;
					
				case 0:		// Change terminator
					[[keyDataDict valueForKey:kKeyDocument] changeTerminatorForState:nextState to:dragText];
					break;
					
				case 1:		// Convert to output
					[[keyDataDict valueForKey:kKeyDocument] makeDeadKeyOutput:keyDataDict output:dragText];
					break;
			}
			[self interactionCompleted];
		}
						 choices:2];
        subsidiaryHandler = handler;
	}
	else {
		[theDocumentWindow changeOutputForKey:keyDataDict to:dragText usingBaseMap:![[ToolboxData sharedToolboxData] JISOnly]];
		[self interactionCompleted];
	}
}

- (void)interactionCompleted
{
    // call the document's interactionDidComplete method
    [completionTarget interactionDidComplete:self];
}

- (void)interactionDidComplete:(id<UKInteractionHandler>)handler
{
    NSAssert(handler == subsidiaryHandler, @"Wrong handler");
    subsidiaryHandler = nil;
}

- (void)handleMessage:(NSDictionary *)messageData
{
#pragma unused(messageData)
		// We don't handle any messages at this point
}

- (void)cancelInteraction {
	[self interactionCompleted];
}

@end

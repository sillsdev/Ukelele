//
//  GetKeyCodeHandler.m
//  Ukelele 3
//
//  Created by John Brownie on 28/09/13.
//
//

#import "GetKeyCodeHandler.h"
#import "UkeleleConstantStrings.h"
#import "UkeleleConstants.h"

@implementation GetKeyCodeHandler {
    void (^callBack)(NSInteger);
}

- (instancetype)init {
	if (self = [super init]) {
		_completionTarget = nil;
		callBack = nil;
	}
	return self;
}

+ (GetKeyCodeHandler *)getKeyCodeHandler {
	return [[GetKeyCodeHandler alloc] init];
}

- (void)beginInteractionWithCompletion:(void (^)(NSInteger))completionBlock {
	callBack = completionBlock;
}

- (void)handleMessage:(NSDictionary *)messageData {
	NSString *messageName = messageData[kMessageNameKey];
	NSInteger keyCode = kNoKeyCode;
	if ([messageName isEqualToString:kMessageClick]) {
			// Handle a click
		keyCode = [messageData[kMessageArgumentKey] integerValue];
	}
	else if ([messageName isEqualToString:kMessageKeyDown]) {
			// Handle a key down
		keyCode = [messageData[kMessageArgumentKey] integerValue];
	}
	if (keyCode != kNoKeyCode) {
			// Have a valid key code
		callBack(keyCode);
		[self interactionCompleted];
	}
}

- (void)interactionCompleted {
	[self.completionTarget interactionDidComplete:self];
}

- (void)cancelInteraction {
		// User cancelled
	callBack(kNoKeyCode);
	[self interactionCompleted];
}

@end

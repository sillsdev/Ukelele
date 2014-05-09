//
//  KeyboardEnvironment.h
//  Ukelele 3
//
//  Created by John Brownie on 20/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface KeyboardEnvironment : NSObject

@property (nonatomic) NSInteger currentKeyboardID;
@property (nonatomic) BOOL stickyModifiersOn;
@property (nonatomic) NSUInteger currentModifiers;
@property (copy) NSString *currentState;

+ (KeyboardEnvironment *)instance;
+ (void)updateKeyboard:(NSInteger)keyboardID
	   stickyModifiers:(BOOL)stickyModifiers
			 modifiers:(NSUInteger)modifiers
				 state:(NSString *)state;

@end

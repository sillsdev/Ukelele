//
//  WrongStateChosenSheet.h
//  Ukelele 3
//
//  Created by John Brownie on 17/11/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

MY_EXTERN NSString *kWrongStateType;
MY_EXTERN NSString *kWrongStateName;

@interface WrongStateChosenSheet : NSWindowController {
	IBOutlet NSTextField *messageField;
	IBOutlet NSMatrix *stateChoice;
	IBOutlet NSPopUpButton *existingStateButton;
	IBOutlet NSTextField *newStateField;
	void (^callBack)(NSDictionary *);
	NSWindow *parentWindow;
}

- (IBAction)acceptNewState:(id)sender;
- (IBAction)cancelNewState:(id)sender;
- (IBAction)chooseStateType:(id)sender;

+ (WrongStateChosenSheet *)wrongStateChosenSheet;
- (void)beginInteractionForWindow:(NSWindow *)theWindow
					   withStates:(NSArray *)stateNames
						 callBack:(void (^)(NSDictionary *))theCallBack;
- (void)setMessage:(NSString *)messageText;

@end

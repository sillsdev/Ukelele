//
//  ConfirmStateNameSheet.h
//  Ukelele 3
//
//  Created by John Brownie on 28/11/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

MY_EXTERN NSString *kConfirmStateType;
MY_EXTERN NSString *kConfirmStateNew;
MY_EXTERN NSString *kConfirmStateExisting;
MY_EXTERN NSString *kConfirmStateName;

@interface ConfirmStateNameSheet : NSWindowController {
	IBOutlet NSTextField *messageField;
	IBOutlet NSTextField *minorTextField;
	IBOutlet NSTextField *newStateField;
	void (^callBack)(NSDictionary *);
	NSWindow *parentWindow;
}

- (IBAction)useExistingState:(id)sender;
- (IBAction)useNewState:(id)sender;
- (IBAction)cancelDialog:(id)sender;

+ (ConfirmStateNameSheet *)confirmStateNameSheet;
- (void)startInteractionWithWindow:(NSWindow *)theWindow callBack:(void (^)(NSDictionary *))theCallBack;
- (void)setMessage:(NSString *)messageText;
- (void)setMinorText:(NSString *)messageText;

@end

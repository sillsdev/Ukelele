//
//  AskReplaceDeadKeySheet.h
//  Ukelele 3
//
//  Created by John Brownie on 16/11/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

MY_EXTERN NSString *kAskReplaceDeadKeyAccept;
MY_EXTERN NSString *kAskReplaceDeadKeyReject;

@interface AskReplaceDeadKeySheet : NSWindowController {
	IBOutlet NSTextField *messageField;
	void (^callBack)(NSString *);
}

- (IBAction)acceptChange:(id)sender;
- (IBAction)rejectChange:(id)sender;
- (IBAction)cancelChange:(id)sender;

+ (AskReplaceDeadKeySheet *)askReplaceDeadKeySheet;
- (void)setMessage:(NSString *)messageText;

- (void)beginSheetWithCallBack:(void (^)(NSString *))theCallBack
					 forWindow:(NSWindow *)parentWindow;

@end

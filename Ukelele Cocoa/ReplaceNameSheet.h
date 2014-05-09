//
//  ReplaceNameSheet.h
//  Ukelele 3
//
//  Created by John Brownie on 15/06/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ReplaceNameSheet : NSWindowController {
	IBOutlet NSTextField *chooseField;
	IBOutlet NSPopUpButton *nameButton;
	IBOutlet NSTextField *replacementNamePrompt;
	IBOutlet NSTextField *replacementNameField;
	IBOutlet NSTextField *errorField;
	BOOL (^verifyCallBack)(NSString *);
	void (^acceptCallBack)(NSString *, NSString *);
}

+ (ReplaceNameSheet *)createReplaceNameSheet;

- (void)beginReplaceNameSheetWithText:(NSString *)infoText
							forWindow:(NSWindow *)parentWindow
							withNames:(NSArray *)nameList
					   verifyCallBack:(BOOL (^)(NSString *))theVerifyCallBack
					   acceptCallBack:(void (^)(NSString *, NSString *))theAcceptCallBack;

- (IBAction)acceptChoice:(id)sender;
- (IBAction)cancelChoice:(id)sender;

@end

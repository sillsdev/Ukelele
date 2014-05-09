//
//  AskKeyCode.h
//  Ukelele 3
//
//  Created by John Brownie on 7/12/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AskKeyCode : NSWindowController<NSControlTextEditingDelegate> {
	IBOutlet NSTextField *majorTextField;
	IBOutlet NSTextField *minorTextField;
	IBOutlet NSTextField *keyCodeField;
	IBOutlet NSTextField *errorField;
	NSWindow *parentWindow;
	void (^callBack)(NSNumber *);
}

- (IBAction)acceptKeyCode:(id)sender;
- (IBAction)cancelKeyCode:(id)sender;

+ (AskKeyCode *)askKeyCode;
- (void)beginDialogForWindow:(NSWindow *)theWindow callBack:(void (^)(NSNumber *))theCallBack;

- (void)setMajorText:(NSString *)majorText;
- (void)setMinorText:(NSString *)minorText;

@end

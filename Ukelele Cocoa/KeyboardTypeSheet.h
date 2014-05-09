//
//  KeyboardTypeSheet.h
//  Ukelele 3
//
//  Created by John Brownie on 5/03/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KeyboardResourceList.h"

@interface KeyboardTypeSheet : NSWindowController {
	IBOutlet NSTableView *keyboardTypeTable;
	IBOutlet NSPopUpButton *codingButton;
	void (^callBack)(NSNumber *);
}

@property (nonatomic, strong) KeyboardResourceList *keyboardResources;
@property (nonatomic, strong) IBOutlet NSArrayController *arrayController;

+ (KeyboardTypeSheet *)createKeyboardTypeSheet;

- (IBAction)acceptChoice:(id)sender;
- (IBAction)cancelChoice:(id)sender;

- (void)beginKeyboardTypeSheetForWindow:(NSWindow *)parentWindow
						   withKeyboard:(NSInteger)keyboardID
							   callBack:(void (^)(NSNumber *))theCallBack;

@end

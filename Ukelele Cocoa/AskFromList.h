//
//  AskFromList.h
//  Ukelele 3
//
//  Created by John Brownie on 29/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AskFromList : NSWindowController {
	IBOutlet NSTextField *informationText;
	IBOutlet NSPopUpButton *listButton;
	void (^callBack)(NSString *);
}

- (IBAction)acceptChoice:(id)sender;
- (IBAction)cancelChoice:(id)sender;

+ (AskFromList *)askFromList;
- (void)beginAskFromListWithText:(NSString *)infoText
						withMenu:(NSArray *)menuItems
					   forWindow:(NSWindow *)parentWindow
						callBack:(void (^)(NSString *))theCallBack;

@end

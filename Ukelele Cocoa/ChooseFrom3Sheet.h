//
//  ChooseFrom3Sheet.h
//  Ukelele 3
//
//  Created by John Brownie on 1/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ChooseFrom3Sheet : NSWindowController {
	IBOutlet NSTextField *infoText;
	IBOutlet NSMatrix *radioButtons;
	IBOutlet NSWindow *chooseSheet;
	void (^callBack)(int);
}

- (IBAction)acceptChoice:(id)sender;
- (IBAction)cancelChoice:(id)sender;

+ (ChooseFrom3Sheet *)chooseFrom3Sheet;

- (void)beginChooseOption1:(NSString *)option1
				   option2:(NSString *)option2
				   option3:(NSString *)option3
				   message:(NSString *)messageText
					window:(NSWindow *)parentWindow
				  callBack:(void (^)(int))theCallBack;	// theCallBack will be invoked with the chosen option or -1 for cancel

@end

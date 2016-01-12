//
//  ChooseKeyboardIDWindowController.h
//  Ukelele 3
//
//  Created by John Brownie on 31/07/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString *kKeyboardIDWindowName;
extern NSString *kKeyboardIDWindowScript;
extern NSString *kKeyboardIDWindowID;

@interface ChooseKeyboardNameWindowController : NSWindowController {
	IBOutlet NSTextField *nameField;
	IBOutlet NSPopUpButton *scriptButton;
	IBOutlet NSTextField *rangeField;
	NSArray *scriptList;
	void (^callBack)(NSDictionary *);
}

@property (nonatomic) NSInteger currentID;

- (IBAction)selectScript:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;

+ (ChooseKeyboardNameWindowController *)chooseKeyboardID;

- (void)startDialogWithInfo:(NSDictionary *)infoDictionary
				  forWindow:(NSWindow *)parentWindow
				   callBack:(void (^)(NSDictionary *))theCallBack;

@end

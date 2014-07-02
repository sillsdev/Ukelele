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
extern NSString *kKeyboardIDWindowBuildVersion;
extern NSString *kKeyboardIDWindowBundleVersion;
extern NSString *kKeyboardIDWindowSourceVersion;

@interface ChooseKeyboardIDWindowController : NSWindowController {
	IBOutlet NSTextField *nameField;
	IBOutlet NSPopUpButton *scriptButton;
	IBOutlet NSTextField *rangeField;
	IBOutlet NSTextField *idField;
	NSArray *scriptList;
	void (^callBack)(NSDictionary *);
}

- (IBAction)selectScript:(id)sender;
- (IBAction)generateID:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)cancel:(id)sender;

+ (ChooseKeyboardIDWindowController *)chooseKeyboardID;

- (void)startDialogWithInfo:(NSDictionary *)infoDictionary
				  forWindow:(NSWindow *)parentWindow
				   callBack:(void (^)(NSDictionary *))theCallBack;

@end

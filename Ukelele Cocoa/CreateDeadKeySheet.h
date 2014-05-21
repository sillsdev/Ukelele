//
//  CreateDeadKeySheet.h
//  Ukelele 3
//
//  Created by John Brownie on 11/11/11.
//  Copyright (c) 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UkeleleKeyboardObject.h"
#import "UkeleleDeadKeyConstants.h"

	// Dictionary keys
MY_EXTERN NSString *kDeadKeyDataKeyCode;
MY_EXTERN NSString *kDeadKeyDataModifiers;
MY_EXTERN NSString *kDeadKeyDataStateName;
MY_EXTERN NSString *kDeadKeyDataStateType;
MY_EXTERN NSString *kDeadKeyDataTerminator;
MY_EXTERN NSString *kDeadKeyDataTerminatorSpecified;

@interface CreateDeadKeySheet : NSWindowController<NSControlTextEditingDelegate> {
	void (^callBack)(NSDictionary *);
	UkeleleKeyboardObject *keyboardObject;
	NSUInteger modifierCombination;
	NSString *currentState;
}
@property (strong) IBOutlet NSMatrix *chooseDeadKey;
@property (strong) IBOutlet NSTextField *deadKeyCode;
@property (strong) IBOutlet NSTextField *badKeyCodeMessage;
@property (strong) IBOutlet NSTextField *terminatorString;
@property (strong) IBOutlet NSComboBox *deadKeyState;
@property (strong) IBOutlet NSTextField *missingStateMessage;

- (IBAction)acceptChoice:(id)sender;
- (IBAction)cancelChoice:(id)sender;
- (IBAction)pickDeadKey:(id)sender;

+ (CreateDeadKeySheet *)createDeadKeySheet;

- (void)beginCreateDeadKeySheet:(UkeleleKeyboardObject *)keyboardLayout
				  withModifiers:(NSUInteger)modifiers
					   forState:(NSString *)stateName
					  forWindow:(NSWindow *)parentWindow
					   callback:(void (^)(NSDictionary *))theCallback;

@end

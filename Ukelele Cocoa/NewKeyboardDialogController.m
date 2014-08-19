//
//  NewKeyboardDialogController.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 11/07/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import "NewKeyboardDialogController.h"
#import "ScriptInfo.h"

NSString *kNewKeyboardName = @"name";
NSString *kNewKeyboardScript = @"script";
NSString *kNewKeyboardType = @"type";
NSString *kNewKeyboardCommandLayout = @"commandLayout";

@implementation NewKeyboardDialogController {
	NSArray *scriptList;
	void (^callback)(NSDictionary *);
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"NewKeyboardDialog" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
        scriptList = [ScriptInfo standardScripts];
		[_keyboardScript removeAllItems];
		for (ScriptInfo *scriptInfo in scriptList) {
			NSString *scriptName = [scriptInfo scriptName];
			[_keyboardScript addItemWithTitle:scriptName];
		}
		callback = nil;
    }
    return self;
}

+ (NewKeyboardDialogController *)newKeyboardDialogController {
	return [[NewKeyboardDialogController alloc] initWithWindowNibName:@"NewKeyboardDialog"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end

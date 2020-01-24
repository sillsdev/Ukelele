//
//  ChooseKeyboardIDWindowController.mm
//  Ukelele 3
//
//  Created by John Brownie on 31/07/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "ChooseKeyboardNameWindowController.h"
#import "ScriptInfo.h"

NSString *kKeyboardIDWindowName = @"KeyboardName";
NSString *kKeyboardIDWindowScript = @"ScriptID";

@implementation ChooseKeyboardNameWindowController

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"ChooseKeyboardNameWindow" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        scriptList = [ScriptInfo standardScripts];
		[scriptButton removeAllItems];
		for (ScriptInfo *scriptInfo in scriptList) {
			NSString *scriptName = [scriptInfo scriptName];
			[scriptButton addItemWithTitle:scriptName];
		}
		callBack = nil;
    }
    
    return self;
}


+ (ChooseKeyboardNameWindowController *)chooseKeyboardID
{
	return [[ChooseKeyboardNameWindowController alloc] initWithWindowNibName:@"ChooseKeyboardNameWindow"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)startDialogWithInfo:(NSDictionary *)infoDictionary
				  forWindow:(NSWindow *)parentWindow
				   callBack:(void (^)(NSDictionary *))theCallBack
{
	[nameField setStringValue:infoDictionary[kKeyboardIDWindowName]];
	NSInteger scriptIndex = [infoDictionary[kKeyboardIDWindowScript] integerValue];
	[scriptButton selectItemAtIndex:scriptIndex];
	[self selectScript:self];
	callBack = theCallBack;
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (IBAction)selectScript:(id)sender
{
#pragma unused(sender)
	NSInteger selectedScript = [scriptButton indexOfSelectedItem];
	if (selectedScript == -1) {
			// No selection
		return;
	}
	ScriptInfo *scriptInfo = scriptList[selectedScript];
//	NSInteger minID = [scriptInfo minID];
//	NSInteger maxID = [scriptInfo maxID];
//	NSString *scriptExplanation = [NSString stringWithFormat:@"%@ keyboards should have an ID between %ld and %ld",
//								   [scriptInfo scriptName], minID, maxID];
//	[rangeField setStringValue:scriptExplanation];
	[rangeField setStringValue:[scriptInfo scriptDescription]];
}

- (IBAction)ok:(id)sender
{
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	NSMutableDictionary *infoDictionary = [NSMutableDictionary dictionary];
	infoDictionary[kKeyboardIDWindowName] = [nameField stringValue];
	infoDictionary[kKeyboardIDWindowScript] = @([scriptButton indexOfSelectedItem]);
	callBack(infoDictionary);
}

- (IBAction)cancel:(id)sender
{
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(nil);
}

@end

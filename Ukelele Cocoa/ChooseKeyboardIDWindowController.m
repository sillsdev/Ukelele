//
//  ChooseKeyboardIDWindowController.mm
//  Ukelele 3
//
//  Created by John Brownie on 31/07/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "ChooseKeyboardIDWindowController.h"
#import "ScriptInfo.h"

NSString *kKeyboardIDWindowName = @"KeyboardName";
NSString *kKeyboardIDWindowScript = @"ScriptID";
NSString *kKeyboardIDWindowID = @"KeyboardID";
NSString *kKeyboardIDWindowBuildVersion = @"BuildVersion";
NSString *kKeyboardIDWindowBundleVersion = @"BundleVersion";
NSString *kKeyboardIDWindowSourceVersion = @"SourceVersion";

@implementation ChooseKeyboardIDWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"ChooseKeyboardIDWindow" owner:self topLevelObjects:nil];
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


+ (ChooseKeyboardIDWindowController *)chooseKeyboardID
{
	return [[ChooseKeyboardIDWindowController alloc] initWithWindowNibName:@"ChooseKeyboardIDWindow"];
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
	NSInteger keyboardID = [infoDictionary[kKeyboardIDWindowID] intValue];
	[idField setIntegerValue:keyboardID];
	NSString *versionString = infoDictionary[kKeyboardIDWindowBuildVersion];
	if (versionString) {
		[buildVersion setStringValue:versionString];
	}	
	versionString = infoDictionary[kKeyboardIDWindowBundleVersion];
	if (versionString) {
		[bundleVersion setStringValue:versionString];
	}	
	versionString = infoDictionary[kKeyboardIDWindowSourceVersion];
	if (versionString) {
		[sourceVersion setStringValue:versionString];
	}	
	callBack = theCallBack;
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)selectScript:(id)sender
{
	NSInteger selectedScript = [scriptButton indexOfSelectedItem];
	if (selectedScript == -1) {
			// No selection
		return;
	}
	ScriptInfo *scriptInfo = scriptList[selectedScript];
	NSInteger minID = [scriptInfo minID];
	NSInteger maxID = [scriptInfo maxID];
	NSString *scriptExplanation = [NSString stringWithFormat:@"%@ keyboards should have an ID between %ld and %ld",
								   [scriptInfo scriptName], minID, maxID];
	[rangeField setStringValue:scriptExplanation];
	[self generateID:self];
}

- (IBAction)generateID:(id)sender
{
	NSInteger selectedScript = [scriptButton indexOfSelectedItem];
	ScriptInfo *scriptInfo = scriptList[selectedScript];
	NSInteger generatedID = [scriptInfo randomID];
	[idField setIntegerValue:generatedID];
}

- (IBAction)ok:(id)sender
{
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	NSMutableDictionary *infoDictionary = [NSMutableDictionary dictionary];
	infoDictionary[kKeyboardIDWindowName] = [nameField stringValue];
	infoDictionary[kKeyboardIDWindowScript] = @([scriptButton indexOfSelectedItem]);
	infoDictionary[kKeyboardIDWindowID] = @([idField intValue]);
	infoDictionary[kKeyboardIDWindowBuildVersion] = [buildVersion stringValue];
	infoDictionary[kKeyboardIDWindowBundleVersion] = [bundleVersion stringValue];
	infoDictionary[kKeyboardIDWindowSourceVersion] = [sourceVersion stringValue];
	callBack(infoDictionary);
}

- (IBAction)cancel:(id)sender
{
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(nil);
}

@end

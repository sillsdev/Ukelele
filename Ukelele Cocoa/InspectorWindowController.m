//
//  InspectorWindowController.m
//  Ukelele 3
//
//  Created by John Brownie on 10/02/13.
//
//

#import "InspectorWindowController.h"
#import "UkeleleConstantStrings.h"
#import "ScriptInfo.h"
#import "UkeleleDocument.h"
#import "UKKeyboardLayoutBundle.h"

@implementation InspectorWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
		_stateStack = @[kStateNameNone];
		[_outputField setStringValue:@""];
		[_keyCodeField setStringValue:@""];
		[_modifierMatchField setStringValue:@""];
		[_modifiersField setStringValue:@""];
		_scriptList = [ScriptInfo standardScripts];
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
	[_stateStackTable selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
}

+ (InspectorWindowController *)getInstance {
	static InspectorWindowController *theInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		theInstance = [[InspectorWindowController alloc] initWithWindowNibName:@"InspectorWindow"];
	});
	return theInstance;
}

- (IBAction)generateID:(id)sender {
		// Work out the script
	NSInteger selectedScript = [_keyboardScriptButton indexOfSelectedItem];
	ScriptInfo *scriptInfo = _scriptList[selectedScript];
		// Generate a random number in the appropriate range
	NSInteger newID = [scriptInfo randomID];
	[_currentKeyboard setKeyboardID:newID];
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
	return NO;
}

- (void)setStateStack:(NSArray *)stateStack {
	NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity:[stateStack count]];
	for (NSString *stateName in [stateStack reverseObjectEnumerator]) {
		[tempArray addObject:stateName];
	}
	_stateStack = tempArray;
	[_stateStackTable selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	NSDocumentController *sharedController = [NSDocumentController sharedDocumentController];
	NSDocument *currentDocument = [sharedController currentDocument];
		// Tell the document that we have selected the tab
	if ([currentDocument isKindOfClass:[UkeleleDocument class]]) {
			// It's a keyboard layout document
		if ([kTabIdentifierDocument isEqualToString:[tabViewItem identifier]]) {
				// Don't have bundle parameters for a non-bundled keyboard layout
			[self setBundleSectionEnabled:NO];
		}
		[(UkeleleDocument *)currentDocument inspectorDidActivateTab:[tabViewItem identifier]];
	}
	else if ([currentDocument isKindOfClass:[UKKeyboardLayoutBundle class]]) {
			// It's a keyboard layout bundle
		if ([kTabIdentifierDocument isEqualToString:[tabViewItem identifier]]) {
				// We have a bundle, so allow the editing of the bundle parameters
			[self setBundleSectionEnabled:YES];
		}
		[(UKKeyboardLayoutBundle *)currentDocument inspectorDidActivateTab:[tabViewItem identifier]];
	}
}

- (void)setScript:(NSInteger)scriptCode {
	for (NSInteger i = 0; i < [_scriptList count]; i++) {
		ScriptInfo *scriptInfo = _scriptList[i];
		NSInteger scriptID = [scriptInfo scriptID];
		if (scriptID == scriptCode) {
			[_keyboardScriptButton selectItemAtIndex:i];
			break;
		}
	}
}

- (IBAction)showWindow:(id)sender {
	[self tabView:_tabView didSelectTabViewItem:[_tabView selectedTabViewItem]];
	[super showWindow:sender];
}

- (void)setKeyboardSectionEnabled:(BOOL)enabled {
	[_keyboardIDField setEnabled:enabled];
	[_keyboardNameField setEnabled:enabled];
	[_keyboardScriptButton setEnabled:enabled];
	[_generateButton setEnabled:enabled];
}

- (void)setBundleSectionEnabled:(BOOL)enabled {
	[_bundleNameField setEnabled:enabled];
	[_bundleVersionField setEnabled:enabled];
	[_buildVersionField setEnabled:enabled];
	[_sourceVersionField setEnabled:enabled];
}

@end

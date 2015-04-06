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
#import "UKKeyboardDocument.h"
#import "UKKeyboardController.h"
#import "UKKeyboardController+Housekeeping.h"

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
		NSMutableArray *scriptRanges = [NSMutableArray arrayWithCapacity:[_scriptList count]];
		for (NSUInteger i = 0; i < [_scriptList count]; i++) {
			NSString *rangeString = [NSString stringWithFormat:@"Keyboard ID should be between %ld and %ld", [_scriptList[i] minID], [_scriptList[i] maxID]];
			scriptRanges[i] = rangeString;
		}
		_scriptRangeList = scriptRanges;
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
	[self.stateStackTable selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
	NSData *frameData =[theDefaults objectForKey:UKInspectorWindowLocation];
	if (frameData != nil) {
		NSRect newFrame = *(NSRect *)[frameData bytes];
		[self.window setFrame:newFrame display:NO];
	}
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
	NSInteger selectedScript = [self.keyboardScriptButton indexOfSelectedItem];
	ScriptInfo *scriptInfo = self.scriptList[selectedScript];
		// Generate a random number in the appropriate range
	NSInteger newID = [scriptInfo randomID];
	if (self.currentWindow == nil) {
			// We have a bundle window
		NSAssert(self.currentBundle, @"Must have a bundle");
		self.currentWindow = [self.currentBundle controllerForCurrentEntry];
	}
	[self.currentWindow setKeyboardID:newID];
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
	[self.stateStackTable selectRowIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	NSDocumentController *sharedController = [NSDocumentController sharedDocumentController];
	UKKeyboardDocument *theDocument = [sharedController currentDocument];
	if (self.currentWindow != nil) {
		theDocument = [self.currentWindow parentDocument];
	}
	else {
		[self setKeyboardSectionEnabled:NO];
	}
	[theDocument inspectorDidActivateTab:[tabViewItem identifier]]; // Moved because of dead store?
}

- (void)setScript:(NSInteger)scriptCode {
	for (NSInteger i = 0; i < [self.scriptList count]; i++) {
		ScriptInfo *scriptInfo = self.scriptList[i];
		NSInteger scriptID = [scriptInfo scriptID];
		if (scriptID == scriptCode) {
			[self.keyboardScriptButton selectItemAtIndex:i];
			break;
		}
	}
}

- (IBAction)showWindow:(id)sender {
	[self tabView:self.tabView didSelectTabViewItem:[self.tabView selectedTabViewItem]];
	[super showWindow:sender];
}

- (void)setKeyboardSectionEnabled:(BOOL)enabled {
	[self.keyboardIDField setEnabled:enabled];
	[self.keyboardNameField setEnabled:enabled];
	[self.keyboardScriptButton setEnabled:enabled];
	[self.generateButton setEnabled:enabled];
}

#pragma mark Delegate methods

- (void)windowDidMove:(NSNotification *)notification {
	NSRect newFrame = [self.window frame];
	NSData *frameData = [NSData dataWithBytes:&newFrame length:sizeof(NSRect)];
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
	[theDefaults setObject:frameData forKey:UKInspectorWindowLocation];
}

@end

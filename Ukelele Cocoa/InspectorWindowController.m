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

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
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
		NSMutableArray *scriptDescriptions = [NSMutableArray arrayWithCapacity:[_scriptList count]];
		for (NSUInteger i = 0; i < [_scriptList count]; i++) {
			scriptDescriptions[i] = [_scriptList[i] scriptDescription];
		}
		_scriptDescriptionList = scriptDescriptions;
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
	NSData *frameData = [theDefaults objectForKey:UKInspectorWindowLocation];
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

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row {
#pragma unused(tableView)
#pragma unused(row)
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

- (IBAction)selectScript:(id)sender {
#pragma unused(sender)
	
}

- (void)setKeyboardSectionEnabled:(BOOL)enabled {
	[self.keyboardIDField setEnabled:enabled];
	[self.keyboardNameField setEnabled:enabled];
	[self.keyboardScriptButton setEnabled:enabled];
}

#pragma mark Delegate methods

- (void)windowDidMove:(NSNotification *)notification {
#pragma unused(notification)
	NSRect newFrame = [self.window frame];
	NSData *frameData = [NSData dataWithBytes:&newFrame length:sizeof(NSRect)];
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
	[theDefaults setObject:frameData forKey:UKInspectorWindowLocation];
}

@end

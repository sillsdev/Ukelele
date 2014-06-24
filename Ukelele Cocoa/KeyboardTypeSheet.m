//
//  KeyboardTypeSheet.m
//  Ukelele 3
//
//  Created by John Brownie on 5/03/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "KeyboardTypeSheet.h"

static NSString *nibName = @"KeyboardTypeSheet";
static NSString *nibWindowName = @"Keyboard Type";

@interface KeyboardTypeSheet ()

@end

@implementation KeyboardTypeSheet

- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner
{
	[[NSBundle mainBundle] loadNibNamed:nibName owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName owner:self];
    if (self) {
        // Initialization code here.
		_keyboardResources = [KeyboardResourceList getInstance];
		[_arrayController setContent:[_keyboardResources keyboardTypeTable]];
		NSTableColumn *tableColumn = [keyboardTypeTable tableColumnWithIdentifier:@"KeyboardType"];
		[tableColumn bind:@"value" toObject:_arrayController withKeyPath:@"arrangedObjects.keyboardName" options:nil];
		callBack = nil;
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

+ (KeyboardTypeSheet *)createKeyboardTypeSheet
{
	return [[KeyboardTypeSheet alloc] initWithWindowNibName:nibWindowName owner:self];
}

- (IBAction)acceptChoice:(id)sender
{
	[[self window] orderOut:self];
	NSInteger keyboardID = [self.keyboardResources resourceForType:[keyboardTypeTable selectedRow] code:[codingButton indexOfSelectedItem]];
	[NSApp endSheet:[self window]];
	callBack(@(keyboardID));
}

- (IBAction)cancelChoice:(id)sender
{
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(nil);
}

- (void)beginKeyboardTypeSheetForWindow:(NSWindow *)parentWindow
						   withKeyboard:(NSInteger)keyboardID
							   callBack:(void (^)(NSNumber *))theCallBack
{
	callBack = theCallBack;
	NSDictionary *indexDictionary = [self.keyboardResources indicesForResourceID:keyboardID];
	[keyboardTypeTable selectRowIndexes:[NSIndexSet indexSetWithIndex:[indexDictionary[kKeyNameIndex] integerValue]]
				   byExtendingSelection:NO];
	[keyboardTypeTable scrollRowToVisible:[keyboardTypeTable selectedRow]];
	[codingButton selectItemAtIndex:[indexDictionary[kKeyCodingIndex] integerValue] - 1];
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

@end

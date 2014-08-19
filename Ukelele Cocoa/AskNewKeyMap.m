//
//  AskNewKeyMap.m
//  Ukelele 3
//
//  Created by John Brownie on 24/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "AskNewKeyMap.h"
#import "UkeleleConstants.h"

@implementation NewKeyMapInfo

@end

static NSString *nibFileName = @"AskNewKeyMap";
static NSString *nibWindowName = @"AskNewKeyMap";

@implementation AskNewKeyMap

@synthesize infoText;
@synthesize keyMapType;
@synthesize standardKeyMaps;
@synthesize makeCopyKeyMaps;

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:nibFileName owner:self topLevelObjects:nil];
	self = [super initWithWindowNibName:windowNibName];
	if (self) {
			// Set up the standard key maps popup
		[standardKeyMaps removeAllItems];
		[standardKeyMaps addItemsWithTitles:@[@"QWERTY lower case", @"QWERTY upper case",
											 @"Dvorak lower case", @"Dvorak upper case",
											 @"AZERTY lower case", @"AZERTY upper case",
											 @"QWERTZ lower case", @"QWERTZ upper case",
											 @"Colemak lower case", @"Colemak upper case"]];
	}
	return self;
}

+ (AskNewKeyMap *)askNewKeyMap
{
	return [[AskNewKeyMap alloc] initWithWindowNibName:nibWindowName];
}

- (void)beginNewKeyMapWithText:(NSString *)informationText
				   withKeyMaps:(NSArray *)keyMaps
					 forWindow:(NSWindow *)parentWindow
					  callBack:(void (^)(NewKeyMapInfo *))theCallBack
{
	[infoText setStringValue:informationText];
	[makeCopyKeyMaps removeAllItems];
	[makeCopyKeyMaps addItemsWithTitles:keyMaps];
	callBack = theCallBack;
    [standardKeyMaps setEnabled:NO];
    [makeCopyKeyMaps setEnabled:NO];
    [unlinkedCheckBox setEnabled:NO];
	[NSApp beginSheet:[self window]
	   modalForWindow:parentWindow
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}

- (IBAction)selectKeyMapType:(id)sender
{
	switch ([keyMapType selectedRow]) {
		case kNewKeyMapEmpty:
			[standardKeyMaps setEnabled:NO];
			[makeCopyKeyMaps setEnabled:NO];
			[unlinkedCheckBox setEnabled:NO];
			break;

		case kNewKeyMapStandard:
			[standardKeyMaps setEnabled:YES];
			[makeCopyKeyMaps setEnabled:NO];
			[unlinkedCheckBox setEnabled:NO];
			break;

		case kNewKeyMapCopy:
			[standardKeyMaps setEnabled:NO];
			[makeCopyKeyMaps setEnabled:YES];
			[unlinkedCheckBox setEnabled:YES];
			break;
	}
}

- (IBAction)acceptNewKeyMap:(id)sender
{
	NewKeyMapInfo *infoBlock = [[NewKeyMapInfo alloc] init];
	[infoBlock setKeyMapTypeSelection:[keyMapType selectedRow]];
	switch ([keyMapType selectedRow]) {
		case kNewKeyMapStandard:
			[infoBlock setStandardKeyMapSelection:[standardKeyMaps indexOfSelectedItem]];
			break;
			
		case kNewKeyMapCopy:
			[infoBlock setCopyKeyMapSelection:[[makeCopyKeyMaps titleOfSelectedItem] integerValue]];
			[infoBlock setIsUnlinked:[unlinkedCheckBox state] == NSOnState];
			break;
	}
	callBack(infoBlock);
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
}

- (IBAction)cancelNewKeyMap:(id)sender
{
	[[self window] orderOut:self];
	callBack(nil);
	[NSApp endSheet:[self window]];
}

@end

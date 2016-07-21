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

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:nibFileName owner:self topLevelObjects:nil];
	self = [super initWithWindowNibName:windowNibName];
	if (self) {
			// Set up the standard key maps popup
		[self.standardKeyMaps removeAllItems];
		[self.standardKeyMaps addItemsWithTitles:@[@"QWERTY lower case", @"QWERTY upper case",
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
	[self.infoText setStringValue:informationText];
	[self.makeCopyKeyMaps removeAllItems];
	[self.makeCopyKeyMaps addItemsWithTitles:keyMaps];
	callBack = theCallBack;
	[self.keyMapType selectCellAtRow:0 column:0];
    [self.standardKeyMaps setEnabled:NO];
    [self.makeCopyKeyMaps setEnabled:NO];
    [unlinkedCheckBox setEnabled:NO];
	[NSApp beginSheet:[self window]
	   modalForWindow:parentWindow
		modalDelegate:nil
	   didEndSelector:nil
		  contextInfo:nil];
}

- (IBAction)selectKeyMapType:(id)sender
{
#pragma unused(sender)
	switch ([self.keyMapType selectedRow]) {
		case kNewKeyMapEmpty:
			[self.standardKeyMaps setEnabled:NO];
			[self.makeCopyKeyMaps setEnabled:NO];
			[unlinkedCheckBox setEnabled:NO];
			break;

		case kNewKeyMapStandard:
			[self.standardKeyMaps setEnabled:YES];
			[self.makeCopyKeyMaps setEnabled:NO];
			[unlinkedCheckBox setEnabled:NO];
			break;

		case kNewKeyMapCopy:
			[self.standardKeyMaps setEnabled:NO];
			[self.makeCopyKeyMaps setEnabled:YES];
			[unlinkedCheckBox setEnabled:YES];
			break;
	}
}

- (IBAction)acceptNewKeyMap:(id)sender
{
#pragma unused(sender)
	NewKeyMapInfo *infoBlock = [[NewKeyMapInfo alloc] init];
	[infoBlock setKeyMapTypeSelection:[self.keyMapType selectedRow]];
	switch ([self.keyMapType selectedRow]) {
		case kNewKeyMapStandard:
			[infoBlock setStandardKeyMapSelection:[self.standardKeyMaps indexOfSelectedItem]];
			break;
			
		case kNewKeyMapCopy:
			[infoBlock setCopyKeyMapSelection:[[self.makeCopyKeyMaps titleOfSelectedItem] integerValue]];
			[infoBlock setIsUnlinked:[unlinkedCheckBox state] == NSOnState];
			break;
	}
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(infoBlock);
}

- (IBAction)cancelNewKeyMap:(id)sender
{
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(nil);
}

@end

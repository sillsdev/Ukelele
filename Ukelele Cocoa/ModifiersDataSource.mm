//
//  ModifiersDataSource.m
//  Ukelele 3
//
//  Created by John Brownie on 14/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "ModifiersDataSource.h"
#import "UkeleleKeyboardObject.h"
#import "UkeleleKeyboard.h"
#import "UkeleleConstantStrings.h"
#import "ModifierMap.h"
#import "KeyboardEnvironment.h"

enum {
	shiftIndex,
	optionIndex,
	commandIndex,
	controlIndex,
	capsLockIndex
};

#define MDSNextKey @"Next"
#define MDSPrevKey @"Prev"

@implementation ModifiersDataSource

#pragma mark Internal routines

static NSMutableDictionary *statusDictionary = nil;

- (NSAttributedString *)getStringForModifier:(NSInteger)modifier withStatus:(NSUInteger)modifierStatus {
	static NSString *optionKeyString;
	static NSString *leftOptionKeyString;
	static NSString *rightOptionKeyString;
	static NSString *shiftKeyString;
	static NSString *leftShiftKeyString;
	static NSString *rightShiftKeyString;
	static NSString *commandKeyString;
	static NSString *controlKeyString;
	static NSString *leftControlKeyString;
	static NSString *rightControlKeyString;
	static NSString *capsLockKeyString;
	static NSString *upArrowString;
	static NSString *downArrowString;
	static NSDictionary *upAttributeDictionary;
	static NSDictionary *downAttributeDictionary;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		optionKeyString = [NSString stringWithFormat:@"%C", (unsigned short)kOptionUnicode];
		leftOptionKeyString = [NSString stringWithFormat:@"L %@", optionKeyString];
		rightOptionKeyString = [NSString stringWithFormat:@"R %@", optionKeyString];
		shiftKeyString = [NSString stringWithFormat:@"%C", (unsigned short)kShiftUnicode];
		leftShiftKeyString = [NSString stringWithFormat:@"L %@", shiftKeyString];
		rightShiftKeyString = [NSString stringWithFormat:@"R %@", shiftKeyString];
		commandKeyString = [NSString stringWithFormat:@"%C", (unsigned short)kCommandUnicode];
		controlKeyString = [NSString stringWithFormat:@"%C", (unsigned short)kControlUnicode];
		leftControlKeyString = [NSString stringWithFormat:@"L %@", controlKeyString];
		rightControlKeyString = [NSString stringWithFormat:@"R %@", controlKeyString];
		capsLockKeyString = [NSString stringWithFormat:@"%C", (unsigned short)kCapsLockUnicode];
		upArrowString = [NSString stringWithFormat:@"%C", (unichar)0x2191];
		downArrowString = [NSString stringWithFormat:@"%C", (unichar)0x2193];
		upAttributeDictionary = @{NSForegroundColorAttributeName : [NSColor redColor],
			NSStrikethroughStyleAttributeName : @(NSUnderlineStyleThick)};
		downAttributeDictionary = @{NSForegroundColorAttributeName : [NSColor blueColor]};
	});
	NSAttributedString *result;
	if (modifierStatus == kModifierEither || modifierStatus == kModifierAnyOpt) {
			// No modifiers to show, so it's the empty string
		result = [[NSAttributedString alloc] initWithString:@""];
	}
	else if (modifierStatus == kModifierLeft || modifierStatus == kModifierLeftRight ||
			 modifierStatus == kModifierRight || modifierStatus == kModifierLeftOpt ||
			 modifierStatus == kModifierLeftOptRight || modifierStatus == kModifierLeftRightOpt ||
			 modifierStatus == kModifierRightOpt) {
			// Need to show both a left and a right
		NSMutableAttributedString *leftString, *rightString;
		NSAssert((modifier == shiftIndex || modifier == optionIndex || modifier == controlIndex), @"Must be a paired modifier");
		switch (modifier) {
			case shiftIndex:
				leftString = [[NSMutableAttributedString alloc] initWithString:leftShiftKeyString];
				rightString = [[NSMutableAttributedString alloc] initWithString:rightShiftKeyString];
				break;
				
			case optionIndex:
				leftString = [[NSMutableAttributedString alloc] initWithString:leftOptionKeyString];
				rightString = [[NSMutableAttributedString alloc] initWithString:rightOptionKeyString];
				break;
				
			case controlIndex:
				leftString = [[NSMutableAttributedString alloc] initWithString:leftControlKeyString];
				rightString = [[NSMutableAttributedString alloc] initWithString:rightControlKeyString];
				break;
		}
		NSMutableAttributedString *partialString = [[NSMutableAttributedString alloc] initWithString:@""];
		NSMutableAttributedString *stringFragment;
		if (modifierStatus == kModifierLeft || modifierStatus == kModifierLeftRight || modifierStatus == kModifierLeftRightOpt) {
			stringFragment = [[NSMutableAttributedString alloc] initWithAttributedString:leftString];
			[stringFragment addAttributes:downAttributeDictionary range:NSMakeRange(0, [leftString length])];
			[partialString appendAttributedString:stringFragment];
		}
		else if (modifierStatus == kModifierRight || modifierStatus == kModifierRightOpt) {
			stringFragment = [[NSMutableAttributedString alloc] initWithAttributedString:leftString];
			[stringFragment addAttributes:upAttributeDictionary range:NSMakeRange(0, [leftString length])];
			[partialString appendAttributedString:stringFragment];
		}
		NSAttributedString *separator = [[NSAttributedString alloc] initWithString:@""];
		if ([partialString length] > 0) {
			separator = [[NSAttributedString alloc] initWithString:@", "];
		}
		if (modifierStatus == kModifierRight || modifierStatus == kModifierLeftRight || modifierStatus == kModifierLeftOptRight) {
			stringFragment = [[NSMutableAttributedString alloc] initWithAttributedString:rightString];
			[stringFragment addAttributes:downAttributeDictionary range:NSMakeRange(0, [rightString length])];
			[partialString appendAttributedString:separator];
			[partialString appendAttributedString:stringFragment];
		}
		else if (modifierStatus == kModifierLeft || modifierStatus == kModifierLeftOpt) {
			stringFragment = [[NSMutableAttributedString alloc] initWithAttributedString:rightString];
			[stringFragment addAttributes:upAttributeDictionary range:NSMakeRange(0, [rightString length])];
			[partialString appendAttributedString:separator];
			[partialString appendAttributedString:stringFragment];
		}
		result = partialString;
	}
	else {
			// One modifier
		NSString *modifierString;
		switch (modifier) {
			case shiftIndex:
				modifierString = shiftKeyString;
				break;
				
			case optionIndex:
				modifierString = optionKeyString;
				break;
				
			case commandIndex:
				modifierString = commandKeyString;
				break;
				
			case controlIndex:
				modifierString = controlKeyString;
				break;
				
			case capsLockIndex:
				modifierString = capsLockKeyString;
				break;
		}
		switch (modifierStatus) {
			case kModifierNone:
			case kModifierNotPressed:
			case kModifierLeftOpt:
			case kModifierRightOpt:
				result = [[NSAttributedString alloc] initWithString:modifierString attributes:upAttributeDictionary];
				break;
				
			case kModifierPressed:
			case kModifierAny:
			case kModifierEither:
			case kModifierLeftOptRight:
			case kModifierLeftRightOpt:
				result = [[NSAttributedString alloc] initWithString:modifierString attributes:downAttributeDictionary];
				break;
		}
	}
	return result;
}

- (NSString *)getModifierString:(unsigned int)modifierStatus
{
	if (statusDictionary == nil) {
		statusDictionary = [NSMutableDictionary dictionaryWithCapacity:13];
		statusDictionary[[NSString stringWithFormat:@"%d", kModifierPressed]] = @"Down";
		statusDictionary[[NSString stringWithFormat:@"%d", kModifierNotPressed]] = @"Up";
		statusDictionary[[NSString stringWithFormat:@"%d", kModifierEither]] = @"Either Up or Down";
		statusDictionary[[NSString stringWithFormat:@"%d", kModifierNone]] = @"Both Up";
		statusDictionary[[NSString stringWithFormat:@"%d", kModifierLeft]] = @"Left Down, Right Up";
		statusDictionary[[NSString stringWithFormat:@"%d", kModifierRight]] = @"Left Up, Right Down";
		statusDictionary[[NSString stringWithFormat:@"%d", kModifierLeftRight]] = @"Both Down";
		statusDictionary[[NSString stringWithFormat:@"%d", kModifierLeftOpt]] = @"Left Down or Up, Right Up";
		statusDictionary[[NSString stringWithFormat:@"%d", kModifierRightOpt]] = @"Left Up, Right Down or Up";
		statusDictionary[[NSString stringWithFormat:@"%d", kModifierLeftOptRight]] = @"Left Down or Up, Right Down";
		statusDictionary[[NSString stringWithFormat:@"%d", kModifierLeftRightOpt]] = @"Left Down, Right Down or Up";
		statusDictionary[[NSString stringWithFormat:@"%d", kModifierAny]] = @"Either Down";
		statusDictionary[[NSString stringWithFormat:@"%d", kModifierAnyOpt]] = @"Either Down or Up";
	}
	return statusDictionary[[NSString stringWithFormat:@"%d", modifierStatus]];
}

- (void)setupArray
{
	boost::shared_ptr<KeyboardElement> keyboardElement = [keyboardLayout keyboard]->GetKeyboard();
	ModifierMap *modMap = keyboardElement->GetModifierMap(static_cast<UInt32>([[KeyboardEnvironment instance] currentKeyboardID]));
	unsigned int rowCount = 0;
	int keyMapSelectCount = modMap->GetKeyMapSelectCount();
	for (int selectIndex = 0; selectIndex < keyMapSelectCount; selectIndex++) {
		KeyMapSelect *selectElement = modMap->GetKeyMapSelectElement(selectIndex);
		if (selectElement == NULL) {
			continue;
		}
		unsigned int selectID = selectElement->GetKeyMapSelectIndex();
		SInt32 mapCount = selectElement->GetModifierElementCount();
		for (SInt32 mapIndex = 1; mapIndex <= mapCount; mapIndex++) {
			ModifierElement *modifierElement = selectElement->GetModifierElement(mapIndex);
			NSMutableDictionary *rowEntry = [NSMutableDictionary dictionaryWithCapacity:7];
			rowEntry[kLabelIndex] = @{kLabelIntegerRepresentation: @(selectID), kLabelStringRepresentation: [NSString stringWithFormat:@"%d", selectID]};
			rowEntry[kLabelSubindex] = @{kLabelIntegerRepresentation: @(mapIndex), kLabelStringRepresentation: [NSString stringWithFormat:@"%d", mapIndex]};
			UInt32 modifierStatus = modifierElement->GetModifierPairStatus(shiftKey, rightShiftKey);
			rowEntry[kLabelShift] = @{kLabelIntegerRepresentation: @(modifierStatus), kLabelStringRepresentation: [self getStringForModifier:shiftIndex withStatus:modifierStatus]};
			modifierStatus = modifierElement->GetModifierStatus(alphaLock);
			rowEntry[kLabelCapsLock] = @{kLabelIntegerRepresentation: @(modifierStatus), kLabelStringRepresentation: [self getStringForModifier:capsLockIndex withStatus:modifierStatus]};
			modifierStatus = modifierElement->GetModifierPairStatus(optionKey, rightOptionKey);
			rowEntry[kLabelOption] = @{kLabelIntegerRepresentation: @(modifierStatus), kLabelStringRepresentation: [self getStringForModifier:optionIndex withStatus:modifierStatus]};
			modifierStatus = modifierElement->GetModifierStatus(cmdKey);
			rowEntry[kLabelCommand] = @{kLabelIntegerRepresentation: @(modifierStatus), kLabelStringRepresentation: [self getStringForModifier:commandIndex withStatus:modifierStatus]};
			modifierStatus = modifierElement->GetModifierPairStatus(controlKey, rightControlKey);
			rowEntry[kLabelControl] = @{kLabelIntegerRepresentation: @(modifierStatus), kLabelStringRepresentation: [self getStringForModifier:controlIndex withStatus:modifierStatus]};
			[rowArray insertObject:rowEntry atIndex:rowCount];
			rowCount++;
		}
	}
	NSArray *modifierIndices = [keyboardLayout getModifierIndices];
	[indexDictionary removeAllObjects];
	for (NSInteger i = 0; i < [modifierIndices count]; i++) {
		NSMutableDictionary *indexRelations = [NSMutableDictionary dictionary];
		if (i > 0) {
			indexRelations[MDSPrevKey] = modifierIndices[i - 1];
		}
		if (i < [modifierIndices count] - 1) {
			indexRelations[MDSNextKey] = modifierIndices[i + 1];
		}
		indexDictionary[modifierIndices[i]] = indexRelations;
	}
}

#pragma mark Initialisation

- (id)init {
	return [self initWithKeyboardObject:nil];
}

- (id)initWithKeyboardObject:(UkeleleKeyboardObject *)keyboard
{
	self = [super init];
	if (self) {
		keyboardLayout = keyboard;
			// Set up the array
		rowArray = [NSMutableArray array];
		indexDictionary = [NSMutableDictionary dictionary];
		if (keyboard) {
			[self setupArray];
		}
	}
	return self;
}


- (UkeleleKeyboardObject *)keyboard
{
	return keyboardLayout;
}

- (void)setKeyboard:(UkeleleKeyboardObject *)keyboard
{
	keyboardLayout = keyboard;
	if (keyboard) {
		[self updateKeyboard];
	}
}

- (void)updateKeyboard
{
		// Update the array
	[rowArray removeAllObjects];
	[self setupArray];
}

#pragma mark Fetch data

- (NSInteger)modifierValueForRow:(NSInteger)rowNumber column:(NSString *)columnLabel
{
	NSDictionary *rowEntry = rowArray[rowNumber];
	NSDictionary *statusDict = rowEntry[columnLabel];
	return [statusDict[kLabelIntegerRepresentation] integerValue];
}

- (NSInteger)indexForRow:(NSInteger)rowNumber
{
	NSDictionary *rowEntry = rowArray[rowNumber];
	NSDictionary *indexEntry = rowEntry[kLabelIndex];
	return [indexEntry[kLabelIntegerRepresentation] integerValue];
}

- (NSInteger)subindexForRow:(NSInteger)rowNumber
{
	NSDictionary *rowEntry = rowArray[rowNumber];
	NSDictionary *indexEntry = rowEntry[kLabelSubindex];
	return [indexEntry[kLabelIntegerRepresentation] integerValue];
}

#pragma mark Table data source methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [rowArray count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSDictionary *rowData = rowArray[row];
	NSDictionary *statusData = rowData[[tableColumn identifier]];
	return statusData[kLabelStringRepresentation];
}

#pragma mark Drag and drop

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
	if ([rowIndexes count] != 1) {
			// Only drag single rows
		return NO;
	}
	NSData *pasteboardData = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
	[pboard declareTypes:@[ModifiersTableDragType] owner:self];
	[pboard setData:pasteboardData forType:ModifiersTableDragType];
	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
		// We don't accept drops on a row, but only between them
	if (dropOperation == NSTableViewDropOn) {
		return NSDragOperationNone;
	}
		// We can accept a drop anywhere except in the same set
	NSInteger proposedRowSet;
	if (row >= [rowArray count]) {
			// Dropping at the end of the table
		proposedRowSet = [self indexForRow:[rowArray count] - 1];
	}
	else {
		proposedRowSet = [self indexForRow:row];
	}
	NSPasteboard *pboard = [info draggingPasteboard];
	NSData *pbData = [pboard dataForType:ModifiersTableDragType];
	NSIndexSet *sourceIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:pbData];
	NSUInteger sourceIndex = [sourceIndexes firstIndex];
	NSInteger sourceRowSet = [self indexForRow:sourceIndex];
	NSInteger nextSet = sourceRowSet;
	NSDictionary *sourceSetRelations = indexDictionary[@(sourceRowSet)];
	if (sourceSetRelations != nil) {
		NSNumber *nextSetObject = sourceSetRelations[MDSNextKey];
		if (nextSetObject != nil) {
			nextSet = [nextSetObject integerValue];
		}
	}
	if (proposedRowSet == sourceRowSet || proposedRowSet == nextSet) {
			// Same set, so can't accept a drop here
		return NSDragOperationNone;
	}
		// Find the first row with the destination set number
	NSInteger destinationRow;
	if (row >= [rowArray count]) {
		destinationRow = row;
	}
	else {
		for (destinationRow = row; destinationRow > 0; destinationRow--) {
			if ([self indexForRow:destinationRow - 1] != proposedRowSet) {
				break;
			}
		}
	}
	[tableView setDropRow:destinationRow dropOperation:NSTableViewDropAbove];
	return NSDragOperationMove;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
	NSInteger destinationSet;
	if (row >= [rowArray count]) {
		destinationSet = [self indexForRow:[rowArray count] - 1] + 1;
	}
	else {
		destinationSet = [self indexForRow:row];
	}
	NSPasteboard *pboard = [info draggingPasteboard];
	NSData *pbData = [pboard dataForType:ModifiersTableDragType];
	NSIndexSet *sourceIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:pbData];
	NSUInteger sourceIndex = [sourceIndexes firstIndex];
	NSInteger sourceRowSet = [self indexForRow:sourceIndex];
	if (destinationSet > sourceRowSet) {
		destinationSet = [indexDictionary[@(destinationSet)][MDSPrevKey] integerValue];
	}
		// Now we need to tell the document to move the source set to the destination set
	[keyboardLayout moveModifierSetIndex:sourceRowSet toIndex:destinationSet forKeyboard:[[KeyboardEnvironment instance] currentKeyboardID]];
	[self updateKeyboard];
	return YES;
}

@end

//
//  KeyboardResourceList.m
//  Ukelele 3
//
//  Created by John Brownie on 29/02/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "KeyboardResourceList.h"
#import "LayoutInfo.h"
#import "UkeleleConstantStrings.h"
#import "UkeleleConstants.h"
#import <Carbon/Carbon.h>

	// Dictionary keys
NSString *kKeyKeyboardName = @"name";
NSString *kKeyKeyboardDescription = @"description";
NSString *kKeyCodingList = @"coding";
NSString *kKeyKeyboardIDs = @"keyboardID";
NSString *kKeyNameIndex = @"nameIndex";
NSString *kKeyCodingIndex = @"codingIndex";

@implementation KeyboardType

+ (KeyboardType *)keyboardTypeName:(NSString *)theName
				   withDescription:(NSString *)theDescription
					   withCodings:(NSArray *)theCodings
						   withIDs:(NSArray *)theIDs
{
	KeyboardType *result = [[KeyboardType alloc] init];
	[result setKeyboardName:theName];
	[result setKeyboardDescription:theDescription];
	[result setKeyboardCodings:theCodings];
	[result setKeyboardResourceIDs:theIDs];
	return result;
}

@end

@implementation KeyboardResourceList {
	NSArray *knownKeyboardsList;
	NSArray *unknownKeyboardsList;
	NSArray *resourceSet;
}

- (instancetype)init
{
	self = [super init];
	if (self) {
			// Initialise
			// Build a list of all the KCAP resources available
		NSURL *resourceListURL = [[NSBundle mainBundle] URLForResource:UKKCAPListFile withExtension:@"plist"];
		NSDictionary *resourceDict = [NSDictionary dictionaryWithContentsOfURL:resourceListURL];
		NSInteger resCount = [resourceDict count];
		NSAssert(resCount > 0, @"There must be at least one resource");
		NSMutableArray *resourceIDs = [NSMutableArray arrayWithCapacity:resCount];
		NSNumberFormatter *theFormatter = [[NSNumberFormatter alloc] init];
		for (NSString *theKey in [resourceDict allKeys]) {
			[resourceIDs addObject:[theFormatter numberFromString:theKey]];
		}
		
			// Go through the list and pick out the basic types
		resourceSet = resourceIDs;
		NSMutableSet *nameSet = [NSMutableSet setWithCapacity:resCount];
		NSMutableSet *unknownSet = [NSMutableSet setWithCapacity:resCount];
		for (NSNumber *currentRes in resourceSet) {
			NSInteger currentResourceID = [currentRes integerValue];
			NSInteger keyboardNameIndex = [LayoutInfo getKeyboardNameIndex:(int)currentResourceID];
			if (0 == keyboardNameIndex) {
				[unknownSet addObject:@(currentResourceID)];
			}
			else {
				[nameSet addObject:@(keyboardNameIndex)];
			}
		}
		NSComparator integerSort = ^(id obj1, id obj2) {
			
			if ([obj1 integerValue] > [obj2 integerValue]) {
				return (NSComparisonResult)NSOrderedDescending;
			}
			
			if ([obj1 integerValue] < [obj2 integerValue]) {
				return (NSComparisonResult)NSOrderedAscending;
			}
			return (NSComparisonResult)NSOrderedSame;
		};
		knownKeyboardsList = [[nameSet allObjects] sortedArrayUsingComparator:integerSort];
		unknownKeyboardsList = [[unknownSet allObjects] sortedArrayUsingComparator:integerSort];
		
			// Go through the knowns
		NSMutableArray *keyboardTypes = [NSMutableArray array];
		for (NSNumber *nameElement in knownKeyboardsList) {
			NSUInteger knownIndex = [nameElement unsignedIntegerValue];
			NSUInteger knownID = [LayoutInfo getKeyboardID:(unsigned)knownIndex];
			NSUInteger keyboardType = [LayoutInfo getKeyboardType:(int)knownID];
			NSDictionary *typeDictionary = [LayoutInfo getKeyboardList:(unsigned)knownIndex];
			NSMutableArray *keyboardIDList = [NSMutableArray array];
			NSMutableArray *codingList = [NSMutableArray array];
			if (kSingleCodeKeyboard == keyboardType) {
				[keyboardIDList addObject:typeDictionary[kKeyAllTypes]];
			}
			else {
				NSNumber *keyboardID = typeDictionary[kKeyANSIType];
				if (0 != [keyboardID integerValue] && [resourceSet containsObject:keyboardID]) {
						// Have the ANSI keyboard
					[keyboardIDList addObject:keyboardID];
					[codingList addObject:kCodeStringANSI];
				}
				keyboardID = typeDictionary[kKeyISOType];
				if (0 != [keyboardID integerValue] && [resourceSet containsObject:keyboardID]) {
						// Have the ISO keyboard
					[keyboardIDList addObject:keyboardID];
					[codingList addObject:kCodeStringISO];
				}
				keyboardID = typeDictionary[kKeyJISType];
				if (0 != [keyboardID integerValue] && [resourceSet containsObject:keyboardID]) {
						// Have the JIS keyboard
					[keyboardIDList addObject:keyboardID];
					[codingList addObject:kCodeStringJIS];
				}
			}
			NSString *keyboardName = [LayoutInfo getKeyboardName:(int)knownIndex];
			NSString *keyboardDescription = [LayoutInfo getKeyboardDescription:(int)knownIndex];
			KeyboardType *keyboardEntry = [KeyboardType keyboardTypeName:keyboardName
														 withDescription:keyboardDescription
															 withCodings:codingList
																 withIDs:keyboardIDList];
			[keyboardTypes addObject:keyboardEntry];
		}
		
			// Go through the unknowns
		NSString *unknownNameFormat = @"Unknown (ID = %d)";
		NSString *unknownDescFormat = @"Unknown keyboard type (ID = %d)";
		for (NSNumber *unknownItem in unknownKeyboardsList) {
			NSInteger unknownID = [unknownItem integerValue];
			NSString *unknownName = [NSString stringWithFormat:unknownNameFormat, unknownID];
			NSString *unknownDesc = [NSString stringWithFormat:unknownDescFormat, unknownID];
			KeyboardType *unknownEntry = [KeyboardType keyboardTypeName:unknownName
														withDescription:unknownDesc
															withCodings:@[]
																withIDs:@[unknownItem]];
			[keyboardTypes addObject:unknownEntry];
		}
		self.keyboardTypeTable = keyboardTypes;
	}
	return self;
}

+ (KeyboardResourceList *)getInstance
{
	static KeyboardResourceList *theInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		theInstance = [[KeyboardResourceList alloc] init];
	});
	return theInstance;
}

- (NSInteger)resourceForType:(NSInteger)typeIndex code:(NSInteger)codeIndex
{
	KeyboardType *keyboardList = self.keyboardTypeTable[typeIndex];
	NSArray *idList = [keyboardList keyboardResourceIDs];
	NSNumber *keyboardID = idList[codeIndex];
	return [keyboardID integerValue];
}

- (NSDictionary *)indicesForResourceID:(NSInteger)resourceID
{
		// Find the resource ID in the name list
	NSInteger nameIndex = -1;
	NSNumber *resourceIDNumber = @(resourceID);
	if ([resourceSet containsObject:@(resourceID)]) {
		NSInteger keyboardNameIndex = [LayoutInfo getKeyboardNameIndex:(int)resourceID];
		if (keyboardNameIndex != 0) {
			for (nameIndex = 0; nameIndex < (NSInteger)[knownKeyboardsList count]; nameIndex++) {
				if ([LayoutInfo getKeyboardNameIndex:[resourceIDNumber intValue]] == [knownKeyboardsList[nameIndex] intValue]) {
					break;
				}
			}
		}
		else {
			NSInteger index;
			for (index = 0; index < (NSInteger)[unknownKeyboardsList count]; index++) {
				if ([resourceIDNumber isEqualToNumber:unknownKeyboardsList[index]]) {
					break;
				}
			}
			nameIndex = index + [knownKeyboardsList count];
		}
	}
		// Now work out the index in the type list
		//	Get the type for the resource
	PhysicalKeyboardLayoutType layoutType = KBGetLayoutType((SInt16)resourceID);
		//	Get the list of keyboards of this type
	NSDictionary *keyboardList = nil;
	if (nameIndex >= 0 && nameIndex < (NSInteger)[knownKeyboardsList count]) {
		keyboardList = [LayoutInfo getKeyboardList:(unsigned)nameIndex];
	}
	else {
		NSNumber *resID = @(resourceID);
		keyboardList = @{kKeyAllTypes: resID,
						kKeyANSIType: resID, kKeyISOType: resID, kKeyJISType: resID};
	}
		//	Look up the types from LayoutInfo
	NSInteger typeIndex = -1;
	switch ([LayoutInfo getKeyboardLayoutType:(int)resourceID]) {
		case kSingleCodeKeyboard:
				//	If it's a universal keyboard, there's no index
			typeIndex = -1;
		break;
			
				//	When only one type is available, the index is 1
		case kANSIOnlyKeyboard:
			typeIndex = 1;
		break;
			
		case kISOOnlyKeyboard:
			typeIndex = 1;
		break;
			
		case kJISOnlyKeyboard:
			typeIndex = 1;
		break;
			
				//	When two types are available, we have to find out whether the
				//	first is present if we're looking at the second of two
		case kANSIISOKeyboard:
			if (layoutType == kKeyboardANSI) {
				typeIndex = 1;
			}
			else if ([resourceSet containsObject:keyboardList[kKeyANSIType]]) {
				typeIndex = 2;
			}
			else {
				typeIndex = 1;
			}
		break;
			
		case kANSIJISKeyboard:
			if (layoutType == kKeyboardANSI) {
				typeIndex = 1;
			}
			else if ([resourceSet containsObject:keyboardList[kKeyANSIType]]) {
				typeIndex = 2;
			}
			else {
				typeIndex = 1;
			}
		break;
			
		case kISOJISKeyboard:
			if (layoutType == kKeyboardISO) {
				typeIndex = 1;
			}
			else if ([resourceSet containsObject:keyboardList[kKeyISOType]]) {
				typeIndex = 2;
			}
			else {
				typeIndex = 1;
			}
		break;
			
				//	When all three types are possible, we need to find out which
				//	ones are actually present.
		case kANSIISOJISKeyboard:
			if (layoutType == kKeyboardANSI) {
				typeIndex = 1;
			}
			else if ([resourceSet containsObject:keyboardList[kKeyANSIType]]) {
					//	ANSI is present
				if ([resourceSet containsObject:keyboardList[kKeyISOType]]) {
						//	ANSI and ISO present
					if (layoutType == kKeyboardISO) {
						typeIndex = 2;
					}
					else {
						typeIndex = 3;
					}
				}
				else {
						//	ANSI and JIS present
					typeIndex = 2;
				}
			}
			else if ([resourceSet containsObject:keyboardList[kKeyISOType]]) {
					//	ANSI not present, but ISO is present
				if (layoutType == kKeyboardISO) {
					typeIndex = 1;
				}
				else {
					typeIndex = 2;
				}
			}
			else {
					//	Only JIS present
				typeIndex = 1;
			}
		break;
	}
	NSAssert(typeIndex == -1 || (typeIndex >= 1 && typeIndex <= 3), @"Must have a valid index");
	NSDictionary *theIndices = @{kKeyNameIndex: @(nameIndex),
								kKeyCodingIndex: @(typeIndex)};
	return theIndices;
}

@end

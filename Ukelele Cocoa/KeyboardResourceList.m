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
	NSSet *resourceSet;
}

- (id)init
{
	self = [super init];
	if (self) {
			// Initialise
			// Build a list of all the KCAP resources available
			// Code from Think Reference
		SInt16 resCount = CountResources('KCAP');
		NSMutableSet *resourceIDs = [NSMutableSet setWithCapacity:resCount];
		SetResLoad(false);			// do not need resource, just info
		for (SInt16 j = 1; j <= resCount; j++) {
			Handle resHandle = GetIndResource('KCAP', j);
			ResType resType;
			SInt16 resID;
			unsigned char resName[256];
			GetResInfo(resHandle, &resID, &resType, resName);
			[resourceIDs addObject:@((NSInteger)resID)];
		}
		SetResLoad(true);				// better do this!
		resourceSet = resourceIDs;
		
			// Go through the list and pick out the basic types
		resCount = [resourceSet count];
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
	if (theInstance == nil) {
		theInstance = [[KeyboardResourceList alloc] init];
	}
	return theInstance;
}

- (NSInteger)resourceForType:(NSInteger)typeIndex code:(NSInteger)codeIndex
{
	KeyboardType *keyboardList = _keyboardTypeTable[typeIndex];
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
			for (nameIndex = 0; nameIndex < [knownKeyboardsList count]; nameIndex++) {
				if ([LayoutInfo getKeyboardNameIndex:[resourceIDNumber intValue]] == [knownKeyboardsList[nameIndex] intValue]) {
					break;
				}
			}
		}
		else {
			NSInteger index;
			for (index = 0; index < [unknownKeyboardsList count]; index++) {
				if ([resourceIDNumber isEqualToNumber:unknownKeyboardsList[index]]) {
					break;
				}
			}
			nameIndex = index + [knownKeyboardsList count];
		}
	}
		// Now work out the index in the type list
		//	Get the type for the resource
	PhysicalKeyboardLayoutType layoutType = KBGetLayoutType(resourceID);
		//	Get the list of keyboards of this type
	NSDictionary *keyboardList = nil;
	if (nameIndex >= 0 && nameIndex < [knownKeyboardsList count]) {
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
	NSDictionary *theIndices = @{kKeyNameIndex: @(nameIndex),
								kKeyCodingIndex: @(typeIndex)};
	return theIndices;
}

- (NSArray *)namesList
{
	NSMutableArray *theNames = [NSMutableArray arrayWithCapacity:[_keyboardTypeTable count]];
	for (KeyboardType *element in _keyboardTypeTable) {
		[theNames addObject:[element keyboardName]];
	}
	return theNames;
}

- (NSArray *)descriptionsList
{
	NSMutableArray *theDescriptions = [NSMutableArray arrayWithCapacity:[_keyboardTypeTable count]];
	for (KeyboardType *element in _keyboardTypeTable) {
		[theDescriptions addObject:[element keyboardDescription]];
	}
	return theDescriptions;
}

- (NSArray *)codingsForType:(NSInteger)typeIndex
{
	return [_keyboardTypeTable[typeIndex] keyboardCodings];
}

@end

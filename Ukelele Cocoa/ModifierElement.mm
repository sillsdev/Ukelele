/*
 *  ModifierElement.mm
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "ModifierElement.h"
#include "UkeleleConstants.h"
#include "XMLErrors.h"
#include "UkeleleStrings.h"
#include "NBundle.h"
#include "NCocoa.h"

// Key strings
const NString kModifierElementMissingKeysAttribute = "ModifierElementMissingKeysAttribute";
const NString kModifierElementUnknownModifier = "ModifierElementUnknownModifier";

#pragma mark === ModifierElement ===

// Constructor

ModifierElement::ModifierElement(void)
	: XMLCommentHolder(kModifierElementType)
{
}

// Copy constructor

ModifierElement::ModifierElement(const ModifierElement& inOriginal)
	: XMLCommentHolder(inOriginal)
{
	mModifierString = inOriginal.mModifierString;
	mModifierMap = inOriginal.mModifierMap;
}

// Destructor

ModifierElement::~ModifierElement(void)
{
}

#pragma mark -

// Add a modifier key with its status

ErrorMessage ModifierElement::AddModifierKey(const UInt32 inModifier, const UInt32 inStatus)
{
	AddModifier(inModifier, 0, inStatus);
	mModifierString = CreateModifierString();
	return ErrorMessage(XMLNoError, "");
}

// Add a modifier key by name

ErrorMessage ModifierElement::AddModifierKey(NString inModifierName)
{
	if (inModifierName.IsEmpty()) {
		return ErrorMessage(XMLNoError, "");
	}
	ModifierKeyStringTable *stringTable = ModifierKeyStringTable::GetInstance();
	UInt32 leftModifier, rightModifier;
	UInt32 keyStatus;
	if (stringTable->GetMatchKeys(inModifierName, leftModifier, rightModifier, keyStatus)) {
		AddModifier(leftModifier, rightModifier, keyStatus);
		AddModifierName(inModifierName);
		return ErrorMessage(XMLNoError, "");
	}
	NString errorFormat = NBundleString(kModifierElementUnknownModifier, "", kErrorTableName);
	NString errorMessage;
	errorMessage.Format(errorFormat, inModifierName);
	return ErrorMessage(XMLUnknownModifierError, errorMessage);
}

// Add a list of modifiers

ErrorMessage ModifierElement::AddModifierKeyList(NString inModifierList)
{
	// Split the given string on white space
	NStringList splitList = inModifierList.Split(" ", kNStringPattern);
	// Add each modifier
	ErrorMessage errorStatus(XMLNoError, "");
	for (NStringListIterator pos = splitList.begin(); pos != splitList.end() && errorStatus == XMLNoError; ++pos) {
		NString modifierString = *pos;
		errorStatus = AddModifierKey(modifierString);
	}
	if (errorStatus == XMLNoError) {
		mModifierString = CreateModifierString();
	}
	return errorStatus;
}

// Get status for a modifier

UInt32 ModifierElement::GetModifierStatus(const UInt32 inModifier)
{
	UInt32 numMaps = static_cast<UInt32>(mModifierMap.size());
	if (numMaps == 0) {
		return kModifierNotPressed;
	}
	UInt32 result = inModifier & mModifierMap[0] ? kModifierPressed : kModifierNotPressed;
	for (UInt32 i = 1; i < numMaps; i++) {
		UInt32 state = inModifier & mModifierMap[i] ? kModifierPressed : kModifierNotPressed;
		if (result != state) {
			return kModifierEither;
		}
	}
	return result;
}

// Get status for a pair of modifiers

UInt32 ModifierElement::GetModifierPairStatus(const UInt32 inLeftModifier, const UInt32 inRightModifier)
{
	UInt32 numMaps = static_cast<UInt32>(mModifierMap.size());
	if (numMaps == 0) {
		return kModifierNone;
	}
	UInt32 modifiers = mModifierMap[0];
	UInt32 result;
	if (modifiers & inLeftModifier) {
		if (modifiers & inRightModifier) {
			result = kModifierLeftRight;
		}
		else {
			result = kModifierLeft;
		}
	}
	else {
		if (modifiers & inRightModifier) {
			result = kModifierRight;
		}
		else {
			result = kModifierNone;
		}
	}
	for (UInt32 i = 1; i < numMaps; i++) {
		modifiers = mModifierMap[i];
		if (modifiers & inLeftModifier) {
			if (modifiers & inRightModifier) {
				result |= kModifierLeftRight;
			}
			else {
				result |= kModifierLeft;
			}
		}
		else {
			if (modifiers & inRightModifier) {
				result |= kModifierRight;
			}
			else {
				result |= kModifierNone;
			}
		}
	}
	return result;
}

// Get all the modifiers

void ModifierElement::GetModifierStatus(UInt32& outShift,
										UInt32& outCapsLock,
										UInt32& outOption,
										UInt32& outCommand,
										UInt32& outControl)
{
	outShift = GetModifierPairStatus(shiftKey, rightShiftKey);
	outCapsLock = GetModifierStatus(alphaLock);
	outOption = GetModifierPairStatus(optionKey, rightOptionKey);
	outCommand = GetModifierStatus(cmdKey);
	outControl = GetModifierPairStatus(controlKey, rightControlKey);
}

// Get the key list as a string

NString ModifierElement::GetModifierKeyList(void)
{
	return mModifierString;
}

// Set modifier status

void ModifierElement::SetModifierStatus(const UInt32 inShift,
										const UInt32 inCapsLock,
										const UInt32 inOption,
										const UInt32 inCommand,
										const UInt32 inControl)
{
	// First, remove all current modifier keys
	while (mModifierMap.size() > 0) {
		mModifierMap.pop_back();
	}
	mModifierString = "";
	
	// Now add the new modifier keys
	AddModifierPair(shiftKey, rightShiftKey, inShift);
	AddModifier(alphaLock, 0, inCapsLock);
	AddModifierPair(optionKey, rightOptionKey, inOption);
	AddModifier(cmdKey, 0, inCommand);
	AddModifierPair(controlKey, rightControlKey, inControl);
	mModifierString = CreateModifierString();
}

// Test whether a modifier combination matches

bool ModifierElement::ModifierMatches(const UInt32 inModifierCombination)
{
	if (mModifierMap.size() == 0) {
		// If there are no modifier maps, only no modifiers can match
		return inModifierCombination == 0;
	}
	return std::binary_search(mModifierMap.begin(), mModifierMap.end(), inModifierCombination);
}

#pragma mark -

// Set up the modifier string

NString ModifierElement::CreateModifierString(void)
{
	ModifierKeyStringTable *stringTable = ModifierKeyStringTable::GetInstance();
	NString modifierString("");
	UInt32 status = GetModifierPairStatus(shiftKey, rightShiftKey);
	if (status != kModifierNone) {
		NString shiftString = stringTable->GetKeyString(shiftKey, status);
		modifierString += shiftString;
	}
	status = GetModifierStatus(alphaLock);
	if (status != kModifierNotPressed) {
		NString capsLockString = stringTable->GetKeyString(alphaLock, status);
		if (!modifierString.IsEmpty()) {
			modifierString += " ";
		}
		modifierString += capsLockString;
	}
	status = GetModifierPairStatus(optionKey, rightOptionKey);
	if (status != kModifierNone) {
		NString optionString = stringTable->GetKeyString(optionKey, status);
		if (!modifierString.IsEmpty()) {
			modifierString += " ";
		}
		modifierString += optionString;
	}
	status = GetModifierStatus(cmdKey);
	if (status != kModifierNotPressed) {
		NString cmdString = stringTable->GetKeyString(cmdKey, status);
		if (!modifierString.IsEmpty()) {
			modifierString += " ";
		}
		modifierString += cmdString;
	}
	status = GetModifierPairStatus(controlKey, rightControlKey);
	if (status != kModifierNone) {
		NString controlString = stringTable->GetKeyString(controlKey, status);
		if (!modifierString.IsEmpty()) {
			modifierString += " ";
		}
		modifierString += controlString;
	}
	return modifierString;
}

// Add a modifier or modifier pair to the current list

void ModifierElement::AddModifier(const UInt32 key1, const UInt32 key2, const UInt32 status)
{
	// Calculate the number of combinations will be generated
	UInt32 numMaps = 0;
	UInt32 modifierCombinations[4];
	if (key2 == 0) {
		// Just one modifier key
		if (status == kModifierPressed) {
			// Just the key by itself
			numMaps = 1;
			modifierCombinations[0] = key1;
		}
		else if (status == kModifierEither) {
			// Key pressed or not pressed
			numMaps = 2;
			modifierCombinations[0] = 0;
			modifierCombinations[1] = key1;
		}
		// Else nothing to add
	}
	else {
		// We have a pair, and it should be one of the "any" options
		if (status == kModifierPressed) {
			// Either or both keys presssed
			numMaps = 3;
			modifierCombinations[0] = key1;
			modifierCombinations[1] = key2;
			modifierCombinations[2] = key1 | key2;
		}
		else if (status == kModifierEither) {
			// Either key pressed or not pressed
			numMaps = 4;
			modifierCombinations[0] = 0;
			modifierCombinations[1] = key1;
			modifierCombinations[2] = key2;
			modifierCombinations[3] = key1 | key2;
		}
		// Else nothing to add
	}
	
	// Now run through each existing map
	UInt32 numExistingMaps = static_cast<UInt32>(mModifierMap.size());
	if (numExistingMaps == 0) {
		// No existing maps, so just add these combinations
		for (UInt32 combination = 0; combination < numMaps; combination++) {
			mModifierMap.push_back(modifierCombinations[combination]);
		}
	}
	else {
		// Compose each existing map with the different combinations
		for (UInt32 map = 0; map < numExistingMaps; map++) {
			// Get the map
			UInt32 originalMap = mModifierMap[map];
			// Compose it with all the combinations
			for (UInt32 combination = 0; combination < numMaps; combination++) {
				UInt32 newMap = originalMap | modifierCombinations[combination];
				if (combination == 0) {
					// Replace with the new map
					mModifierMap[map] = newMap;
				}
				else {
					// Append the new map
					mModifierMap.push_back(newMap);
				}
			}
		}
	}
	std::sort(mModifierMap.begin(), mModifierMap.end());
}

// Add a modifier name to the list of modifiers

void ModifierElement::AddModifierName(NString inName)
{
	if (mModifierString.IsEmpty()) {
		mModifierString = "";
	}
	if (!mModifierString.IsEmpty()) {
		mModifierString += " ";
	}
	mModifierString += inName;
}

// Add a modifier pair

void ModifierElement::AddModifierPair(const UInt32 inLeft, const UInt32 inRight, const UInt32 inStatus)
{
	switch (inStatus) {
		case kModifierNotPressed:
		case kModifierNone:
			// Nothing to do
		break;
		
		case kModifierPressed:
		case kModifierAny:
			AddModifier(inLeft, inRight, kModifierPressed);
		break;
		
		case kModifierEither:
		case kModifierAnyOpt:
			AddModifier(inLeft, inRight, kModifierEither);
		break;
		
		case kModifierLeft:
			AddModifier(inLeft, 0, kModifierPressed);
		break;
		
		case kModifierLeftOpt:
			AddModifier(inLeft, 0, kModifierEither);
		break;
		
		case kModifierRight:
			AddModifier(inRight, 0, kModifierPressed);
		break;
		
		case kModifierRightOpt:
			AddModifier(inRight, 0, kModifierEither);
		break;
		
		case kModifierLeftRight:
			AddModifier(inLeft, 0, kModifierPressed);
			AddModifier(inRight, 0, kModifierPressed);
		break;
		
		case kModifierLeftOptRight:
			AddModifier(inLeft, 0, kModifierEither);
			AddModifier(inRight, 0, kModifierPressed);
		break;
		
		case kModifierLeftRightOpt:
			AddModifier(inLeft, 0, kModifierPressed);
			AddModifier(inRight, 0, kModifierEither);
		break;
		
		default:
			// Should never get here!
		break;
	}
}

#pragma mark -

// Create a modifier element from an XML tree

ErrorMessage ModifierElement::CreateFromXMLTree(const NXMLNode& inXMLTree, ModifierElement*& outElement)
{
	ErrorMessage errorValue(XMLNoError, "");
	NN_ASSERT(inXMLTree.IsElement(kModifierElement));
	NDictionary attributeDictionary = inXMLTree.GetElementAttributes();
	if (!attributeDictionary.HasKey(kKeysAttribute)) {
		// No keys attribute
		NString errorString = NBundleString(kModifierElementMissingKeysAttribute, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorString);
		return errorValue;
	}
	NString keysAttribute = inXMLTree.GetElementAttribute(kKeysAttribute);
	outElement = new ModifierElement();
	errorValue = outElement->AddModifierKeyList(keysAttribute);
	if (errorValue != XMLNoError) {
		delete outElement;
		outElement = NULL;
	}
	return errorValue;
}

// Create an XML tree

NXMLNode *ModifierElement::CreateXMLTree(void)
{
	NXMLNode *xmlTree = new NXMLNode(kNXMLNodeElement, kModifierElement);
	xmlTree->SetElementUnpaired(true);
	xmlTree->SetElementAttribute(kKeysAttribute, GetModifierKeyList());
	AddCommentsToXMLTree(*xmlTree);
	return xmlTree;
}

NString ModifierElement::GetDescription(void)
{
	NString descriptionString;
	descriptionString.Format("modifiers \"%@\"", GetModifierKeyList());
	return descriptionString;
}

// Create a simplified version, that is one which only deals with left modifiers

UInt32 ModifierElement::SimplifiedModifier(const UInt32 inStatus)
{
    UInt32 status = inStatus;
    switch (inStatus) {
        case kModifierNotPressed:
        case kModifierPressed:
        case kModifierEither:
            break;
            
        case kModifierNone:
        case kModifierAny:
        case kModifierAnyOpt:
            // No change
            break;
            
        case kModifierLeft:
        case kModifierLeftRight:
        case kModifierLeftRightOpt:
            status = kModifierAny;
            break;
            
        case kModifierLeftOpt:
        case kModifierLeftOptRight:
            status = kModifierAnyOpt;
            break;
            
        case kModifierRight:
        case kModifierRightOpt:
            status = kModifierNone;
            break;
    }
    return status;
}

ModifierElement *ModifierElement::SimplifiedModifierElement(void)
{
    ModifierElement *simplifiedElement = new ModifierElement();
	UInt32 capsLockStatus = GetModifierStatus(alphaLock);
	UInt32 cmdStatus = GetModifierStatus(cmdKey);
	UInt32 shiftStatus = SimplifiedModifier(GetModifierPairStatus(shiftKey, rightShiftKey));
	UInt32 optionStatus = SimplifiedModifier(GetModifierPairStatus(optionKey, rightOptionKey));
	UInt32 controlStatus = SimplifiedModifier(GetModifierPairStatus(controlKey, rightControlKey));
	simplifiedElement->SetModifierStatus(shiftStatus, capsLockStatus, optionStatus, cmdStatus, controlStatus);
    return simplifiedElement;
}

// Test whether a modifier combination can be simplified

bool ModifierElement::IsSimple(const UInt32 inStatus)
{
    switch (inStatus) {
        case kModifierLeft:
        case kModifierLeftOpt:
        case kModifierLeftRight:
        case kModifierLeftOptRight:
        case kModifierLeftRightOpt:
        case kModifierRight:
        case kModifierRightOpt:
            return false;
    }
    return true;
}

bool ModifierElement::IsSimplified(void)
{
    if (!IsSimple(GetModifierPairStatus(shiftKey, rightShiftKey))) {
        return false;
    }
    if (!IsSimple(GetModifierPairStatus(optionKey, rightOptionKey))) {
        return false;
    }
    if (!IsSimple(GetModifierPairStatus(controlKey, rightControlKey))) {
        return false;
    }
    return true;
}

// Append to a list of comment holders

void ModifierElement::AppendToList(XMLCommentHolderList& ioList)
{
	ioList.push_back(this);
}

#pragma mark === ModifierKeyStringTable ===

ModifierKeyStringTable *ModifierKeyStringTable::sModifierKeyStringTable = NULL;

// Constructor

ModifierKeyStringTable::ModifierKeyStringTable(void)
{
}

// Destructor

ModifierKeyStringTable::~ModifierKeyStringTable(void)
{
	if (sModifierKeyStringTable == this) {
		delete [] mStringTable;
		delete [] mLeftModifierTable;
		delete [] mRightModifierTable;
		delete [] mStatusTable;
		sModifierKeyStringTable = NULL;
	}
}

#pragma mark -

// Get the singleton instance

ModifierKeyStringTable *ModifierKeyStringTable::GetInstance(void)
{
	if (sModifierKeyStringTable == NULL) {
		sModifierKeyStringTable = new ModifierKeyStringTable();
		sModifierKeyStringTable->SetupStringTable();
	}
	return sModifierKeyStringTable;
}

// Get matching keys

bool ModifierKeyStringTable::GetMatchKeys(NString inString,
										  UInt32& outLeftModifier,
										  UInt32& outRightModifier,
										  UInt32& outStatus)
{
	ModifierKeyStringTable *stringTable = GetInstance();
	return stringTable->Match(inString, outLeftModifier, outRightModifier, outStatus);
}

// Get the match as a string

NString ModifierKeyStringTable::GetKeyString(const UInt32 inLeftKey, const UInt32 inStatus)
{
	UInt32 leftIndex = 0;
	UInt32 rightIndex = 0;
	UInt32 anyIndex = 0;
	switch (inLeftKey) {
		case shiftKey:
			leftIndex = kShiftIndex;
			rightIndex = kRightShiftIndex;
			anyIndex = kAnyShiftIndex;
		break;
		
		case alphaLock:
			leftIndex = kCapsLockIndex;
			rightIndex = 0;
			anyIndex = 0;
		break;
		
		case controlKey:
			leftIndex = kControlIndex;
			rightIndex = kRightControlIndex;
			anyIndex = kAnyControlIndex;
		break;
		
		case optionKey:
			leftIndex = kOptionIndex;
			rightIndex = kRightOptionIndex;
			anyIndex = kAnyOptionIndex;
		break;
		
		case cmdKey:
			leftIndex = kCommandIndex;
			rightIndex = 0;
			anyIndex = 0;
		break;
	}
	NString result("");
	switch (inStatus) {
		case kModifierPressed:
			NN_ASSERT(rightIndex == 0);
			result = mStringTable[leftIndex];
		break;
		
		case kModifierNotPressed:
			NN_ASSERT(rightIndex == 0);
			result = "";
		break;
		
		case kModifierEither:
			NN_ASSERT(rightIndex == 0);
			result = mStringTable[leftIndex + 1];
		break;
		
		case kModifierNone:
			result = "";
		break;
		
		case kModifierLeft:
			result = mStringTable[leftIndex];
		break;
		
		case kModifierRight:
			result = mStringTable[rightIndex];
		break;
		
		case kModifierLeftRight:
			result = mStringTable[leftIndex] + " " + mStringTable[rightIndex];
		break;
		
		case kModifierLeftOpt:
			result = mStringTable[leftIndex + 1];
		break;
		
		case kModifierRightOpt:
			result = mStringTable[rightIndex + 1];
		break;
		
		case kModifierLeftOptRight:
			result = mStringTable[leftIndex + 1] + " " + mStringTable[rightIndex];
		break;
		
		case kModifierLeftRightOpt:
			result = mStringTable[leftIndex] + " " + mStringTable[rightIndex + 1];
		break;
		
		case kModifierAny:
			result = mStringTable[anyIndex];
		break;
		
		case kModifierAnyOpt:
			result = mStringTable[anyIndex + 1];
		break;
	}
	return result;
}

#pragma mark -

// Set up the string table

void ModifierKeyStringTable::SetupStringTable(void)
{
	mNumberStrings = kModifierStringCount;
	mStringTable = new NString[kModifierStringCount];
	mLeftModifierTable = new UInt32[kModifierStringCount];
	mRightModifierTable = new UInt32[kModifierStringCount];
	mStatusTable = new UInt32[kModifierStringCount];
	
	// AnyControl
	mStringTable[kAnyControlIndex] = kAnyControlKey;
	mLeftModifierTable[kAnyControlIndex] = controlKey;
	mRightModifierTable[kAnyControlIndex] = rightControlKey;
	mStatusTable[kAnyControlIndex] = kModifierPressed;
	
	// AnyControl?
	mStringTable[kAnyControlOptIndex] = kAnyControlKeyOpt;
	mLeftModifierTable[kAnyControlOptIndex] = controlKey;
	mRightModifierTable[kAnyControlOptIndex] = rightControlKey;
	mStatusTable[kAnyControlOptIndex] = kModifierEither;
	
	// AnyOption
	mStringTable[kAnyOptionIndex] = kAnyOptionKey;
	mLeftModifierTable[kAnyOptionIndex] = optionKey;
	mRightModifierTable[kAnyOptionIndex] = rightOptionKey;
	mStatusTable[kAnyOptionIndex] = kModifierPressed;
	
	// AnyOption?
	mStringTable[kAnyOptionOptIndex] = kAnyOptionKeyOpt;
	mLeftModifierTable[kAnyOptionOptIndex] = optionKey;
	mRightModifierTable[kAnyOptionOptIndex] = rightOptionKey;
	mStatusTable[kAnyOptionOptIndex] = kModifierEither;
	
	// AnyShift
	mStringTable[kAnyShiftIndex] = kAnyShiftKey;
	mLeftModifierTable[kAnyShiftIndex] = shiftKey;
	mRightModifierTable[kAnyShiftIndex] = rightShiftKey;
	mStatusTable[kAnyShiftIndex] = kModifierPressed;
	
	// AnyShift?
	mStringTable[kAnyShiftOptIndex] = kAnyShiftKeyOpt;
	mLeftModifierTable[kAnyShiftOptIndex] = shiftKey;
	mRightModifierTable[kAnyShiftOptIndex] = rightShiftKey;
	mStatusTable[kAnyShiftOptIndex] = kModifierEither;
	
	// CapsLock
	mStringTable[kCapsLockIndex] = kCapsLockKey;
	mLeftModifierTable[kCapsLockIndex] = alphaLock;
	mRightModifierTable[kCapsLockIndex] = 0;
	mStatusTable[kCapsLockIndex] = kModifierPressed;
	
	// CapsLock?
	mStringTable[kCapsLockOptIndex] = kCapsLockKeyOpt;
	mLeftModifierTable[kCapsLockOptIndex] = alphaLock;
	mRightModifierTable[kCapsLockOptIndex] = 0;
	mStatusTable[kCapsLockOptIndex] = kModifierEither;
	
	// Command
	mStringTable[kCommandIndex] = kCommandKey;
	mLeftModifierTable[kCommandIndex] = cmdKey;
	mRightModifierTable[kCommandIndex] = 0;
	mStatusTable[kCommandIndex] = kModifierPressed;
	
	// Command?
	mStringTable[kCommandOptIndex] = kCommandKeyOpt;
	mLeftModifierTable[kCommandOptIndex] = cmdKey;
	mRightModifierTable[kCommandOptIndex] = 0;
	mStatusTable[kCommandOptIndex] = kModifierEither;
	
	// Control
	mStringTable[kControlIndex] = kControlKey;
	mLeftModifierTable[kControlIndex] = controlKey;
	mRightModifierTable[kControlIndex] = 0;
	mStatusTable[kControlIndex] = kModifierPressed;
	
	// Control?
	mStringTable[kControlOptIndex] = kControlKeyOpt;
	mLeftModifierTable[kControlOptIndex] = controlKey;
	mRightModifierTable[kControlOptIndex] = 0;
	mStatusTable[kControlOptIndex] = kModifierEither;
	
	// Option
	mStringTable[kOptionIndex] = kOptionKey;
	mLeftModifierTable[kOptionIndex] = optionKey;
	mRightModifierTable[kOptionIndex] = 0;
	mStatusTable[kOptionIndex] = kModifierPressed;
	
	// Option?
	mStringTable[kOptionOptIndex] = kOptionKeyOpt;
	mLeftModifierTable[kOptionOptIndex] = optionKey;
	mRightModifierTable[kOptionOptIndex] = 0;
	mStatusTable[kOptionOptIndex] = kModifierEither;
	
	// RightControl
	mStringTable[kRightControlIndex] = kRightControlKey;
	mLeftModifierTable[kRightControlIndex] = rightControlKey;
	mRightModifierTable[kRightControlIndex] = 0;
	mStatusTable[kRightControlIndex] = kModifierPressed;
	
	// RightControl?
	mStringTable[kRightControlOptIndex] = kRightControlKeyOpt;
	mLeftModifierTable[kRightControlOptIndex] = rightControlKey;
	mRightModifierTable[kRightControlOptIndex] = 0;
	mStatusTable[kRightControlOptIndex] = kModifierEither;
	
	// RightOption
	mStringTable[kRightOptionIndex] = kRightOptionKey;
	mLeftModifierTable[kRightOptionIndex] = rightOptionKey;
	mRightModifierTable[kRightOptionIndex] = 0;
	mStatusTable[kRightOptionIndex] = kModifierPressed;
	
	// RightOption?
	mStringTable[kRightOptionOptIndex] = kRightOptionKeyOpt;
	mLeftModifierTable[kRightOptionOptIndex] = rightOptionKey;
	mRightModifierTable[kRightOptionOptIndex] = 0;
	mStatusTable[kRightOptionOptIndex] = kModifierEither;
	
	// RightShift
	mStringTable[kRightShiftIndex] = kRightShiftKey;
	mLeftModifierTable[kRightShiftIndex] = rightShiftKey;
	mRightModifierTable[kRightShiftIndex] = 0;
	mStatusTable[kRightShiftIndex] = kModifierPressed;
	
	// RightShift?
	mStringTable[kRightShiftOptIndex] = kRightShiftKeyOpt;
	mLeftModifierTable[kRightShiftOptIndex] = rightShiftKey;
	mRightModifierTable[kRightShiftOptIndex] = 0;
	mStatusTable[kRightShiftOptIndex] = kModifierEither;
	
	// Shift
	mStringTable[kShiftIndex] = kShiftKey;
	mLeftModifierTable[kShiftIndex] = shiftKey;
	mRightModifierTable[kShiftIndex] = 0;
	mStatusTable[kShiftIndex] = kModifierPressed;
	
	// Shift?
	mStringTable[kShiftOptIndex] = kShiftKeyOpt;
	mLeftModifierTable[kShiftOptIndex] = shiftKey;
	mRightModifierTable[kShiftOptIndex] = 0;
	mStatusTable[kShiftOptIndex] = kModifierEither;
}

// Find a match

bool ModifierKeyStringTable::Match(NString inString,
								   UInt32& outLeftModifier,
								   UInt32& outRightModifier,
								   UInt32& outStatus)
{
	UInt32 left = 0;
	UInt32 right = kModifierStringCount - 1;
	while (left <= right) {
		UInt32 mid = (left + right) / 2;
		NComparison compareResult = inString.Compare(mStringTable[mid]);
		if (compareResult == kNCompareEqualTo) {
			outLeftModifier = mLeftModifierTable[mid];
			outRightModifier = mRightModifierTable[mid];
			outStatus = mStatusTable[mid];
			return true;
		}
		else if (compareResult == kNCompareGreaterThan) {
			left = mid + 1;
		}
		else {
			right = mid - 1;
		}
	}
	return false;
}

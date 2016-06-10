/*
 *  KeyMapSet.mm
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "KeyMapSet.h"
#include "KeyboardDefinitions.h"
#include "XMLErrors.h"
#include "UkeleleStrings.h"
#include "NBundle.h"
#include "LayoutInfo.h"
#include "NCocoa.h"

// Key strings
const NString kKeyMapSetMissingIDAttribute = "KeyMapSetMissingIDAttribute";
const NString kKeyMapSetWrongElementType = "KeyMapSetWrongElementType";
const NString kKeyMapSetInvalidNodeType = "KeyMapSetInvalidNodeType";
const NString kKeyMapSetRepeatedKeyMap = "KeyMapSetRepeatedKeyMap";
const NString kKeyMapSetSelfReferentialBaseMap = "KeyMapSetSelfReferentialBaseMap";

// Constructor

KeyMapSet::KeyMapSet(const NString inID)
	: XMLCommentHolder(kKeyMapSetType), mID(inID), mKeyMapTable(new KeyMapElementList)
{
}

// Copy constructor
KeyMapSet::KeyMapSet(const KeyMapSet& inOriginal)
	: XMLCommentHolder(inOriginal)
{
	mID = inOriginal.mID;
	mKeyMapTable.reset(new KeyMapElementList(*inOriginal.mKeyMapTable));
}

// Destructor

KeyMapSet::~KeyMapSet(void)
{
}

#pragma mark -
#pragma mark === Operators ===

// Assignment operator

void KeyMapSet::operator=(const KeyMapSet& inOriginal)
{
	mID = inOriginal.mID;
	mKeyMapTable.reset(new KeyMapElementList(*inOriginal.mKeyMapTable));
}

// Comparison operator

bool KeyMapSet::operator<(const KeyMapSet& inCompareTo) const
{
	return mID < inCompareTo.mID;
}

#pragma mark -

// Create a basic key map set

KeyMapSet *KeyMapSet::CreateBasicKeyMapSet(NString inID, NString inBaseMapID)
{
	KeyMapSet *keyMapSet = new KeyMapSet(inID);
	for (UInt32 i = 0; i < kNumBasicModifiers; i++) {
		KeyMapElement *keyMapElement = KeyMapElement::CreateDefaultKeyMapElement(
			kStandardKeyMapEmpty, i, inBaseMapID, i);
		keyMapSet->AddKeyMap(keyMapElement);
	}
	return keyMapSet;
}

	// Create a standard key map set

KeyMapSet *KeyMapSet::CreateStandardKeyMapSet(NString inID, NString inBaseMapID, UInt32 inStandardKeyboard, UInt32 inCommandKeyboard, UInt32 inCapsLockKeyboard, ModifierMap *inModifierMap) {
	bool hasCommandKeyboard = inCommandKeyboard != inStandardKeyboard;
	bool hasCapsLockKeyboard = inCapsLockKeyboard != inStandardKeyboard;
	UInt32 numModifiers = inModifierMap->GetKeyMapSelectCount();
	KeyMapSet *keyMapSet = new KeyMapSet(inID);
	KeyMapElement *keyMapElement = NULL;
	for (UInt32 index = 0; index < numModifiers; index++) {
		KeyMapSelect *keyMapSelect = inModifierMap->GetKeyMapSelectElement(index);
		UInt32 keyMapType;
		if (keyMapSelect->RequiresModifier(optionKey) || keyMapSelect->RequiresModifier(controlKey)) {
				// This requires option or control, so we put in an empty key map
			keyMapType = kStandardLayoutEmpty;
		}
		else if (hasCapsLockKeyboard && keyMapSelect->RequiresModifier(alphaLock)) {
				// Need the caps lock keyboard
			keyMapType = inCapsLockKeyboard;
		}
		else if (hasCommandKeyboard && keyMapSelect->RequiresModifier(cmdKey)) {
				// Need the command keyboard
			keyMapType = inCommandKeyboard;
		}
		else {
				// Use the standard keyboard
			keyMapType = inStandardKeyboard;
		}
			// This needs to be more fine-grained, working out the uppercase/lowercase/caps lock
			// version and getting the right kind of keyMap
		UInt32 modifiers = 0;
		if (keyMapSelect->RequiresModifier(alphaLock) && !hasCapsLockKeyboard) {
			modifiers |= alphaLock;
		}
		if (keyMapSelect->RequiresModifier(shiftKey)) {
			modifiers |= shiftKey;
		}
		keyMapType = (UInt32)[LayoutInfo getStandardKeyMapForKeyboard:keyMapType withModifiers:modifiers];
		keyMapElement = KeyMapElement::CreateDefaultKeyMapElement(keyMapType, index, inBaseMapID, index);
		keyMapSet->AddKeyMap(keyMapElement);
	}
	return keyMapSet;
}

KeyMapSet *KeyMapSet::CreateStandardJISKeyMapSet(NString inID, NString inBaseMapID, ModifierMap *inModifierMap) {
	KeyMapSet *keyMapSet = new KeyMapSet(inID);
	UInt32 numModifiers = inModifierMap->GetKeyMapSelectCount();
	KeyMapElement *keyMapElement = NULL;
	for (UInt32 index = 0; index < numModifiers; index++) {
		keyMapElement = KeyMapElement::CreateDefaultKeyMapElement(kStandardKeyMapEmpty, index, inBaseMapID, index);
		keyMapSet->AddKeyMap(keyMapElement);
	}
	return keyMapSet;
}

// Create a key map set from an XML tree

ErrorMessage KeyMapSet::CreateFromXMLTree(const NXMLNode& inXMLTree,
										  KeyMapSet*& outElement,
										  shared_ptr<XMLCommentContainer> ioCommentContainer)
{
	NN_ASSERT(inXMLTree.IsElement(kKeyMapSetElement));
	ErrorMessage errorValue(XMLNoError, "");
	NString errorString;
	NDictionary attributesDictionary = inXMLTree.GetElementAttributes();
	if (!attributesDictionary.HasKey(kIDAttribute)) {
		errorString = NBundleString(kKeyMapSetMissingIDAttribute, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorString);
		return errorValue;
	}
	NString mapSetID = inXMLTree.GetElementAttribute(kIDAttribute);
	outElement = new KeyMapSet(mapSetID);
	XMLCommentHolder *commentHolder = outElement;
	const NXMLNodeList *childList = inXMLTree.GetChildren();
	for (NXMLNodeListConstIterator pos = childList->begin(); pos != childList->end() && errorValue == XMLNoError; ++pos) {
		const NXMLNode *childTree = *pos;
		NString errorFormat;
		switch (childTree->GetType()) {
			case kNXMLNodeElement:
				if (childTree->GetTextValue() != kKeyMapElement) {
					errorFormat = NBundleString(kKeyMapSetWrongElementType, "", kErrorTableName);
					errorString.Format(errorFormat, mapSetID, childTree->GetTextValue());
					errorValue = ErrorMessage(XMLBadElementTypeError, errorString);
					break;
				}
				KeyMapElement *keyMapElement;
				errorValue = KeyMapElement::CreateFromXMLTree(*childTree, keyMapElement, ioCommentContainer);
				if (errorValue == XMLNoError) {
					// Check for a repeated keyMap element
					if (outElement->HasKeyMapElement(keyMapElement->GetIndex())) {
						errorFormat = NBundleString(kKeyMapSetRepeatedKeyMap, "", kErrorTableName);
						errorString.Format(errorFormat, mapSetID, keyMapElement->GetIndex());
						errorValue = ErrorMessage(XMLRepeatedKeyMapError, errorString);
					}
				}
				if (errorValue == XMLNoError) {
					outElement->mKeyMapTable->AppendKeyMapElement(keyMapElement);
				}
				if (commentHolder != NULL) {
					commentHolder->RemoveDuplicateComments();
				}
				commentHolder = keyMapElement;
				ioCommentContainer->AddCommentHolder(keyMapElement);
			break;
			
			case kNXMLNodeComment: {
				XMLComment *childComment = new XMLComment(childTree->GetTextValue(), commentHolder);
				commentHolder->AddXMLComment(childComment);
			}
			break;
			
			default:
				// Wrong kind of node
				errorFormat = NBundleString(kKeyMapSetInvalidNodeType, "", kErrorTableName);
				errorString.Format(errorFormat, mapSetID);
				errorValue = ErrorMessage(XMLWrongXMLNodeTypeError, errorString);
			break;
		}
	}
	if (errorValue == XMLNoError) {
		commentHolder->RemoveDuplicateComments();
	}
	else {
		// An error in processing, so delete the partially constructed element
		delete outElement;
		outElement = NULL;
	}
	return errorValue;
}

// Create an XML tree representing the key map set element

NXMLNode *KeyMapSet::CreateXMLTree(void)
{
	NXMLNode *xmlTree = new NXMLNode(kNXMLNodeElement, kKeyMapSetElement);
	xmlTree->SetElementAttribute(kIDAttribute, mID);
	AddCommentsToXMLTree(*xmlTree);
	mKeyMapTable->AddToXMLTree(*xmlTree);
	return xmlTree;
}

NString KeyMapSet::GetDescription(void)
{
	NString descriptionString;
	descriptionString.Format("keyMapSet id=%@", mID);
	return descriptionString;
}

#pragma mark -

// Return the number of key map elements

UInt32 KeyMapSet::GetKeyMapCount(void) const
{
	return mKeyMapTable->GetKeyMapCount();
}

// Return the maximum length of any output string

UInt32 KeyMapSet::GetMaxout(void) const
{
	return mKeyMapTable->GetMaxout();
}

// Return true if any special key output is missing

bool KeyMapSet::IsMissingSpecialKeyOutput(void) const
{
	UInt32 keyMapCount = mKeyMapTable->GetKeyMapCount();
	for (UInt32 i = 0; i < keyMapCount; i++) {
		KeyMapElement *keyMapElement = mKeyMapTable->GetKeyMapElement(i);
		if (keyMapElement != NULL && keyMapElement->IsMissingSpecialKeyOutput()) {
			return true;
		}
	}
	return false;
}

// Returns a list of base maps

NStringList KeyMapSet::GetBaseMaps(void) const
{
	NStringList baseMaps;
	UInt32 keyMapCount = mKeyMapTable->GetKeyMapCount();
	for (UInt32 i = 0; i < keyMapCount; i++) {
		KeyMapElement *keyMapElement = mKeyMapTable->GetKeyMapElement(i);
		if (keyMapElement != NULL) {
			NString baseMapName = keyMapElement->GetBaseMapSet();
			if (baseMapName != "" && find(baseMaps.begin(), baseMaps.end(), baseMapName) == baseMaps.end()) {
				baseMaps.push_back(baseMapName);
			}
		}
	}
	return baseMaps;
}

// Returns true if the key maps are relative

bool KeyMapSet::IsRelative(void) const
{
	bool result = false;
	UInt32 keyMapCount = mKeyMapTable->GetKeyMapCount();
	if (keyMapCount > 0) {
		KeyMapElement *keyMapElement = mKeyMapTable->GetKeyMapElement(0);
		result = !keyMapElement->GetBaseMapSet().IsEmpty();
	}
	return result;
}

bool KeyMapSet::HasInlineAction(void) const
{
	UInt32 keyMapCount = mKeyMapTable->GetKeyMapCount();
	for (UInt32 i = 0; i < keyMapCount; i++) {
		KeyMapElement *keyMapElement = mKeyMapTable->GetKeyMapElement(i);
		if (keyMapElement != NULL && keyMapElement->HasInlineAction()) {
			return true;
		}
	}
	return false;
}

bool KeyMapSet::HasKeyMapSetGap() const {
	bool result = false;
	UInt32 keyMapCount = mKeyMapTable->GetKeyMapCount();
	for (UInt32 i = 0; i < keyMapCount; i++) {
		KeyMapElement *keyMapElement = mKeyMapTable->GetKeyMapElement(i);
			// Each key map element must have an index in the range 0..keyMapCount - 1, and be in order
		if (keyMapElement->GetIndex() != i) {
			result = true;
			break;
		}
	}
	return result;
}

#pragma mark -

// Get the key map element at the given index

KeyMapElement *KeyMapSet::GetKeyMapElement(const UInt32 inIndex) const
{
	return mKeyMapTable->GetKeyMapElement(inIndex);
}

bool KeyMapSet::HasKeyMapElement(const UInt32 inIndex) const
{
	if (inIndex < mKeyMapTable->GetKeyMapCount()) {
		return GetKeyMapElement(inIndex) != NULL;
	}
	return false;
}

// Add the key map element at the appropriate index

void KeyMapSet::AddKeyMap(KeyMapElement *inKeyMap) {
	mKeyMapTable->AddKeyMapElement(inKeyMap);
}

// Insert the key map element into the set at the given index

void KeyMapSet::InsertKeyMapAtIndex(const UInt32 inIndex, KeyMapElement *inKeyMap)
{
	mKeyMapTable->InsertKeyMapElementAtIndex(inIndex, inKeyMap);
}

// Remove the key map element at the given index

KeyMapElement *KeyMapSet::RemoveKeyMapElement(const UInt32 inIndex)
{
	return mKeyMapTable->RemoveKeyMapElement(inIndex);
}

// Reorder the key maps in the set, adjusting all references

void KeyMapSet::RenumberKeyMaps(std::vector<SInt32>& inIndexMap) {
	KeyMapElementList *newKeyMapList = new KeyMapElementList();
	UInt32 keyMapCount = GetKeyMapCount();
	for (UInt32 i = 0; i < keyMapCount; i++) {
		KeyMapElement *keyMap = GetKeyMapElement(i);
		if (keyMap != NULL) {
			KeyMapElement *newKeyMap = new KeyMapElement(*keyMap);
			SInt32 newIndex = inIndexMap[i];
			newKeyMap->SetIndex(newIndex);
			if (keyMap->GetBaseMapSet() != "") {
				newKeyMap->SetBaseIndex(inIndexMap[keyMap->GetBaseIndex()]);
			}
			newKeyMapList->AddKeyMapElement(newKeyMap);
		}
	}
	mKeyMapTable.reset(newKeyMapList);
}

#pragma mark -

// Make the key map set relative

void KeyMapSet::MakeRelative(NString inBaseMapSet)
{
	mKeyMapTable->MakeRelative(inBaseMapSet);
}

// Import a dead key from another keyboard layout

void KeyMapSet::ImportDeadKey(NString inLocalState,
							  NString inSourceState,
							  KeyMapSet *inSource,
							  shared_ptr<ActionElementSet> inLocalActionList,
							  const shared_ptr<ActionElementSet> inSourceActionList)
{
	UInt32 mapSetCount = mKeyMapTable->GetKeyMapCount();
	NN_ASSERT(inSource->GetKeyMapCount() == mapSetCount);
	for (UInt32 i = 0; i < mapSetCount; i++) {
		KeyMapElement *localElement = mKeyMapTable->GetKeyMapElement(i);
		KeyMapElement *sourceElement = inSource->GetKeyMapElement(i);
		localElement->ImportDeadKey(sourceElement, inLocalState, inSourceState, inSourceActionList, inLocalActionList);
	}
}

// Add special key output

void KeyMapSet::AddSpecialKeyOutput(void)
{
	UInt32 keyMapCount = mKeyMapTable->GetKeyMapCount();
	for (UInt32 i = 0; i < keyMapCount; i++) {
		KeyMapElement *keyMapElement = mKeyMapTable->GetKeyMapElement(i);
		if (keyMapElement != NULL) {
			keyMapElement->AddSpecialKeyOutput();
		}
	}
}

// Swap two keys in each key map element

void KeyMapSet::SwapKeys(const UInt32 inKeyCode1, const UInt32 inKeyCode2)
{
	UInt32 keyMapCount = mKeyMapTable->GetKeyMapCount();
	for (UInt32 i = 0; i < keyMapCount; i++) {
		KeyMapElement *keyMapElement = mKeyMapTable->GetKeyMapElement(i);
		if (keyMapElement != NULL) {
			keyMapElement->SwapKeyElements(inKeyCode1, inKeyCode2);
		}
	}
}

// Append to a list of comment holders

void KeyMapSet::AppendToList(XMLCommentHolderList& ioList)
{
	ioList.push_back(this);
	mKeyMapTable->AppendToList(ioList);
}

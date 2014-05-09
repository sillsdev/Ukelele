/*
 *  ModifierMap.mm
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "ModifierMap.h"
#include "UkeleleConstants.h"
#include "UkeleleStrings.h"
#include "XMLErrors.h"
#include "NBundle.h"

// Key strings
static const NString kNotKeyMapSelectError = "NotKeyMapSelectError";
static const NString kModifierMapMissingID = "ModifierMapMissingID";
static const NString kModifierMapMissingDefaultIndex = "ModifierMapMissingDefaultIndex";
static const NString kModifierMapInvalidNodeType = "ModifierMapInvalidNodeType";
static const NString kModifierMapEmpty = "ModifierMapEmpty";

// Constructor

ModifierMap::ModifierMap(const NString inID, const UInt32 inDefaultIndex)
	: XMLCommentHolder(kModifierMapType), mID(inID), mDefaultIndex(inDefaultIndex)
{
	CalculateModifierMap();
}

// Destructor

ModifierMap::~ModifierMap(void)
{
	NN_ASSERT(!mID.IsEmpty());
	if (!mKeyMapSelectList.empty()) {
		KeyMapSelectIterator pos;
		for (pos = mKeyMapSelectList.begin(); pos != mKeyMapSelectList.end(); ++pos) {
			KeyMapSelect *keyMapSelect = *pos;
			if (keyMapSelect != NULL) {
				delete keyMapSelect;
			}
		}
	}
}

#pragma mark -

// Set a new default index value

void ModifierMap::SetDefaultIndex(const UInt32 inDefaultIndex)
{
	mDefaultIndex = inDefaultIndex;
	CalculateModifierMap();
}

// Add a new keyMapSelect element

void ModifierMap::AddKeyMapSelectElement(KeyMapSelect *inKeyMapSelect, bool inCalculateMap)
{
	NN_ASSERT(inKeyMapSelect != NULL);
	SInt32 theIndex = inKeyMapSelect->GetKeyMapSelectIndex();
	if (theIndex >= static_cast<SInt32>(mKeyMapSelectList.size())) {
		mKeyMapSelectList.resize(theIndex + 1, NULL);
	}
	NN_ASSERT(mKeyMapSelectList[theIndex] == NULL);
	mKeyMapSelectList[theIndex] = inKeyMapSelect;
	if (inCalculateMap) {
		CalculateModifierMap();
	}
}

// Insert a keyMapSelect element at the given index

void ModifierMap::InsertKeyMapSelectAtIndex(KeyMapSelect *inKeyMapSelect, const SInt32 inIndex, bool inCalculateMap)
{
	mKeyMapSelectList.insert(mKeyMapSelectList.begin() + inIndex, inKeyMapSelect);
	KeyMapSelectIterator pos;
	for (pos = mKeyMapSelectList.begin() + inIndex + 1; pos != mKeyMapSelectList.end(); ++pos) {
		KeyMapSelect *keyMapSelect = *pos;
		if (keyMapSelect != NULL) {
			keyMapSelect->SetKeyMapSelectIndex(keyMapSelect->GetKeyMapSelectIndex() + 1);
		}
	}
	if (inCalculateMap) {
		CalculateModifierMap();
	}
}

// Get a keyMapSelect element

KeyMapSelect *ModifierMap::GetKeyMapSelectElement(const SInt32 inIndex)
{
	NN_ASSERT(inIndex >= 0 && inIndex < static_cast<SInt32>(mKeyMapSelectList.size()));
	KeyMapSelect *keyMapSelect = mKeyMapSelectList[inIndex];
	return keyMapSelect;
}

// Remove and return the keyMapSelect element at the given index

KeyMapSelect *ModifierMap::RemoveKeyMapSelectElement(const SInt32 inIndex)
{
	NN_ASSERT(inIndex >= 0 && inIndex < static_cast<SInt32>(mKeyMapSelectList.size()));
	KeyMapSelect *keyMapSelect = mKeyMapSelectList[inIndex];
	mKeyMapSelectList.erase(mKeyMapSelectList.begin() + inIndex);
	SInt32 numKeyMapSelects = mKeyMapSelectList.size();
	for (SInt32 i = inIndex; i < numKeyMapSelects; i++) {
		KeyMapSelect *item = mKeyMapSelectList[i];
		if (item != NULL) {
			item->SetKeyMapSelectIndex(i);
		}
	}
	CalculateModifierMap();
	return keyMapSelect;
}

// Rearrange the key map select elements

void ModifierMap::RenumberKeyMapSelects(std::vector<SInt32>& inIndexMap) {
	KeyMapSelectList newKeyMapSelectList;
	UInt32 keyMapSelectCount = mKeyMapSelectList.size();
	newKeyMapSelectList.insert(newKeyMapSelectList.begin(), keyMapSelectCount, NULL);
	for (UInt32 i = 0; i < keyMapSelectCount; i++) {
		if (mKeyMapSelectList[i] != NULL) {
				// Need to copy it to its new place
			SInt32 newIndex = inIndexMap[i];
			KeyMapSelect *newKeyMapSelect = new KeyMapSelect(*mKeyMapSelectList[i]);
			newKeyMapSelect->SetKeyMapSelectIndex(newIndex);
			newKeyMapSelectList[newIndex] = newKeyMapSelect;
		}
	}
		// Now replace the existing key map select list
	for (UInt32 j = 0; j < keyMapSelectCount; j++) {
		KeyMapSelect *keyMapSelect = mKeyMapSelectList[j];
		if (keyMapSelect != NULL) {
			delete keyMapSelect;
			NN_ASSERT_MSG(newKeyMapSelectList[j] != NULL, "Should have a non-null key map select at index %d", j);
			mKeyMapSelectList[j] = newKeyMapSelectList[j];
		}
	}
	CalculateModifierMap();
}

#pragma mark -

// Insert a modifier element at the given location

void ModifierMap::InsertModifierElementAtIndex(ModifierElement *inModifierElement,
	const SInt32 inIndex, const SInt32 inSubIndex)
{
	KeyMapSelect *keyMapSelect = GetKeyMapSelectElement(inIndex);
	keyMapSelect->InsertModifierElementAtIndex(inModifierElement, inSubIndex);
	CalculateModifierMap();
}

// Remove and return the modifier element at the given location

ModifierElement *ModifierMap::RemoveModifierElement(const SInt32 inIndex, const SInt32 inSubIndex)
{
	KeyMapSelect *keyMapSelect = GetKeyMapSelectElement(inIndex);
	ModifierElement *modifierElement = keyMapSelect->RemoveModifierElement(inSubIndex);
	CalculateModifierMap();
	return modifierElement;
}

#pragma mark -

// Get a matching keyMapSelect.

UInt32
ModifierMap::GetMatchingKeyMapSelect(const UInt32 inModifiers)
{
	// Mask out the bits that aren't handled for keys, since they are actually
	// converting one key code to a different key code.
	UInt32 currentModifiers = inModifiers & ~(kEventKeyModifierNumLockMask | kEventKeyModifierFnMask);
	UInt32 index = ModifierToIndex(currentModifiers);
	return mModifierMap[index];
}

// GetMatchingModifiers: Return a modifier combination that is in the given
// key map set

UInt32 ModifierMap::GetMatchingModifiers(const UInt32 inKeyMapSelectIndex)
{
	for (UInt32 i = 0; i < kModifierMapLength; i++) {
		if (mModifierMap[i] == inKeyMapSelectIndex) {
			return IndexToModifier(i);
		}
	}
	return IndexToModifier(0);
}

// Return true if the modifier map given is equivalent to this one, i.e. it
// has the same mappings, though it may be expressed differently

bool ModifierMap::IsEquivalent(const ModifierMap *inMap) const
{
	for (UInt32 modifierIndex = 0; modifierIndex < kModifierMapLength; modifierIndex++) {
		if (mModifierMap[modifierIndex] != inMap->mModifierMap[modifierIndex]) {
			return false;
		}
	}
	return true;
}

// Return a list of the indices that are referenced

std::vector<UInt32> ModifierMap::GetReferencedIndices(void) const
{
	std::vector<UInt32> indexRef;
	KeyMapSelectList::const_iterator pos;
	for (pos = mKeyMapSelectList.begin(); pos != mKeyMapSelectList.end(); ++pos) {
		if (*pos != NULL) {
			indexRef.push_back((*pos)->GetKeyMapSelectIndex());
		}
	}
	std::sort(indexRef.begin(), indexRef.end());
	return indexRef;
}

#pragma mark -

// Handle simplified modifier maps, that is, those that do not reference left & right modifiers separately

ModifierMap *ModifierMap::SimplifiedModifierMap(void)
{
    ModifierMap *simplifiedVersion = new ModifierMap(mID, mDefaultIndex);
    KeyMapSelectIterator pos;
    for (pos = mKeyMapSelectList.begin(); pos != mKeyMapSelectList.end(); ++pos) {
        if (*pos) {
            simplifiedVersion->mKeyMapSelectList.push_back((*pos)->SimplifiedKeyMapSelect());
        }
    }
    simplifiedVersion->CalculateModifierMap();
    return simplifiedVersion;
}

bool ModifierMap::IsSimplified(void)
{
    KeyMapSelectIterator pos;
    for (pos = mKeyMapSelectList.begin(); pos != mKeyMapSelectList.end(); ++pos) {
        if (!(*pos)->IsSimplified()) {
            return false;
        }
    }
    return true;
}

#pragma mark -

// Create a basic modifier map

ModifierMap *ModifierMap::CreateBasicModifierMap(void)
{
	ModifierMap *modifierMap = new ModifierMap(kDefaultModifiersName, kStandardDefaultIndex);
	static NString modifiersList[kNumStandardModifiers] = {
		kNoModifiers, kShiftOnly, kOptionOnly, kCapsLockOnly, kShiftOption
	};
	for (UInt32 i = 0; i < kNumStandardModifiers; i++) {
		KeyMapSelect *keyMapSelect = KeyMapSelect::CreateBasicKeyMapSelect(i, modifiersList[i]);
		modifierMap->AddKeyMapSelectElement(keyMapSelect, false);
	}
	modifierMap->CalculateModifierMap();
	return modifierMap;
}

// Create a modifier map from an XML tree

ErrorMessage ModifierMap::CreateFromXMLTree(const NXMLNode& inXMLTree,
											ModifierMap*& outElement,
											shared_ptr<XMLCommentContainer> ioCommentContainer)
{
	ErrorMessage errorValue(XMLNoError, "");
	NString errorString;
	NString errorFormat;
	NN_ASSERT(inXMLTree.IsElement(kModifierMapElement));
	NDictionary attributeDictionary = inXMLTree.GetElementAttributes();
	if (!attributeDictionary.HasKey(kIDAttribute)) {
			// No id attribute
		errorString = NBundleString(kModifierMapMissingID, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorString);
		return errorValue;
	}
	NString idAttribute = inXMLTree.GetElementAttribute(kIDAttribute);
	if (!attributeDictionary.HasKey(kDefaultIndexAttribute)) {
			// No defaultIndex attribute
		errorFormat = NBundleString(kModifierMapMissingDefaultIndex, "", kErrorTableName);
		errorString.Format(errorFormat, idAttribute);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorString);
		return errorValue;
	}
	NString defaultIndexString = inXMLTree.GetElementAttribute(kDefaultIndexAttribute);
	NNumber defaultIndexNumber(defaultIndexString);
	UInt32 defaultIndex = defaultIndexNumber.GetUInt32();
	outElement = new ModifierMap(idAttribute, defaultIndex);
	const NXMLNodeList *childList = inXMLTree.GetChildren();
	if (childList->size() == 0) {
		// Empty modifier map
		errorFormat = NBundleString(kModifierMapEmpty, "", kErrorTableName);
		errorString.Format(errorFormat, idAttribute);
		errorValue = ErrorMessage(XMLEmptyModifierMapError, errorString);
	}
	NString childValue;
	XMLCommentHolder *commentHolder = outElement;
	for (NXMLNodeListConstIterator pos = childList->begin(); pos != childList->end() && errorValue == XMLNoError; ++pos) {
		const NXMLNode *childTree = *pos;
		switch (childTree->GetType()) {
			case kNXMLNodeElement:
				// An element, which should be a keyMapSelect
				childValue = childTree->GetTextValue();
				if (childValue != kKeyMapSelectElement) {
					NString errorFormat = NBundleString(kNotKeyMapSelectError, "", kErrorTableName);
					errorString.Format(errorFormat, childValue);
					errorValue = ErrorMessage(XMLBadElementTypeError, errorString);
					break;
				}
				KeyMapSelect *keyMapSelect;
				errorValue = KeyMapSelect::CreateFromXMLTree(*childTree, keyMapSelect, ioCommentContainer);
				if (errorValue == XMLNoError) {
					// Got a valid keyMapSelect
					outElement->AddKeyMapSelectElement(keyMapSelect, false);
					if (commentHolder != NULL) {
						commentHolder->RemoveDuplicateComments();
					}
					commentHolder = keyMapSelect;
					ioCommentContainer->AddCommentHolder(keyMapSelect);
				}
			break;
			
			case kNXMLNodeComment: {
				// A comment
				childValue = childTree->GetTextValue();
				XMLComment *childComment = new XMLComment(childValue, commentHolder);
				commentHolder->AddXMLComment(childComment);
			}
			break;
			
			default:
				// Invalid node type
				errorFormat = NBundleString(kModifierMapInvalidNodeType, "", kErrorTableName);
				errorString.Format(errorFormat, idAttribute);
				errorValue = ErrorMessage(XMLWrongXMLNodeTypeError, errorString);
			break;
		}
	}
	if (errorValue == XMLNoError) {
		// Recalculate the modifier map, now that we have some real data for it
		outElement->CalculateModifierMap();
		commentHolder->RemoveDuplicateComments();
	}
	else {
		// An error in processing, so delete the partially constructed element
		delete outElement;
		outElement = NULL;
	}
	return errorValue;
}

// Create an XML tree

NXMLNode *ModifierMap::CreateXMLTree(void)
{
	NXMLNode *xmlTree = new NXMLNode(kNXMLNodeElement, kModifierMapElement);
	xmlTree->SetElementAttribute(kIDAttribute, mID);
	NString defaultIndexString;
	defaultIndexString.Format("%d", mDefaultIndex);
	xmlTree->SetElementAttribute(kDefaultIndexAttribute, defaultIndexString);
	AddCommentsToXMLTree(*xmlTree);
	if (!mKeyMapSelectList.empty()) {
		KeyMapSelectIterator pos;
		for (pos = mKeyMapSelectList.begin(); pos != mKeyMapSelectList.end(); ++pos) {
			KeyMapSelect *keyMapSelect = *pos;
			if (keyMapSelect != NULL) {
				NXMLNode *keyMapSelectTree = keyMapSelect->CreateXMLTree();
				xmlTree->AddChild(keyMapSelectTree);
			}
		}
	}
	return xmlTree;
}

NString ModifierMap::GetDescription(void)
{
	NString descriptionString;
	descriptionString.Format("modifierMap id=%@, default index=%d", mID, mDefaultIndex);
	return descriptionString;
}

// Append to a list of comment holders

void ModifierMap::AppendToList(XMLCommentHolderList& ioList)
{
	ioList.push_back(this);
	KeyMapSelectIterator pos;
	for (pos = mKeyMapSelectList.begin(); pos != mKeyMapSelectList.end(); ++pos) {
		if (*pos != NULL) {
			(*pos)->AppendToList(ioList);
		}
	}
}

#pragma mark -

// Calculate the current modifier map for fast access later

void ModifierMap::CalculateModifierMap(void)
{
	for (UInt32 modifierIndex = 0; modifierIndex < kModifierMapLength; modifierIndex++) {
		UInt32 modifier = IndexToModifier(modifierIndex);
		mModifierMap[modifierIndex] = ModifierToTable(modifier);
	}
}

// Map from an index to the modifier

UInt32 ModifierMap::IndexToModifier(const UInt32 inIndex)
{
	UInt32 modifier = inIndex << kModifierMapShift;
	return modifier;
}

// Map from a modifier to an index

UInt32 ModifierMap::ModifierToIndex(const UInt32 inModifier)
{
	NN_ASSERT(inModifier >> kEventKeyModifierNumLockBit == 0);
	UInt32 index = inModifier >> kModifierMapShift;
	return index;
}

// Map from a modifier into the table. This performs the lookup by searching through
// the key map select elements. Note that we have to go through each element in turn
// to ensure that the last matching element is caught, which is the specification of
// the key map select element.

UInt32 ModifierMap::ModifierToTable(const UInt32 inModifier)
{
	SInt32 numKeyMapSelects = mKeyMapSelectList.size();
	UInt32 theTable = mDefaultIndex;
	for (SInt32 index = numKeyMapSelects - 1; index >= 0; index--) {
		KeyMapSelect *keyMapSelect = mKeyMapSelectList[index];
		if (keyMapSelect != NULL && keyMapSelect->ModifierMatches(inModifier)) {
			theTable = index;
			break;
		}
	}
	return theTable;
}

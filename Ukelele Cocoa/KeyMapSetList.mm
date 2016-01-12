/*
 *  KeyMapSetList.mm
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "KeyMapSetList.h"

// Constructor

KeyMapSetList::KeyMapSetList(void)
{
}

// Copy constructor

KeyMapSetList::KeyMapSetList(const KeyMapSetList& inOriginal)
{
	if (!inOriginal.mList.empty()) {
		for (KeyMapSetConstIterator pos = inOriginal.mList.begin(); pos != inOriginal.mList.end(); ++pos) {
			KeyMapSet *keyMapSet = new KeyMapSet(**pos);
			mList.push_back(keyMapSet);
		}
		std::sort(mList.begin(), mList.end(), DereferenceLess());
	}
}

// Destructor

KeyMapSetList::~KeyMapSetList(void)
{
	if (!mList.empty()) {
		for (KeyMapSetIterator pos = mList.begin(); pos != mList.end(); ++pos) {
			KeyMapSet *keyMapSet = *pos;
			delete keyMapSet;
		}
	}
}

#pragma mark -

// Get the maximum length of an output string

UInt32 KeyMapSetList::GetMaxout(void) const
{
	UInt32 maxout = 0;
	for (KeyMapSetConstIterator pos = mList.begin(); pos != mList.end(); ++pos) {
		KeyMapSet *keyMapSet = *pos;
		UInt32 keyMapSetMaxout = keyMapSet->GetMaxout();
		if (keyMapSetMaxout > maxout) {
			maxout = keyMapSetMaxout;
		}
	}
	return maxout;
}

// Return true if any of the special key output is missing

bool KeyMapSetList::IsMissingSpecialKeyOutput(void) const
{
	for (KeyMapSetConstIterator pos = mList.begin(); pos != mList.end(); ++pos) {
		KeyMapSet *keyMapSet = *pos;
		if (keyMapSet->IsMissingSpecialKeyOutput()) {
			return true;
		}
	}
	return false;
}

NStringList KeyMapSetList::GetKeyMapSets(void) const
{
	NStringList keyMapSets;
	for (KeyMapSetConstIterator pos = mList.begin(); pos != mList.end(); ++pos) {
		KeyMapSet *keyMapSet = *pos;
		NStringList baseMaps = keyMapSet->GetBaseMaps();
		keyMapSets.insert(keyMapSets.end(), baseMaps.begin(), baseMaps.end());
	}
	return keyMapSets;
}

bool KeyMapSetList::HasInlineAction(void) const
{
	for (KeyMapSetConstIterator pos = mList.begin(); pos != mList.end(); ++pos) {
		KeyMapSet *keyMapSet = *pos;
		if (keyMapSet->HasInlineAction()) {
			return true;
		}
	}
	return false;
}

bool KeyMapSetList::HasKeyMapSetGap(void) const {
	bool result = false;
	for (KeyMapSetConstIterator pos = mList.begin(); pos != mList.end(); ++pos) {
		KeyMapSet *keyMapSet = *pos;
		if (keyMapSet->HasKeyMapSetGap()) {
			result = true;
			break;
		}
	}
	return result;
}

bool KeyMapSetList::HasInvalidBaseIndex(void) const {
	bool result = false;
	for (KeyMapSetConstIterator pos = mList.begin(); pos != mList.end(); ++pos) {
		KeyMapSet *keyMapSet = *pos;
		UInt32 keyMapSetSize = keyMapSet->GetKeyMapSize();
		for (UInt32 i = 0; i < keyMapSetSize && !result; i++) {
			KeyMapElement *keyMap = keyMapSet->GetKeyMapElement(i);
			if (keyMap->GetBaseMapSet() != "") {
					// Have a base map
				KeyMapSet *baseMap = FindKeyMapSet(keyMap->GetBaseMapSet());
				if (baseMap == NULL) {
						// Reference to non-existent base map
					result = true;
					break;
				}
				if (baseMap->GetKeyMapElement(keyMap->GetBaseIndex()) == NULL) {
						// Bad index
					result = true;
					break;
				}
			}
		}
	}
	return result;
}

bool KeyMapSetList::HasExtraKeyMap(UInt32 inKeyMapSelectCount) const {
	bool result = false;
	for (KeyMapSetConstIterator pos = mList.begin(); pos != mList.end(); ++pos) {
		KeyMapSet *keyMapSet = *pos;
		if (keyMapSet->GetKeyMapCount() > inKeyMapSelectCount) {
			result = true;
			break;
		}
	}
	return result;
}

#pragma mark -

// Add a key map set to the list

void KeyMapSetList::AddKeyMapSet(KeyMapSet *inKeyMapSet)
{
	NN_ASSERT(inKeyMapSet != NULL);
	mList.push_back(inKeyMapSet);
}

// After adding all the key map sets, sort the list

void KeyMapSetList::CompleteSet(void)
{
	std::sort(mList.begin(), mList.end(), DereferenceLess());
}

// Get a key map set at the given index

KeyMapSet *KeyMapSetList::GetKeyMapSet(const UInt32 inIndex) const
{
	NN_ASSERT(inIndex > 0 && inIndex <= mList.size());
	return mList[inIndex - 1];
}

// Get a key map set with the given ID

KeyMapSet *KeyMapSetList::FindKeyMapSet(NString inID) const
{
	KeyMapSet *keyMapSet = NULL;
	SInt32 left = 0;
	SInt32 right = static_cast<SInt32>(mList.size() - 1);
	while (left <= right) {
		SInt32 current = (left + right) / 2;
		keyMapSet = mList[current];
		NComparison comparison = keyMapSet->GetID().Compare(inID);
		if (comparison == kNCompareEqualTo) {
			return keyMapSet;
		}
		else if (comparison == kNCompareLessThan) {
			left = current + 1;
		}
		else {
			right = current - 1;
		}
	}
	return NULL;
}

// Remove all the key map sets without deleting them

void KeyMapSetList::Clear(void)
{
	mList.clear();
}

// Import a dead key from another keyboard layout

void KeyMapSetList::ImportDeadKey(KeyMapSetList *inSource,
								  const NString inLocalState,
								  const NString inSourceState,
								  shared_ptr<ActionElementSet> inLocalActionList,
								  const shared_ptr<ActionElementSet> inSourceActionList)
{
	KeyMapSetIterator localPos;
	KeyMapSetIterator sourcePos = inSource->mList.begin();
	for (localPos = mList.begin(); localPos != mList.end() && sourcePos != inSource->mList.end(); ++localPos, ++sourcePos) {
		KeyMapSet *localKeyMapSet = *localPos;
		KeyMapSet *sourceKeyMapSet = *sourcePos;
		localKeyMapSet->ImportDeadKey(inLocalState, inSourceState, sourceKeyMapSet,
			inLocalActionList, inSourceActionList);
	}
}

#pragma mark -

// Get all the state names referenced by the key map sets

void KeyMapSetList::GetStateNames(NSMutableSet *ioStateNames, const UInt32 inReachable) const
{
	for (KeyMapSetConstIterator pos = mList.begin(); pos != mList.end(); ++pos) {
		KeyMapSet *keyMapSet = *pos;
		keyMapSet->GetStateNames(ioStateNames, inReachable);
	}
}

// Replace all instances of a state name with a new name

void KeyMapSetList::ReplaceStateName(const NString inOldName, const NString inNewName)
{
	for (KeyMapSetIterator pos = mList.begin(); pos != mList.end(); ++pos) {
		KeyMapSet *keyMapSet = *pos;
		keyMapSet->ReplaceStateName(inOldName, inNewName);
	}
}

// Remove all references to the states in the given set

void KeyMapSetList::RemoveStates(NSSet *inStates)
{
	for (KeyMapSetIterator pos = mList.begin(); pos != mList.end(); ++pos) {
		KeyMapSet *keyMapSet = *pos;
		keyMapSet->RemoveStates(inStates);
	}
}

// Change an action name

void KeyMapSetList::ChangeActionName(const NString inOldName, const NString inNewName)
{
	for (KeyMapSetIterator pos = mList.begin(); pos != mList.end(); ++pos) {
		KeyMapSet *keyMapSet = *pos;
		keyMapSet->ChangeActionName(inOldName, inNewName);
	}
}

// Get the actions that are used

NSSet *KeyMapSetList::GetUsedActions(void) const
{
	NSMutableSet *usedActions = [NSMutableSet setWithCapacity:mList.size()];
	for (KeyMapSetConstIterator pos = mList.begin(); pos != mList.end(); ++pos) {
		KeyMapSet *keyMapSet = *pos;
		keyMapSet->GetUsedActions(usedActions);
	}
	return usedActions;
}

#pragma mark -

// Add special key output that is missing

void KeyMapSetList::AddSpecialKeyOutput(void)
{
	for (KeyMapSetIterator pos = mList.begin(); pos != mList.end(); ++pos) {
		KeyMapSet *keyMapSet = *pos;
		keyMapSet->AddSpecialKeyOutput();
	}
}

// Append to a list of comment holders

void KeyMapSetList::AppendToList(XMLCommentHolderList& ioList)
{
	for (KeyMapSetIterator pos = mList.begin(); pos != mList.end(); ++pos) {
		(*pos)->AppendToList(ioList);
	}
}

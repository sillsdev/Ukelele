/*
 *  KeyElementTable.mm
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "KeyElementTable.h"
#include "UkeleleConstants.h"
#include "NCocoa.h"

// Constructor

KeyElementTable::KeyElementTable(const UInt32 inTableSize)
{
	mTableSize = inTableSize == 0 ? kDefaultKeyElementTableSize : inTableSize;
	mElementTable = KeyElementList(mTableSize, NULL);
}

// Copy constructor

KeyElementTable::KeyElementTable(const KeyElementTable& inOriginal)
{
	mTableSize = inOriginal.mTableSize;
	mElementTable = KeyElementList(mTableSize, NULL);
	for (UInt32 i = 0; i < mTableSize; i++) {
		KeyElement *keyElement = inOriginal.mElementTable[i];
		if (keyElement != NULL) {
			mElementTable[i] = new KeyElement(*keyElement);
		}
	}
}

// Destructor

KeyElementTable::~KeyElementTable(void)
{
	for (UInt32 i = 0; i < mTableSize; i++) {
		KeyElement *keyElement = mElementTable[i];
		if (keyElement != NULL) {
			delete keyElement;
		}
	}
}

#pragma mark -

// Is the table empty?

bool KeyElementTable::IsEmpty(void) const
{
	for (UInt32 i = 0; i < mTableSize; i++) {
		if (mElementTable[i] != NULL) {
			return false;
		}
	}
	return true;
}

// Get the maximum length of any output string

UInt32 KeyElementTable::GetMaxout(void) const
{
	UInt32 maxout = 0;
	for (UInt32 i = 0; i < mTableSize; i++) {
		KeyElement *keyElement = mElementTable[i];
		if (keyElement != NULL) {
			UInt32 keyElementMaxout = keyElement->GetMaxout();
			if (keyElementMaxout > maxout) {
				maxout = keyElementMaxout;
			}
		}
	}
	return maxout;
}

// Get the actions that are being used

void KeyElementTable::GetUsedActions(NSMutableSet *ioActionSet) const
{
	for (UInt32 i = 0; i < mTableSize; i++) {
		KeyElement *keyElement = mElementTable[i];
		if (keyElement != NULL) {
			NString actionName = keyElement->GetActionName();
			if (!actionName.IsEmpty()) {
				[ioActionSet addObject:ToNS(actionName)];
			}
		}
	}
}

bool KeyElementTable::HasInlineAction(void) const
{
	for (UInt32 i = 0; i < mTableSize; i++) {
		KeyElement *keyElement = mElementTable[i];
		if (keyElement != NULL && keyElement->HasInlineAction()) {
			return true;
		}
	}
	return false;
}

#pragma mark -

// Add a key element to the table at the given index

void KeyElementTable::AddKeyElement(const UInt32 inIndex, KeyElement *inKeyElement)
{
	UInt32 elementCount = static_cast<UInt32>(mElementTable.size());
	if (inIndex < elementCount) {
		// We're inserting into the table, where the original element, if any,
		// should be deleted before the new element is assigned
		KeyElement *oldElement = mElementTable[inIndex];
		if (oldElement != NULL && oldElement != inKeyElement) {
			delete oldElement;
		}
	}
	else {
		// We're putting the new element beyond the end of the table, so we
		// add as many NULL elements as needed and then adjust the mTableSize
		// member
		if (inIndex >= mTableSize) {
			mElementTable.resize(inIndex + 1, NULL);
			mTableSize = inIndex + 1;
		}
	}
	mElementTable[inIndex] = inKeyElement;
}

// Get the key element at the given index

KeyElement *KeyElementTable::GetKeyElement(const UInt32 inIndex)
{
	if (inIndex == kNoKeyCode) {
		return NULL;
	}
	if (inIndex >= mTableSize) {
		mElementTable.resize(inIndex + 1, NULL);
		mTableSize = inIndex + 1;
	}
	return mElementTable[inIndex];
}

// Remove a key element from the given index

void KeyElementTable::RemoveKeyElement(const UInt32 inIndex)
{
	NN_ASSERT(inIndex < mTableSize);
	NN_ASSERT(inIndex < mElementTable.size());
	KeyElement *keyElement = mElementTable[inIndex];
	delete keyElement;
	keyElement = NULL;
	mElementTable[inIndex] = NULL;
}

// Swap two key elements

void KeyElementTable::SwapKeyElements(const UInt32 inKeyCode1, const UInt32 inKeyCode2)
{
	KeyElement *keyElement1 = GetKeyElement(inKeyCode1);
	KeyElement *keyElement2 = GetKeyElement(inKeyCode2);
	if (keyElement1 != NULL) {
		// Set the key code to inKeyCode2
		keyElement1->ChangeKeyCode(inKeyCode2);
	}
	if (keyElement2 != NULL) {
		// Set the key code to inKeyCode1
		keyElement2->ChangeKeyCode(inKeyCode1);
	}
	// Swap the table entries
	mElementTable[inKeyCode1] = keyElement2;
	mElementTable[inKeyCode2] = keyElement1;
}

// Append to a list of comment holders

void KeyElementTable::AppendToList(XMLCommentHolderList& ioList)
{
	for (UInt32 i = 0; i < mTableSize; i++) {
		if (mElementTable[i] != NULL) {
			mElementTable[i]->AppendToList(ioList);
		}
	}
}

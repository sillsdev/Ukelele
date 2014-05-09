/*
 *  ModifierList.mm
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "ModifierList.h"

// Constructor

ModifierList::ModifierList(void)
{
}

// Copy constructor

ModifierList::ModifierList(const ModifierList& inOriginal)
{
	if (!inOriginal.mModifierElementList.empty()) {
		ModifierElementIterator pos;
		ModifierElementIterator startPos = const_cast<ModifierElementList *>(
			&inOriginal.mModifierElementList)->begin();
		ModifierElementIterator endPos = const_cast<ModifierElementList *>(
			&inOriginal.mModifierElementList)->end();
		for (pos = startPos; pos != endPos; ++pos) {
			mModifierElementList.push_back(new ModifierElement(**pos));
		}
	}
}

// Destructor

ModifierList::~ModifierList(void)
{
	if (!mModifierElementList.empty()) {
		ModifierElementIterator pos;
		for (pos = mModifierElementList.begin(); pos != mModifierElementList.end(); ++pos) {
			ModifierElement *element = *pos;
			delete element;
		}
	}
}

#pragma mark -

// Add a modifier element

void ModifierList::AddModifierElement(ModifierElement *inModifier)
{
	NN_ASSERT(inModifier != NULL);
	mModifierElementList.push_back(inModifier);
}

// Insert a modifier element at the given index

void ModifierList::InsertModifierElement(ModifierElement *inModifier, const SInt32 inIndex)
{
	NN_ASSERT(inIndex > 0 && inIndex <= static_cast<SInt32>(mModifierElementList.size()));
	NN_ASSERT(inModifier != NULL);
	mModifierElementList.insert(mModifierElementList.begin() + inIndex - 1, inModifier);
}

// Get the element at a specified index

ModifierElement *ModifierList::GetModifierElement(const SInt32 inIndex) const
{
	NN_ASSERT(inIndex > 0 && inIndex <= static_cast<SInt32>(mModifierElementList.size()));
	ModifierElement *modifierElement = mModifierElementList[inIndex - 1];
	return modifierElement;
}

// Remove the element at the specified index, returning the element

ModifierElement *ModifierList::RemoveModifierElement(const SInt32 inIndex)
{
	NN_ASSERT(inIndex > 0 && inIndex <= static_cast<SInt32>(mModifierElementList.size()));
	ModifierElementIterator pos = mModifierElementList.begin() + inIndex - 1;
	ModifierElement *modifierElement = *pos;
	NN_ASSERT(modifierElement != NULL);
	mModifierElementList.erase(pos);
	return modifierElement;
}

ModifierList *ModifierList::SimplifiedModifierList(void)
{
    ModifierList *simplifiedList = new ModifierList;
    ModifierElementIterator pos;
    for (pos = mModifierElementList.begin(); pos != mModifierElementList.end(); ++pos) {
        ModifierElement *element = (*pos)->SimplifiedModifierElement();
        simplifiedList->AddModifierElement(element);
    }
    return simplifiedList;
}

bool ModifierList::IsSimplified(void)
{
    ModifierElementIterator pos;
    for (pos = mModifierElementList.begin(); pos != mModifierElementList.end(); ++pos) {
        if (!(*pos)->IsSimplified()) {
            return false;
        }
    }
    return true;
}

// Append to a list of comment holders

void ModifierList::AppendToList(XMLCommentHolderList& ioList)
{
	ModifierElementIterator pos;
	for (pos = mModifierElementList.begin(); pos != mModifierElementList.end(); ++pos) {
		(*pos)->AppendToList(ioList);
	}
}

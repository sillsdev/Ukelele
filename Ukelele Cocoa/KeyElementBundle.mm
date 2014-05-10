/*
 *  KeyElementBundle.cpp
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "KeyElementBundle.h"


// Constructor

KeyElementBundle::KeyElementBundle(void)
{
}

// Copy constructor

KeyElementBundle::KeyElementBundle(const KeyElementBundle& inOriginal)
{
	KeyElementListConstIterator keyMapSetIter;
	for (keyMapSetIter = inOriginal.mBundle.begin(); keyMapSetIter != inOriginal.mBundle.end(); ++keyMapSetIter) {
		KeyElementList *keyMapElement = new KeyElementList;
		mBundle.push_back(keyMapElement);
		KeyElementConstIterator keyMapIter;
		for (keyMapIter = (**keyMapSetIter).begin(); keyMapIter != (**keyMapSetIter).end(); ++keyMapIter) {
			KeyElement *keyElement = *keyMapIter;
			if (keyElement != NULL) {
				keyMapElement->push_back(new KeyElement(*keyElement));
			}
			else {
				keyMapElement->push_back(NULL);
			}
		}
	}
}

// Destructor

KeyElementBundle::~KeyElementBundle(void)
{
	KeyElementListIterator keyMapSetIter;
	for (keyMapSetIter = mBundle.begin(); keyMapSetIter != mBundle.end(); ++keyMapSetIter) {
		KeyElementIterator keyMapIter;
		for (keyMapIter = (**keyMapSetIter).begin(); keyMapIter !=  (**keyMapSetIter).end(); ++keyMapIter) {
			if (*keyMapIter != NULL) {
				delete *keyMapIter;
			}
		}
	}
}

#pragma mark -

// Add a key element to the bundle at the given indices

void KeyElementBundle::AddKeyElement(const UInt32 inKeyMapSetIndex,
									 const UInt32 inKeyMapIndex,
									 const KeyElement *inKeyElement)
{
	if (inKeyMapSetIndex >= mBundle.size()) {
		for (UInt32 i = static_cast<UInt32>(mBundle.size()); i <= inKeyMapSetIndex; i++) {
			mBundle.push_back(new KeyElementList);
		}
	}
	KeyElementList *bundleElement = mBundle[inKeyMapSetIndex];
	if (inKeyMapIndex < bundleElement->size()) {
		KeyElement *oldElement = (*bundleElement)[inKeyMapIndex];
		(*bundleElement)[inKeyMapIndex] = new KeyElement(*inKeyElement);
		if (oldElement != NULL && oldElement != inKeyElement) {
			delete oldElement;
		}
	}
	else {
		KeyElement *newElement = inKeyElement != NULL ? new KeyElement(*inKeyElement) : NULL;
		bundleElement->push_back(newElement);
	}
}

// Get the key element at the given indices

KeyElement *KeyElementBundle::GetKeyElement(const UInt32 inKeyMapSetIndex, const UInt32 inKeyMapIndex) const
{
	KeyElement *result = NULL;
	if (inKeyMapSetIndex < mBundle.size()) {
		KeyElementList *bundleElement = mBundle[inKeyMapSetIndex];
		if (inKeyMapIndex < bundleElement->size()) {
			result = (*bundleElement)[inKeyMapIndex];
		}
	}
	return result;
}

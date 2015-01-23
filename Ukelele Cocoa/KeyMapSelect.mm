/*
 *  KeyMapSelect.mm
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "KeyMapSelect.h"
#include "UkeleleConstants.h"
#include "UkeleleStrings.h"
#include "XMLErrors.h"
#include "NBundle.h"

// Key strings
const NString kKeyMapSelectMissingMapIndexAttribute = "KeyMapSelectMissingMapIndexAttribute";
const NString kKeyMapSelectWrongElementType = "KeyMapSelectWrongElementType";
const NString kKeyMapSelectInvalidNodeType = "KeyMapSelectInvalidNodeType";
const NString kKeyMapSelectEmpty = "KeyMapSelectEmpty";

// Constructor

KeyMapSelect::KeyMapSelect(const UInt32 inTableNumber)
	: XMLCommentHolder(kKeyMapSelectType), mMapIndexNumber(inTableNumber), mModifierList(new ModifierList)
{
}

// Copy constructor

KeyMapSelect::KeyMapSelect(const KeyMapSelect& inOriginal)
	: XMLCommentHolder(inOriginal)
{
	mMapIndexNumber = inOriginal.mMapIndexNumber;
	mModifierList.reset(new ModifierList(*inOriginal.mModifierList));
}

// Destructor

KeyMapSelect::~KeyMapSelect(void)
{
}

#pragma mark -

// Add a modifier element

void KeyMapSelect::AddModifierElement(ModifierElement *inModifierElement)
{
	NN_ASSERT(inModifierElement != NULL);
	mModifierList->AddModifierElement(inModifierElement);
}

// Insert a modifier element at the given index

void KeyMapSelect::InsertModifierElementAtIndex(ModifierElement *inModifierElement, const SInt32 inIndex)
{
	NN_ASSERT(inModifierElement != NULL);
	mModifierList->InsertModifierElement(inModifierElement, inIndex);
}

// Get the modifier element at the given index

ModifierElement *KeyMapSelect::GetModifierElement(const SInt32 inIndex) const
{
	NN_ASSERT(inIndex > 0 && inIndex <= (SInt32) mModifierList->GetElementCount());
	return mModifierList->GetModifierElement(inIndex);
}

// Remove and return the modifier element at the given index

ModifierElement *KeyMapSelect::RemoveModifierElement(const SInt32 inIndex)
{
	NN_ASSERT(inIndex > 0 && inIndex <= (SInt32) mModifierList->GetElementCount());
	return mModifierList->RemoveModifierElement(inIndex);
}

// Return true if the given modifier combination matches the keyMapSelect

bool KeyMapSelect::ModifierMatches(const UInt32 inModifierCombination) const
{
	SInt32 numModifiers = mModifierList->GetElementCount();
	for (SInt32 i = 1; i <= numModifiers; i++) {
		ModifierElement *modifierElement = mModifierList->GetModifierElement(i);
		if (modifierElement->ModifierMatches(inModifierCombination)) {
			return true;
		}
	}
	return false;
}

bool KeyMapSelect::RequiresModifier(const UInt32 inModifier) const {
	SInt32 numModifiers = mModifierList->GetElementCount();
	for (SInt32 i = 1; i <= numModifiers; i++) {
		ModifierElement *modifierElement = mModifierList->GetModifierElement(i);
		UInt32 status = modifierElement->GetModifierStatus(inModifier);
		if (status == kModifierPressed || status == kModifierEither) {
			return true;
		}
	}
	return false;
}

#pragma mark -

// Create a basic keyMapSelect element

KeyMapSelect *KeyMapSelect::CreateBasicKeyMapSelect(const UInt32 inID, const NString inModifiers)
{
	KeyMapSelect *keyMapSelect = new KeyMapSelect(inID);
	ModifierElement *modifierElement = new ModifierElement;
	modifierElement->AddModifierKeyList(inModifiers);
	keyMapSelect->AddModifierElement(modifierElement);
	return keyMapSelect;
}

// Deal with simplifying keyMapSelects and whether they are simplified already

KeyMapSelect *KeyMapSelect::SimplifiedKeyMapSelect(void)
{
    KeyMapSelect *simplifiedVersion = new KeyMapSelect(mMapIndexNumber);
    simplifiedVersion->mModifierList.reset(mModifierList->SimplifiedModifierList());
    return simplifiedVersion;
}

bool KeyMapSelect::IsSimplified(void)
{
    return mModifierList->IsSimplified();
}

#pragma mark -

// Create a keyMapSelect from an XML tree

ErrorMessage KeyMapSelect::CreateFromXMLTree(const NXMLNode& inXMLTree,
											 KeyMapSelect*& outElement,
											 shared_ptr<XMLCommentContainer> ioCommentContainer)
{
	ErrorMessage errorValue(XMLNoError, "");
	NString errorString;
	NString errorFormat;
	NN_ASSERT(inXMLTree.IsElement(kKeyMapSelectElement));
	NDictionary attributeDictionary = inXMLTree.GetElementAttributes();
	if (!attributeDictionary.HasKey(kMapIndexAttribute)) {
		// No mapIndex attribute
		errorString = NBundleString(kKeyMapSelectMissingMapIndexAttribute, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorString);
		return errorValue;
	}
	NString attributeString = inXMLTree.GetElementAttribute(kMapIndexAttribute);
	NNumber attributeNumber(attributeString);
	UInt32 mapIndex = attributeNumber.GetUInt32();
	outElement = new KeyMapSelect(mapIndex);
	const NXMLNodeList *childList = inXMLTree.GetChildren();
	if (childList->size() == 0) {
		// Empty keyMapSelect element
		errorFormat = NBundleString(kKeyMapSelectEmpty, "", kErrorTableName);
		errorString.Format(errorFormat, mapIndex);
		errorValue = ErrorMessage(XMLEmptyKeyMapSelectError, errorString);
	}
	NString childValue;
	XMLCommentHolder *commentHolder = outElement;
	for (NXMLNodeListConstIterator pos = childList->begin(); pos != childList->end() && errorValue == XMLNoError; ++pos) {
		const NXMLNode *childTree = *pos;
		switch (childTree->GetType()) {
			case kNXMLNodeElement:
				// An element, which should be a modifier element
				childValue = childTree->GetTextValue();
				if (childValue != kModifierElement) {
					// Not a modifier element
					errorFormat = NBundleString(kKeyMapSelectWrongElementType, "", kErrorTableName);
					errorString.Format(errorFormat, attributeString, childValue);
					errorValue = ErrorMessage(XMLBadElementTypeError, errorString);
					break;
				}
				ModifierElement *modifierElement;
				errorValue = ModifierElement::CreateFromXMLTree(*childTree, modifierElement);
				if (errorValue == XMLNoError) {
					// Got a valid modifier element
					outElement->AddModifierElement(modifierElement);
					// Deal with comments
					if (commentHolder != NULL) {
						commentHolder->RemoveDuplicateComments();
					}
					commentHolder = modifierElement;
					ioCommentContainer->AddCommentHolder(modifierElement);
				}
			break;
			
			case kNXMLNodeComment: {
				// A comment, so add it to the structure
				childValue = childTree->GetTextValue();
				XMLComment *childComment = new XMLComment(childValue, commentHolder);
				commentHolder->AddXMLComment(childComment);
			}
			break;
			
			default:
				// Invalid node type
				errorFormat = NBundleString(kKeyMapSelectInvalidNodeType, "", kErrorTableName);
				errorString.Format(errorFormat, attributeString);
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

// Create an XML tree

NXMLNode *KeyMapSelect::CreateXMLTree(void)
{
	NXMLNode *xmlTree = new NXMLNode(kNXMLNodeElement, kKeyMapSelectElement);
	NString mapIndexString;
	mapIndexString.Format("%d", mMapIndexNumber);
	xmlTree->SetElementAttribute(kMapIndexAttribute, mapIndexString);
	AddCommentsToXMLTree(*xmlTree);
	SInt32 numModifiers = mModifierList->GetElementCount();
	for (SInt32 i = 1; i <= numModifiers; i++) {
		ModifierElement *modifierElement = mModifierList->GetModifierElement(i);
		NXMLNode *modifierElementTree = modifierElement->CreateXMLTree();
		xmlTree->AddChild(modifierElementTree);
	}
	return xmlTree;
}

NString KeyMapSelect::GetDescription(void)
{
	NString descriptionString;
	descriptionString.Format("keyMapSelect index=%d", mMapIndexNumber);
	return descriptionString;
}

// Append to a list of comment holders

void KeyMapSelect::AppendToList(XMLCommentHolderList& ioList)
{
	ioList.push_back(this);
	mModifierList->AppendToList(ioList);
}

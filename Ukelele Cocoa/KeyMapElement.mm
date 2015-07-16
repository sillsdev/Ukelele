/*
 *  KeyMapElement.mm
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "KeyMapElement.h"
#include "UkeleleStrings.h"
#include "LayoutInfo.h"
#include "XMLErrors.h"
#include "NBundle.h"
#include "NCocoa.h"

// Key strings
const NString kKeyMapElementMissingIndexAttribute = "KeyMapElementMissingIndexAttribute";
const NString kKeyMapElementMissingBaseMap = "KeyMapElementMissingBaseMap";
const NString kKeyMapElementMissingBaseIndex = "KeyMapElementMissingBaseIndex";
const NString kKeyMapElementWrongElementType = "KeyMapElementWrongElementType";
const NString kKeyMapElementInvalidNodeType = "KeyMapElementInvalidNodeType";
const NString kKeyMapElementRepeatedKeyElement = "KeyMapElementRepeatedKeyElement";

// Standard special key output
std::pair<UInt32, NString> KeyMapElement::sSpecialKeyList[kSpecialKeyCount] = {
	std::make_pair(kKeyReturn, "&#x000d;"),
	std::make_pair(kKeyTab, "&#x0009;"),
	std::make_pair(kKeyEnter, "&#x0003;"),
	std::make_pair(kKeyEscape, "&#x001b;"),
	std::make_pair(kKeyPadClear, "&#x001b;"),
	std::make_pair(kKeyDelete, "&#x0008;"),
	std::make_pair(kKeyF1, "&#x0010;"),
	std::make_pair(kKeyF2, "&#x0010;"),
	std::make_pair(kKeyF3, "&#x0010;"),
	std::make_pair(kKeyF4, "&#x0010;"),
	std::make_pair(kKeyF5, "&#x0010;"),
	std::make_pair(kKeyF6, "&#x0010;"),
	std::make_pair(kKeyF7, "&#x0010;"),
	std::make_pair(kKeyF8, "&#x0010;"),
	std::make_pair(kKeyF9, "&#x0010;"),
	std::make_pair(kKeyF10, "&#x0010;"),
	std::make_pair(kKeyF11, "&#x0010;"),
	std::make_pair(kKeyF12, "&#x0010;"),
	std::make_pair(kKeyF13, "&#x0010;"),
	std::make_pair(kKeyF14, "&#x0010;"),
	std::make_pair(kKeyF15, "&#x0010;"),
	std::make_pair(kKeyF16, "&#x0010;"),
	std::make_pair(kKeyF17, "&#x0010;"),
	std::make_pair(kKeyF18, "&#x0010;"),
	std::make_pair(kKeyF19, "&#x0010;"),
	std::make_pair(kKeyHelp, "&#x0005;"),
	std::make_pair(kKeyHome, "&#x0001;"),
	std::make_pair(kKeyEnd, "&#x0004;"),
	std::make_pair(kKeyPageUp, "&#x000b;"),
	std::make_pair(kKeyPageDown, "&#x000c;"),
	std::make_pair(kKeyForwardDelete, "&#x007f;"),
	std::make_pair(kKeyLeftArrow, "&#x001c;"),
	std::make_pair(kKeyRightArrow, "&#x001d;"),
	std::make_pair(kKeyUpArrow, "&#x001e;"),
	std::make_pair(kKeyDownArrow, "&#x001f;"),
	std::make_pair(66, "&#x001d;"),
	std::make_pair(70, "&#x001c;"),
	std::make_pair(72, "&#x001f;"),
	std::make_pair(77, "&#x001e;")
};

const UInt32 kDummyKeyCode = 512;

// Constructor

KeyMapElement::KeyMapElement(const UInt32 inIndex, const NString inBaseMapSet,
	const UInt32 inBaseIndex, const UInt32 inTableSize)
	: XMLCommentHolder(kKeyMapElementType), mIndex(inIndex), mBaseMapSet(inBaseMapSet), mBaseIndex(inBaseIndex)
{
	mElementTable.reset(new KeyElementTable(inTableSize));
}

// Copy constructor

KeyMapElement::KeyMapElement(const KeyMapElement& inOriginal)
	: XMLCommentHolder(inOriginal)
{
	mIndex = inOriginal.mIndex;
	mBaseMapSet = inOriginal.mBaseMapSet;
	mBaseIndex = inOriginal.mBaseIndex;
	mElementTable.reset(new KeyElementTable(*inOriginal.mElementTable));
}

// Destructor

KeyMapElement::~KeyMapElement(void)
{
}

#pragma mark -

// Test whether the key element table is empty

bool KeyMapElement::IsEmpty(void) const
{
	return mElementTable->IsEmpty();
}

// Get the maximum length of an output string

UInt32 KeyMapElement::GetMaxout(void) const
{
	return mElementTable->GetMaxout();
}

// Test whether any special key output is missing

bool KeyMapElement::IsMissingSpecialKeyOutput(void) const
{
	if (!mBaseMapSet.IsEmpty()) {
		// Relative maps don't need to have the special key output specified
		return false;
	}
	for (UInt32 i = 0; i < kSpecialKeyCount; i++) {
		KeyElement *keyElement = GetKeyElement(sSpecialKeyList[i].first);
		if (keyElement == NULL || keyElement->GetElementType() == kKeyFormUndefined) {
			return true;
		}
	}
	return false;
}

bool KeyMapElement::HasInlineAction(void) const
{
	return mElementTable->HasInlineAction();
}

#pragma mark -

// Add a key element at the given index

void KeyMapElement::AddKeyElement(const UInt32 inIndex, KeyElement *inKeyElement)
{
	mElementTable->AddKeyElement(inIndex, inKeyElement);
}

// Get the key element at the given index

KeyElement *KeyMapElement::GetKeyElement(const UInt32 inIndex) const
{
	return mElementTable->GetKeyElement(inIndex);
}

// Remove the key element at the given index

void KeyMapElement::RemoveKeyElement(const UInt32 inIndex)
{
	mElementTable->RemoveKeyElement(inIndex);
}

#pragma mark -

// Get all the referenced state names

void KeyMapElement::GetStateNames(NSMutableSet *ioStates, const UInt32 inReachable) const
{
	SInt32 numElements = mElementTable->GetTableSize();
	for (SInt32 i = 0; i < numElements; i++) {
		KeyElement *keyElement = mElementTable->GetKeyElement(i);
		if (keyElement != NULL) {
			keyElement->GetStateNames(ioStates, inReachable);
		}
	}
}

// Replace all instances of a state name with a new name

void KeyMapElement::ReplaceStateName(const NString inOldName, const NString inNewName)
{
	SInt32 numElements = mElementTable->GetTableSize();
	for (SInt32 i = 0; i < numElements; i++) {
		KeyElement *keyElement = mElementTable->GetKeyElement(i);
		if (keyElement != NULL) {
			keyElement->ReplaceStateName(inOldName, inNewName);
		}
	}
}

// Remove the states in the given set

void KeyMapElement::RemoveStates(NSSet *inStates)
{
	SInt32 numElements = mElementTable->GetTableSize();
	for (SInt32 i = 0; i < numElements; i++) {
		KeyElement *keyElement = mElementTable->GetKeyElement(i);
		if (keyElement != NULL) {
			keyElement->RemoveStates(inStates);
		}
	}
}

// Replace all instances of an action name with a new name

void KeyMapElement::ChangeActionName(const NString inOldName, const NString inNewName)
{
	SInt32 numElements = mElementTable->GetTableSize();
	for (SInt32 i = 0; i < numElements; i++) {
		KeyElement *keyElement = mElementTable->GetKeyElement(i);
		if (keyElement != NULL) {
			keyElement->ChangeActionName(inOldName, inNewName);
		}
	}
}

// Get actions that are used

void KeyMapElement::GetUsedActions(NSMutableSet *ioActionSet) const
{
	mElementTable->GetUsedActions(ioActionSet);
}

#pragma mark -

// Get the special key output for the given key code

NString KeyMapElement::GetSpecialKeyOutput(const UInt32 inKeyCode)
{
	for (UInt32 i = 0; i < kSpecialKeyCount; i++) {
		if (inKeyCode == sSpecialKeyList[i].first) {
			return sSpecialKeyList[i].second;
		}
	}
	return NString("");
}

// Add standard special key output

void KeyMapElement::AddSpecialKeyOutput(void)
{
	if (!mBaseMapSet.IsEmpty()) {
		// Do nothing for relative maps
		return;
	}
	// Add output for non-editable keys
	KeyElement *keyElement = NULL;
	for (UInt32 i = 0; i < kSpecialKeyCount; i++) {
		UInt32 keyCode = sSpecialKeyList[i].first;
		keyElement = mElementTable->GetKeyElement(keyCode);
		if (keyElement == NULL) {
			keyElement = new KeyElement(keyCode);
		}
		if (keyElement->GetElementType() == kKeyFormUndefined) {
			keyElement->NewOutputElement(sSpecialKeyList[i].second);
			AddKeyElement(keyCode, keyElement);
		}
	}
}

#pragma mark -

// Import a dead key from another keyboard layout

void KeyMapElement::ImportDeadKey(const KeyMapElement *inSource,
								  const NString inLocalState,
								  const NString inSourceState,
								  const shared_ptr<ActionElementSet> inSourceActionList,
								  shared_ptr<ActionElementSet> inLocalActionList)
{
	UInt32 elementCount = mElementTable->GetTableSize();
	for (UInt32 eltIndex = 0; eltIndex < elementCount; eltIndex++) {
		KeyElement *sourceElement = inSource->GetKeyElement(eltIndex);
		if (sourceElement == NULL) {
			// Nothing to do
			continue;
		}
		KeyElement *localElement = GetKeyElement(eltIndex);
		if (localElement == NULL) {
			localElement = new KeyElement(eltIndex);
			mElementTable->AddKeyElement(eltIndex, localElement);
		}
		NString importString;
		UInt32 sourceType = sourceElement->GetTypeForState(inSourceState, inSourceActionList, importString);
		switch (sourceType) {
			case kStateNull:
				if (localElement->GetElementType() == kKeyFormOutput) {
					localElement->MakeActionElement(kStateNone, inLocalActionList);
				}
			break;
			
			case kStateOutput:
				localElement->ChangeOutput(inLocalState, importString, inLocalActionList);
			break;
			
			case kStateNext:
				localElement->MakeDeadKey(inLocalState, importString, inLocalActionList);
			break;
		}
	}
}

// Swap two keys

void KeyMapElement::SwapKeyElements(const UInt32 inKeyCode1, const UInt32 inKeyCode2)
{
	mElementTable->SwapKeyElements(inKeyCode1, inKeyCode2);
}

// Unlink a key map

void KeyMapElement::UnlinkKeyMapElement(shared_ptr<ActionElementSet> inActionList)
{
	UInt32 tableSize = mElementTable->GetTableSize();
	for (UInt32 i = 0; i < tableSize; i++) {
		KeyElement *keyElement = mElementTable->GetKeyElement(i);
		if (keyElement != NULL && keyElement->GetElementType() == kKeyFormAction) {
			NString actionName = keyElement->GetActionName();
			ActionElement *duplicateAction = inActionList->CreateDuplicateActionElement(actionName);
			NString duplicateName = duplicateAction->GetActionID();
			keyElement->ChangeActionName(actionName, duplicateName);
		}
	}
}

#pragma mark -

// Create a key map element from an XML tree

ErrorMessage KeyMapElement::CreateFromXMLTree(const NXMLNode& inXMLTree,
											  KeyMapElement*& outElement,
											  shared_ptr<XMLCommentContainer> ioCommentContainer)
{
	ErrorMessage errorValue(XMLNoError, "");
	NString errorString;
	NString errorFormat;
	NN_ASSERT(inXMLTree.IsElement(kKeyMapElement));
	NDictionary attributesDictionary = inXMLTree.GetElementAttributes();
	if (!attributesDictionary.HasKey(kIndexAttribute)) {
		errorString = NBundleString(kKeyMapElementMissingIndexAttribute, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorString);
		return errorValue;
	}
	NString indexString = inXMLTree.GetElementAttribute(kIndexAttribute);
	NNumber indexNumber(indexString);
	UInt32 indexValue = indexNumber.GetUInt32();
	if (attributesDictionary.HasKey(kBaseMapSetAttribute) && !attributesDictionary.HasKey(kBaseIndexAttribute)) {
		errorFormat = NBundleString(kKeyMapElementMissingBaseIndex, "", kErrorTableName);
		errorString.Format(errorFormat, indexString);
		errorValue = ErrorMessage(XMLMissingBaseIndexError, errorString);
		return errorValue;
	}
	if (!attributesDictionary.HasKey(kBaseMapSetAttribute) && attributesDictionary.HasKey(kBaseIndexAttribute)) {
		errorFormat = NBundleString(kKeyMapElementMissingBaseMap, "", kErrorTableName);
		errorString.Format(errorFormat, indexString);
		errorValue = ErrorMessage(XMLMissingBaseMapError, errorString);
		return errorValue;
	}
	NString baseMap = inXMLTree.GetElementAttribute(kBaseMapSetAttribute);
	NString baseIndexString = inXMLTree.GetElementAttribute(kBaseIndexAttribute);
	UInt32 baseIndex = 0;
	if (!baseIndexString.IsEmpty()) {
		NNumber baseIndexNumber(baseIndexString);
		baseIndex = baseIndexNumber.GetUInt32();
	}
	outElement = new KeyMapElement(indexValue, baseMap, baseIndex, 0);
	XMLCommentHolder *commentHolder = outElement;
	const NXMLNodeList *childList = inXMLTree.GetChildren();
	for (NXMLNodeListConstIterator pos = childList->begin(); pos != childList->end() && errorValue == XMLNoError; ++pos) {
		NXMLNode *childTree = *pos;
		switch (childTree->GetType()) {
			case kNXMLNodeElement:
				// An element, which should be a key element
				if (childTree->GetTextValue()  != kKeyElement) {
					// Not a key element
					errorFormat = NBundleString(kKeyMapElementWrongElementType, "", kErrorTableName);
					errorString.Format(errorFormat, indexString, childTree->GetTextValue());
					errorValue = ErrorMessage(XMLBadElementTypeError, errorString);
					break;
				}
				KeyElement *keyElement;
				errorValue = KeyElement::CreateFromXMLTree(*childTree, keyElement, ioCommentContainer);
				if (errorValue == XMLNoError) {
					UInt32 keyCode = keyElement->GetKeyCode();
					if (outElement->GetKeyElement(keyCode) != NULL) {
						// Repeated key element
						errorFormat = NBundleString(kKeyMapElementRepeatedKeyElement, "", kErrorTableName);
						errorString.Format(errorFormat, indexString, keyCode);
						errorValue = ErrorMessage(XMLRepeatedKeyElementError, errorString);
					}
					else if (keyCode != kDummyKeyCode) {
						outElement->AddKeyElement(keyCode, keyElement);
					}
				}
				if (commentHolder != NULL) {
					commentHolder->RemoveDuplicateComments();
				}
				commentHolder = keyElement;
				ioCommentContainer->AddCommentHolder(keyElement);
			break;
			
			case kNXMLNodeComment: {
				// A comment, so add it to the structure
				XMLComment *childComment = new XMLComment(childTree->GetTextValue(), commentHolder);
				commentHolder->AddXMLComment(childComment);
			}
			break;
			
			default:
				// Invalid node type
				errorFormat = NBundleString(kKeyMapElementInvalidNodeType, "", kErrorTableName);
				errorString.Format(errorFormat, indexString);
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

ErrorMessage KeyMapElement::CreateFromXML(NSXMLElement *inXMLTree, KeyMapElement *&outElement, shared_ptr<XMLCommentContainer> ioCommentContainer) {
	ErrorMessage errorValue(XMLNoError, "");
	NString errorString;
	NString errorFormat;
	NSXMLNode *attributeNode = [inXMLTree attributeForName:ToNS(kIndexAttribute)];
	if (attributeNode == nil) {
		errorString = NBundleString(kKeyMapElementMissingIndexAttribute, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorString);
		return errorValue;
	}
	NString indexString = ToNN([attributeNode stringValue]);
	NNumber indexNumber(indexString);
	UInt32 indexValue = indexNumber.GetUInt32();
	NSXMLNode *baseMapSetAttribute = [inXMLTree attributeForName:ToNS(kBaseMapSetAttribute)];
	NSXMLNode *baseIndexAttribute = [inXMLTree attributeForName:ToNS(kBaseIndexAttribute)];
	if (baseMapSetAttribute != nil && baseIndexAttribute == nil) {
		errorFormat = NBundleString(kKeyMapElementMissingBaseIndex, "", kErrorTableName);
		errorString.Format(errorFormat, indexString);
		errorValue = ErrorMessage(XMLMissingBaseIndexError, errorString);
		return errorValue;
	}
	if (baseMapSetAttribute == nil && baseIndexAttribute != nil) {
		errorFormat = NBundleString(kKeyMapElementMissingBaseMap, "", kErrorTableName);
		errorString.Format(errorFormat, indexString);
		errorValue = ErrorMessage(XMLMissingBaseMapError, errorString);
		return errorValue;
	}
	NString baseMap = ToNN([baseMapSetAttribute stringValue]);
	NString baseIndexString = ToNN([baseIndexAttribute stringValue]);
	UInt32 baseIndex = 0;
	if (!baseIndexString.IsEmpty()) {
		NNumber baseIndexNumber(baseIndexString);
		baseIndex = baseIndexNumber.GetUInt32();
	}
	outElement = new KeyMapElement(indexValue, baseMap, baseIndex, 0);
	XMLCommentHolder *commentHolder = outElement;
	for (NSXMLNode *childNode in [inXMLTree children]) {
		switch ([childNode kind]) {
			case NSXMLElementKind: {
					// An element, which should be a key element
				if (ToNN([childNode name]) != kKeyElement) {
						// Not a key element
					errorFormat = NBundleString(kKeyMapElementWrongElementType, "", kErrorTableName);
					errorString.Format(errorFormat, indexString, ToNN([childNode name]));
					errorValue = ErrorMessage(XMLBadElementTypeError, errorString);
					break;
				}
				KeyElement *keyElement;
				errorValue = KeyElement::CreateFromXML((NSXMLElement *)childNode, keyElement, ioCommentContainer);
				if (errorValue == XMLNoError) {
					UInt32 keyCode = keyElement->GetKeyCode();
					if (outElement->GetKeyElement(keyCode) != NULL) {
						// Repeated key element
						errorFormat = NBundleString(kKeyMapElementRepeatedKeyElement, "", kErrorTableName);
						errorString.Format(errorFormat, indexString, keyCode);
						errorValue = ErrorMessage(XMLRepeatedKeyElementError, errorString);
					}
					else if (keyCode != kDummyKeyCode) {
						outElement->AddKeyElement(keyCode, keyElement);
					}
				}
				if (commentHolder != NULL) {
					commentHolder->RemoveDuplicateComments();
				}
				commentHolder = keyElement;
				ioCommentContainer->AddCommentHolder(keyElement);
			}
			break;
				
			case NSXMLCommentKind: {
					// A comment, so add it to the structure
				XMLComment *childComment = new XMLComment(ToNN([childNode stringValue]), commentHolder);
				commentHolder->AddXMLComment(childComment);
			}
			break;
				
			default:
				// Invalid node type
				errorFormat = NBundleString(kKeyMapElementInvalidNodeType, "", kErrorTableName);
				errorString.Format(errorFormat, indexString);
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

// Create an XML tree representing the key map element

NXMLNode *KeyMapElement::CreateXMLTree(void)
{
	NXMLNode *xmlTree = new NXMLNode(kNXMLNodeElement, kKeyMapElement);
	NString indexString;
	indexString.Format("%d", mIndex);
	xmlTree->SetElementAttribute(kIndexAttribute, indexString);
	if (!mBaseMapSet.IsEmpty()) {
		xmlTree->SetElementAttribute(kBaseMapSetAttribute, mBaseMapSet);
		NString baseIndexString;
		baseIndexString.Format("%d", mBaseIndex);
		xmlTree->SetElementAttribute(kBaseIndexAttribute, baseIndexString);
	}
	AddCommentsToXMLTree(*xmlTree);
	UInt32 keyTableSize = mElementTable->GetTableSize();
	bool hasElement = false;
	for (UInt32 i = 0; i < keyTableSize; i++) {
		KeyElement *keyElement = mElementTable->GetKeyElement(i);
		if (keyElement != NULL) {
			NXMLNode *keyElementTree = keyElement->CreateXMLTree();
			xmlTree->AddChild(keyElementTree);
			keyElement->AddCommentsToXMLTree(*xmlTree);
			hasElement = true;
		}
	}
	if (!hasElement) {
		// We need to add a dummy element
		KeyElement *dummyElement = new KeyElement(kDummyKeyCode);
		dummyElement->NewOutputElement("");
		NXMLNode *dummyElementTree = dummyElement->CreateXMLTree();
		xmlTree->AddChild(dummyElementTree);
		delete dummyElement;
	}
	return xmlTree;
}

NSXMLElement *KeyMapElement::CreateXML(void) {
	NSXMLElement *xmlTree = [NSXMLElement elementWithName:ToNS(kKeyMapElement)];
	NSXMLNode *attributeNode = [NSXMLNode attributeWithName:ToNS(kIndexAttribute) stringValue:[NSString stringWithFormat:@"%d", mIndex]];
	[xmlTree addAttribute:attributeNode];
	if (!mBaseMapSet.IsEmpty()) {
		attributeNode = [NSXMLNode attributeWithName:ToNS(kBaseMapSetAttribute) stringValue:ToNS(mBaseMapSet)];
		[xmlTree addAttribute:attributeNode];
		attributeNode = [NSXMLNode attributeWithName:ToNS(kBaseIndexAttribute) stringValue:[NSString stringWithFormat:@"%d", mBaseIndex]];
		[xmlTree addAttribute:attributeNode];
	}
	AddCommentsToXML(xmlTree);
	UInt32 keyTableSize = mElementTable->GetTableSize();
	bool hasElement = false;
	for (UInt32 i = 0; i < keyTableSize; i++) {
		KeyElement *keyElement = mElementTable->GetKeyElement(i);
		if (keyElement != NULL) {
			NSXMLElement *keyElementTree = keyElement->CreateXML();
			[xmlTree addChild:keyElementTree];
			keyElement->AddCommentsToXML(xmlTree);
			hasElement = true;
		}
	}
	if (!hasElement) {
		// We need to add a dummy element
		KeyElement *dummyElement = new KeyElement(kDummyKeyCode);
		dummyElement->NewOutputElement("");
		NSXMLElement *dummyElementTree = dummyElement->CreateXML();
		[xmlTree addChild:dummyElementTree];
		delete dummyElement;
	}
	return xmlTree;
}

NString KeyMapElement::GetDescription(void)
{
	NString descriptionString;
	descriptionString.Format(NString("keyMap index=%d"), mIndex);
	if (!mBaseMapSet.IsEmpty()) {
		NString baseMapString;
		baseMapString.Format(" baseMap=%@, baseIndex =%d", mBaseMapSet, mBaseIndex);
		descriptionString += baseMapString;
	}
	return descriptionString;
}

void KeyMapElement::AppendToList(XMLCommentHolderList& ioList)
{
	ioList.push_back(this);
	mElementTable->AppendToList(ioList);
}

#pragma mark -

// Create a default key map element

KeyMapElement *KeyMapElement::CreateDefaultKeyMapElement(const UInt32 inIndex,
														 const NString inBaseMapSet,
														 const UInt32 inBaseIndex)
{
	KeyMapElement *keyMapElement = new KeyMapElement(inIndex, inBaseMapSet, inBaseIndex, 0);
	if (inBaseMapSet.IsEmpty()) {
		keyMapElement->AddSpecialKeyOutput();
	}
	return keyMapElement;
}

// Create a default key map element of the given type

KeyMapElement *KeyMapElement::CreateDefaultKeyMapElement(const UInt32 inSourceType,
														 const UInt32 inIndex,
														 const NString inBaseMapSet,
														 const UInt32 inBaseIndex)
{
	KeyMapElement *keyMapElement = CreateDefaultKeyMapElement(inIndex, inBaseMapSet, inBaseIndex);
	UInt32 tableSize = keyMapElement->GetKeyElementCount();
	for (UInt32 keyCode = 0; keyCode < tableSize; keyCode++) {
		NString outputString = ToNN([LayoutInfo getStandardKeyOutputForKeyboard:inSourceType forKeyCode:keyCode]);
		if (!outputString.IsEmpty()) {
			KeyElement *keyElement = new KeyElement(keyCode);
			keyElement->NewOutputElement(outputString);
			keyMapElement->AddKeyElement(keyCode, keyElement);
		}
	}
	return keyMapElement;
}

// Create a basic key map element, with just the special keys

KeyMapElement *KeyMapElement::CreateBasicKeyMapElement(void)
{
	return CreateDefaultKeyMapElement(0, NString(""), 0);
}

// Get the standard output for a special key

NString KeyMapElement::GetStandardSpecialOutput(const UInt32 inKeyCode)
{
	for (UInt32 i = 0; i < kSpecialKeyCount; i++) {
		if (inKeyCode == sSpecialKeyList[i].first) {
			return sSpecialKeyList[i].second;
		}
	}
	return NString("");
}

#pragma mark -

// Constructor

KeyMapElementList::KeyMapElementList(void)
{
}

// Copy constructor

KeyMapElementList::KeyMapElementList(const KeyMapElementList& inOriginal)
{
	KeyMapElementVector original = inOriginal.mElementList;
	for (KeyMapElementIterator pos = original.begin(); pos != original.end(); ++pos) {
		KeyMapElement *element = *pos;
		if (element != NULL) {
			mElementList.push_back(new KeyMapElement(*element));
		}
		else {
			mElementList.push_back(NULL);
		}
	}
}

// Destructor

KeyMapElementList::~KeyMapElementList(void)
{
	if (!mElementList.empty()) {
		for (KeyMapElementIterator pos = mElementList.begin(); pos != mElementList.end(); ++pos) {
			KeyMapElement *element = *pos;
			if (element != NULL) {
				delete element;
			}
		}
	}
}

#pragma mark -

// Get the maximum length output string

UInt32 KeyMapElementList::GetMaxout(void) const
{
	UInt32 maxout = 0;
	for (KeyMapElementConstIterator pos = mElementList.begin(); pos != mElementList.end(); ++pos) {
		KeyMapElement *keyMapElement = *pos;
		if (keyMapElement != NULL) {
			UInt32 keyMapMaxout = keyMapElement->GetMaxout();
			if (keyMapMaxout > maxout) {
				maxout = keyMapMaxout;
			}
		}
	}
	return maxout;
}

// Get the maximum size of key maps

UInt32 KeyMapElementList::GetKeyMapSize(void) const
{
	UInt32 maxSize = 0;
	for (KeyMapElementConstIterator pos = mElementList.begin(); pos != mElementList.end(); ++pos) {
		KeyMapElement *keyMapElement = *pos;
		if (keyMapElement != NULL) {
			UInt32 keyMapSize = keyMapElement->GetKeyElementCount();
			if (keyMapSize > maxSize) {
				maxSize = keyMapSize;
			}
		}
	}
	return maxSize;
}

#pragma mark -

// Insert a key map element at the given index

void KeyMapElementList::InsertKeyMapElementAtIndex(UInt32 inIndex, KeyMapElement *inKeyMapElement)
{
	UInt32 numKeyMaps = static_cast<UInt32>(mElementList.size());
	if (inIndex >= numKeyMaps) {
		mElementList.push_back(inKeyMapElement);
	}
	else {
		for (KeyMapElementIterator pos = mElementList.begin() + inIndex; pos != mElementList.end(); ++pos) {
			KeyMapElement *keyMapElement = *pos;
			if (keyMapElement != NULL) {
				keyMapElement->SetIndex(keyMapElement->GetIndex() + 1);
				UInt32 baseIndex = keyMapElement->GetBaseIndex();
				if (baseIndex != 0 && baseIndex > inIndex) {
					keyMapElement->SetBaseIndex(baseIndex + 1);
				}
			}
		}
		mElementList.insert(mElementList.begin() + inIndex, inKeyMapElement);
	}
}

// Add a key map element to the end of the list

void KeyMapElementList::AppendKeyMapElement(KeyMapElement *inKeyMapElement)
{
	UInt32 index = inKeyMapElement->GetIndex();
	if (index >= mElementList.size()) {
		mElementList.resize(index + 1, NULL);
	}
	NN_ASSERT(mElementList[index] == NULL);
	mElementList[index] = inKeyMapElement;
}

// Get the key map element at the given index

KeyMapElement *KeyMapElementList::GetKeyMapElement(const UInt32 inIndex) const
{
	NN_ASSERT(inIndex < mElementList.size());
	if (!mElementList.empty()) {
		return mElementList[inIndex];
	}
	return NULL;
}

// Remove the key map element at the given index

KeyMapElement *KeyMapElementList::RemoveKeyMapElement(const UInt32 inIndex)
{
	NN_ASSERT(inIndex < mElementList.size());
	KeyMapElementIterator pos = mElementList.begin() + inIndex;
	KeyMapElement *keyMap = *pos;
	mElementList.erase(pos);
	for (pos = mElementList.begin() + inIndex; pos != mElementList.end(); ++pos) {
		KeyMapElement *keyMapElement = *pos;
		if (keyMapElement != NULL) {
			keyMapElement->SetIndex(keyMapElement->GetIndex() - 1);
			UInt32 baseIndex = keyMapElement->GetBaseIndex();
			if (baseIndex != 0 && baseIndex > inIndex) {
				keyMapElement->SetBaseIndex(baseIndex - 1);
			}
		}
	}
	return keyMap;
}

// Clear out the list without deleting the elements

void KeyMapElementList::Clear(void)
{
	mElementList.clear();
}

// Turn the key map elements into relative maps

void KeyMapElementList::MakeRelative(const NString inBaseMapSet)
{
	if (!mElementList.empty()) {
		for (KeyMapElementIterator pos = mElementList.begin(); pos != mElementList.end(); ++pos) {
			KeyMapElement *keyMapElement = *pos;
			if (keyMapElement != NULL) {
				keyMapElement->SetBaseMapSet(inBaseMapSet);
				keyMapElement->SetBaseIndex(keyMapElement->GetIndex());
			}
		}
	}
}

#pragma mark -

// Get all states referenced by the key maps

void KeyMapElementList::GetStateNames(NSMutableSet *ioStates, const UInt32 inReachable) const
{
	for (KeyMapElementConstIterator pos = mElementList.begin(); pos != mElementList.end(); ++pos) {
		KeyMapElement *keyMapElement = *pos;
		if (keyMapElement != NULL) {
			keyMapElement->GetStateNames(ioStates, inReachable);
		}
	}
}

// Replace all instances of a state name with the new name

void KeyMapElementList::ReplaceStateName(const NString inOldName, const NString inNewName)
{
	for (KeyMapElementIterator pos = mElementList.begin(); pos != mElementList.end(); ++pos) {
		KeyMapElement *keyMapElement = *pos;
		if (keyMapElement != NULL) {
			keyMapElement->ReplaceStateName(inOldName, inNewName);
		}
	}
}

// Remove the states in the given set

void KeyMapElementList::RemoveStates(NSSet *inStates)
{
	for (KeyMapElementIterator pos = mElementList.begin(); pos != mElementList.end(); ++pos) {
		KeyMapElement *keyMapElement = *pos;
		if (keyMapElement != NULL) {
			keyMapElement->RemoveStates(inStates);
		}
	}
}

// Change an action name

void KeyMapElementList::ChangeActionName(const NString inOldName, const NString inNewName)
{
	for (KeyMapElementIterator pos = mElementList.begin(); pos != mElementList.end(); ++pos) {
		KeyMapElement *keyMapElement = *pos;
		if (keyMapElement != NULL) {
			keyMapElement->ChangeActionName(inOldName, inNewName);
		}
	}
}

// Get the actions that are used

void KeyMapElementList::GetUsedActions(NSMutableSet *ioActionSet) const
{
	for (KeyMapElementConstIterator pos = mElementList.begin(); pos != mElementList.end(); ++pos) {
		KeyMapElement *keyMapElement = *pos;
		if (keyMapElement != NULL) {
			keyMapElement->GetUsedActions(ioActionSet);
		}
	}
}

#pragma mark -

// Add the elements of the list to an XML tree

void KeyMapElementList::AddToXMLTree(NXMLNode& inXMLTree)
{
	for (KeyMapElementIterator pos = mElementList.begin(); pos != mElementList.end(); ++pos) {
		KeyMapElement *keyMapElement = *pos;
		if (keyMapElement != NULL) {
			NXMLNode *keyMapElementTree = keyMapElement->CreateXMLTree();
			inXMLTree.AddChild(keyMapElementTree);
		}
	}
}

void KeyMapElementList::AddToXML(NSXMLElement *inXMLTree) {
	for (KeyMapElementIterator pos = mElementList.begin(); pos != mElementList.end(); ++pos) {
		KeyMapElement *keyMapElement = *pos;
		if (keyMapElement != NULL) {
			NSXMLElement *keyMapElementTree = keyMapElement->CreateXML();
			[inXMLTree addChild:keyMapElementTree];
		}
	}
}

void KeyMapElementList::AppendToList(XMLCommentHolderList& ioList)
{
	for (KeyMapElementIterator pos = mElementList.begin(); pos != mElementList.end(); ++pos) {
		(*pos)->AppendToList(ioList);
	}
}

/*
 *  LayoutsElement.mm
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "LayoutsElement.h"
#include "UkeleleConstants.h"
#include "UkeleleStrings.h"
#include "XMLErrors.h"
#include "NBundle.h"
#include "NCocoa.h"

// Key strings
const NString kLayoutsElementWrongElementType = "LayoutsElementWrongElementType";
const NString kLayoutsElementInvalidNodeType = "LayoutsElementInvalidNodeType";

// Constructor

LayoutsElement::LayoutsElement(void)
	: XMLCommentHolder(kLayoutsElementType)
{
}

// Destructor

LayoutsElement::~LayoutsElement(void)
{
	if (!mLayoutList.empty()) {
		LayoutElementList::iterator pos;
		for (pos = mLayoutList.begin(); pos != mLayoutList.end(); ++pos) {
			LayoutElement *theLayout = *pos;
			delete theLayout;
		}
	}
}

// Add a layout to the element

void LayoutsElement::AddLayout(LayoutElement *inLayout)
{
	NN_ASSERT(inLayout != NULL);
	mLayoutList.push_back(inLayout);
}

// Find the layout corresponding to the given keyboard type

LayoutElement *LayoutsElement::FindLayout(const UInt32 inKeyboardType)
{
	if (mLayoutList.empty()) {
		// No layouts at all
		return NULL;
	}
	
	LayoutElement *theLayout = NULL;
	UInt32 first, last;
	LayoutElementList::iterator pos;
	for (pos = mLayoutList.begin(); pos != mLayoutList.end(); ++pos) {
		theLayout = *pos;
		first = theLayout->GetFirst();
		last = theLayout->GetLast();
		if (inKeyboardType >= first && inKeyboardType <= last) {
			// Found a suitable layout
			return theLayout;
		}
	}
	
	// We did not find the keyboard code, so it is the first layout, unless
	// the keyboard code is for a JIS keyboard
	OSType keyboardType = ::KBGetLayoutType((SInt16)inKeyboardType);
	if (keyboardType == kKeyboardJIS) {
		// It is JIS, so find the first layout to handle the default JIS layout
		const UInt32 defaultJIS = gestaltPwrBkEKJISKbd;
		for (pos = mLayoutList.begin(); pos != mLayoutList.end(); ++pos) {
			theLayout = *pos;
			first = theLayout->GetFirst();
			last = theLayout->GetLast();
			if (defaultJIS >= first && defaultJIS <= last) {
				// Found a suitable layout
				return theLayout;
			}
		}
	}
	// Return the first layout
	return mLayoutList[0];
}

// Get all the layouts that reference the given modifier map

LayoutElementList *LayoutsElement::GetLayoutsForModifierMap(const NString inModifierMapID)
{
	LayoutElementList *result = new LayoutElementList;
	LayoutElementList::iterator pos;
	for (pos = mLayoutList.begin(); pos != mLayoutList.end(); ++pos) {
		LayoutElement *theLayout = *pos;
		NString modifierMapID = theLayout->GetModifiers();
		if (modifierMapID == inModifierMapID) {
			// Add the layout to the result list
			result->push_back(theLayout);
		}
	}
	return result;
}

// Return a list of all the names of keyMapSets referenced

NStringList *LayoutsElement::GetKeyMapSetNames(void) const
{
	NStringList *result = new NStringList;
	LayoutElementList::const_iterator pos;
	for (pos = mLayoutList.begin(); pos != mLayoutList.end(); ++pos) {
		LayoutElement *theLayout = *pos;
		NString keyMapSet = theLayout->GetMapSet();
		if (std::find(result->begin(), result->end(), keyMapSet) == result->end()) {
			// Add the keyMapSet to the result list
			result->push_back(keyMapSet);
		}
	}
	return result;
}

// Get all the keyMapSets for the given modifier map

NStringList *LayoutsElement::GetKeyMapsForModifierMap(const NString inModifierMapID) {
	NStringList *result = new NStringList;
	LayoutElementList::const_iterator pos;
	for (pos = mLayoutList.begin(); pos != mLayoutList.end(); ++pos) {
		LayoutElement *theLayout = *pos;
		NString modifierMapID = theLayout->GetModifiers();
		if (modifierMapID == inModifierMapID) {
				// This keyMapSet would use the modifier map, so check add it if we haven't already
			NString keyMapSet = theLayout->GetMapSet();
			if (std::find(result->begin(), result->end(), keyMapSet) == result->end()) {
				result->push_back(keyMapSet);
			}
		}
	}
	return result;
}

NStringList *LayoutsElement::GetModifierMaps() const {
	NStringList *result = new NStringList;
	LayoutElementList::const_iterator pos;
	for (pos = mLayoutList.begin(); pos != mLayoutList.end(); ++pos) {
		LayoutElement *theLayout = *pos;
		NString modifierMapID = theLayout->GetModifiers();
			// Add the modifier map ID if it hasn't already been seen
		if (std::find(result->begin(), result->end(), modifierMapID) == result->end()) {
			result->push_back(modifierMapID);
		}
	}
	return result;
}

#pragma mark -

// Static method to create a basic layouts element

LayoutsElement *LayoutsElement::CreateBasicLayoutsElement(void)
{
	LayoutsElement *layoutsElement = new LayoutsElement;
	LayoutElement *layoutElement;
	layoutElement = new LayoutElement(0, 17, kDefaultModifiersName, kANSIKeyMapName);
	layoutsElement->AddLayout(layoutElement);
	layoutElement = new LayoutElement(18, 18, kDefaultModifiersName, kJISKeyMapName);
	layoutsElement->AddLayout(layoutElement);
	layoutElement = new LayoutElement(21, 23, kDefaultModifiersName, kJISKeyMapName);
	layoutsElement->AddLayout(layoutElement);
	layoutElement = new LayoutElement(30, 30, kDefaultModifiersName, kJISKeyMapName);
	layoutsElement->AddLayout(layoutElement);
	layoutElement = new LayoutElement(33, 33, kDefaultModifiersName, kJISKeyMapName);
	layoutsElement->AddLayout(layoutElement);
	layoutElement = new LayoutElement(36, 36, kDefaultModifiersName, kJISKeyMapName);
	layoutsElement->AddLayout(layoutElement);
	layoutElement = new LayoutElement(194, 194, kDefaultModifiersName, kJISKeyMapName);
	layoutsElement->AddLayout(layoutElement);
	layoutElement = new LayoutElement(197, 197, kDefaultModifiersName, kJISKeyMapName);
	layoutsElement->AddLayout(layoutElement);
	layoutElement = new LayoutElement(200, 201, kDefaultModifiersName, kJISKeyMapName);
	layoutsElement->AddLayout(layoutElement);
	layoutElement = new LayoutElement(206, 207, kDefaultModifiersName, kJISKeyMapName);
	layoutsElement->AddLayout(layoutElement);
	return layoutsElement;
}

// Static method to create a layouts element from an XML tree

ErrorMessage LayoutsElement::CreateFromXMLTree(const NXMLNode& inXMLTree,
											   LayoutsElement*& outElement,
											   shared_ptr<XMLCommentContainer> ioCommentContainer)
{
	ErrorMessage errorValue(XMLNoError, "");
	NN_ASSERT(inXMLTree.IsElement(kLayoutsElement));
	outElement = new LayoutsElement;
	NString childValue;
	NString errorString;
	XMLCommentHolder *commentHolder = outElement;
	const NXMLNodeList *childList = inXMLTree.GetChildren();
	for (NXMLNodeListConstIterator pos = childList->begin(); pos != childList->end() && errorValue == XMLNoError; ++pos) {
		const NXMLNode *childTree = *pos;
		switch (childTree->GetType()) {
			case kNXMLNodeElement:
				// An element, which should be a layout element
				childValue = childTree->GetTextValue();
				if (childValue != kLayoutElement) {
					// Not a layout element
					NString errorFormat = NBundleString(kLayoutsElementWrongElementType, "", kErrorTableName);
					errorString.Format(errorFormat, childValue);
					errorValue = ErrorMessage(XMLBadElementTypeError, errorString);
					break;
				}
				LayoutElement *layoutElement;
				errorValue = LayoutElement::CreateFromXMLTree(*childTree, layoutElement);
				if (errorValue == XMLNoError) {
					// Got a valid layout element
					outElement->AddLayout(layoutElement);
					// Deal with comments
					if (commentHolder != NULL) {
						commentHolder->RemoveDuplicateComments();
					}
					commentHolder = layoutElement;
					ioCommentContainer->AddCommentHolder(layoutElement);
				}
			break;
			
			case kNXMLNodeComment: {
				// A comment, so add it to the structure
				XMLComment *childComment = new XMLComment(childTree->GetTextValue(), commentHolder);
				commentHolder->AddXMLComment(childComment);
			}
			break;
			
			default:
				// Invalid node type
				errorString = NBundleString(kLayoutsElementInvalidNodeType, "", kErrorTableName);
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

// Create an XML tree representing the layouts element

NXMLNode *LayoutsElement::CreateXMLTree(void)
{
	NXMLNode *result = new NXMLNode(kNXMLNodeElement, kLayoutsElement);
	AddCommentsToXMLTree(*result);
	LayoutElementList::iterator pos;
	for (pos = mLayoutList.begin(); pos != mLayoutList.end(); ++pos) {
		LayoutElement *layoutElement = *pos;
		// Get the XML tree for the layout element and add it to the tree
		NXMLNode *childTree = layoutElement->CreateXMLTree();
		result->AddChild(childTree);
	}
	return result;
}

NString LayoutsElement::GetDescription(void)
{
	return NString("layouts element");
}

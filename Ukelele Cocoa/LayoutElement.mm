/*
 *  LayoutElement.mm
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "LayoutElement.h"
#include "UkeleleConstants.h"
#include "XMLErrors.h"
#include "UkeleleStrings.h"
#include "NBundle.h"

// Key strings
const NString kLayoutElementMissingFirstAttribute = "LayoutElementMissingFirstAttribute";
const NString kLayoutElementMissingLastAttribute = "LayoutElementMissingLastAttribute";
const NString kLayoutElementMissingModifiersAttribute = "LayoutElementMissingModifiersAttribute";
const NString kLayoutElementMissingMapSetAttribute = "LayoutElementMissingMapSetAttribute";

// Constructor

LayoutElement::LayoutElement(const UInt32 inFirst, const UInt32 inLast, const NString inModifiers, const NString inMapSet)
	: XMLCommentHolder(kLayoutElementType), mFirst(inFirst), mLast(inLast), mModifiers(inModifiers), mMapSet(inMapSet)
{
}

// Copy constructor

LayoutElement::LayoutElement(const LayoutElement& inOriginal)
	: XMLCommentHolder(inOriginal)
{
	mFirst = inOriginal.mFirst;
	mLast = inOriginal.mLast;
	mModifiers = inOriginal.mModifiers;
	mMapSet = inOriginal.mMapSet;
}

// Destructor

LayoutElement::~LayoutElement(void)
{
}

// Static member to create a LayoutElement from XML

ErrorMessage LayoutElement::CreateFromXMLTree(const NXMLNode& inXMLTree, LayoutElement*& outElement)
{
	ErrorMessage errorValue(XMLNoError, "");
	// Check that it is an element node
	NN_ASSERT(inXMLTree.IsType(kNXMLNodeElement));
	// Check that all the attributes are present
	NString errorString;
	NDictionary attributeDictionary = inXMLTree.GetElementAttributes();
	if (!attributeDictionary.HasKey(kFirstAttribute)) {
		errorString = NBundleString(kLayoutElementMissingFirstAttribute, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorString);
	}
	else if (!attributeDictionary.HasKey(kLastAttribute)) {
		errorString = NBundleString(kLayoutElementMissingLastAttribute, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorString);
	}
	else if (!attributeDictionary.HasKey(kModifiersAttribute)) {
		errorString = NBundleString(kLayoutElementMissingModifiersAttribute, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorString);
	}
	else if (!attributeDictionary.HasKey(kMapSetAttribute)) {
		errorString = NBundleString(kLayoutElementMissingMapSetAttribute, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorString);
	}
	else {
		// Get the attributes
		NString firstString = inXMLTree.GetElementAttribute(kFirstAttribute);
		NString lastString = inXMLTree.GetElementAttribute(kLastAttribute);
		NString modifiersString = inXMLTree.GetElementAttribute(kModifiersAttribute);
		NString mapSetString = inXMLTree.GetElementAttribute(kMapSetAttribute);
		NNumber firstNumber(firstString);
		UInt32 firstValue = firstNumber.GetUInt32();
		NNumber lastNumber(lastString);
		UInt32 lastValue = lastNumber.GetUInt32();
		outElement = new LayoutElement(firstValue, lastValue, modifiersString, mapSetString);
	}
	return errorValue;
}

// Create an XML tree representing the LayoutElement

NXMLNode *LayoutElement::CreateXMLTree(void)
{
	// Create the tree
	NXMLNode *xmlTree = new NXMLNode(kNXMLNodeElement, kLayoutElement);
	// Set the attributes
	NString firstString;
	firstString.Format("%d", mFirst);
	xmlTree->SetElementAttribute(kFirstAttribute, firstString);
	NString lastString;
	lastString.Format("%d", mLast);
	xmlTree->SetElementAttribute(kLastAttribute, lastString);
	xmlTree->SetElementAttribute(kModifiersAttribute, mModifiers);
	xmlTree->SetElementAttribute(kMapSetAttribute, mMapSet);
	AddCommentsToXMLTree(*xmlTree);
	return xmlTree;
}

NString LayoutElement::GetDescription(void)
{
	NString descriptionString;
	descriptionString.Format("layout first=%d, last=%d, modifiers=%@, keyMapSet=%@", mFirst, mLast, mModifiers, mMapSet);
	return descriptionString;
}

// Append to a list of comment holders

void LayoutElement::AppendToList(XMLCommentHolderList& ioList)
{
	ioList.push_back(this);
}

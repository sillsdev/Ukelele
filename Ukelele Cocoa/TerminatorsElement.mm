/*
 *  TerminatorsElement.mm
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "TerminatorsElement.h"
#include "UkeleleConstants.h"
#include "XMLErrors.h"
#include "UkeleleStrings.h"
#include "NBundle.h"
#import "NCocoa.h"

	// Key strings
const NString kTerminatorsElementNotWhen = "TerminatorsElementNotWhen";
const NString kTerminatorsElementRepeatedWhen = "TerminatorsElementRepeatedWhen";
const NString kTerminatorsElementInvalidNodeType = "TerminatorsElementInvalidNodeType";
const NString kTerminatorsElementWhenExtraAttributes = "TerminatorsElementWhenExtraAttributes";

	// Constructor

TerminatorsElement::TerminatorsElement(void)
	: XMLCommentHolder(kTerminatorsElementType)
{
	mWhenElementList.reset(new WhenElementSet);
}

	// Copy constructor

TerminatorsElement::TerminatorsElement(const TerminatorsElement& inOriginal)
	: XMLCommentHolder(kTerminatorsElementType), mWhenElementList(new WhenElementSet(*inOriginal.mWhenElementList))
{
}

	// Destructor

TerminatorsElement::~TerminatorsElement(void)
{
}

#pragma mark -

	// AddWhenElement
	//	Add a when element to the set. Returns true if the element
	//	was not already present, false if it was already present.

bool TerminatorsElement::AddWhenElement(WhenElement *inElement)
{
	NN_ASSERT(inElement != NULL);
	return mWhenElementList->AddWhenElement(inElement);
}

	// FindWhenElement
	//	Return the when element with the given state ID

WhenElement *TerminatorsElement::FindWhenElement(NString inStateID) const
{
	return mWhenElementList->FindWhenElement(inStateID);
}

	// GetWhenElementCount
	//	Returns the number of when elements in the set

SInt32 TerminatorsElement::GetWhenElementCount(void) const
{
	return mWhenElementList->GetWhenElementCount();
}

	// GetMaxout
	//	Returns the length of the longest string that can be output from
	//	one of the terminator elements

UInt32 TerminatorsElement::GetMaxout(void) const
{
	UInt32 maxout = 0;
	if (mWhenElementList.get() != NULL) {
		maxout = mWhenElementList->GetMaxout();
	}
	return maxout;
}

	// GetStateNames
	//	Adds all state names to the given set of names

void TerminatorsElement::GetStateNames(NSMutableSet *ioStateNames, const UInt32 inReachable)
{
	mWhenElementList->GetStateNames(ioStateNames, inReachable);
}

	// HasMultiplier
	//	Returns true if any of the when elements has a multiplier attribute

bool TerminatorsElement::HasMultiplier(void) const
{
	return mWhenElementList->HasMultiplier();
}

#pragma mark -

	// ReplaceStateName
	//	Replaces all occurrences of one state name with the new state name

void TerminatorsElement::ReplaceStateName(NString inOldName, NString inNewName)
{
	mWhenElementList->ReplaceStateName(inOldName, inNewName);
}

	// RemoveStates
	//	Removes all when elements with state IDs in the given set

void TerminatorsElement::RemoveStates(NSSet *inStates)
{
	mWhenElementList->RemoveStates(inStates);
}

	// ImportDeadKey
	//	Imports a dead key by creating a new when element with the given local
	//	state name, and the output from the given when element

void TerminatorsElement::ImportDeadKey(NString inLocalState, WhenElement *inWhenElement)
{
	if (inWhenElement != NULL) {
		WhenElement *localElement = new WhenElement(inLocalState, inWhenElement->GetOutput(), "", "", "");
		AddWhenElement(localElement);
	}
}

#pragma mark -

	// CreateFromXMLTree [static]
	//	Factory method to produce a TerminatorsElement from an XML tree. Returns
	//	an error code, XMLNoError if no errors.

ErrorMessage TerminatorsElement::CreateFromXMLTree(const NXMLNode& inTree,
												   TerminatorsElement*& outElement,
												   shared_ptr<XMLCommentContainer> ioCommentContainer)
{
	ErrorMessage errorValue(XMLNoError, "");
	NN_ASSERT(inTree.IsElement(kTerminatorsElement));
	outElement = new TerminatorsElement;
	NString childValue;
	NString errorString;
	NString errorFormat;
	XMLCommentHolder *commentHolder = outElement;
	const NXMLNodeList *childList = inTree.GetChildren();
	for (NXMLNodeListConstIterator pos = childList->begin(); pos != childList->end() && errorValue == XMLNoError; ++pos) {
		const NXMLNode *childTree = *pos;
		switch (childTree->GetType()) {
			case kNXMLNodeElement:
					// An element, which should be a when element
				childValue = childTree->GetTextValue();
				if (childValue != kWhenElement) {
						// Not a when element
					errorFormat = NBundleString(kTerminatorsElementNotWhen, "", kErrorTableName);
					errorString.Format(errorFormat, childValue);
					errorValue = ErrorMessage(XMLBadElementTypeError, errorString);
					break;
				}
				WhenElement *whenElement;
				errorValue = WhenElement::CreateFromXMLTree(*childTree, whenElement);
				if (errorValue == XMLNoError &&
					(whenElement->GetNext() != "" ||
					 whenElement->GetThrough() != "" ||
					 whenElement->GetMultiplier() != "")) {
						// When element does not specify only the output attribute
					errorFormat = NBundleString(kTerminatorsElementWhenExtraAttributes, "", kErrorTableName);
					errorString.Format(errorFormat, whenElement->GetState());
					errorValue = ErrorMessage(XMLTerminatorWhenNotOutputError, errorString);
				}
				if (errorValue == XMLNoError) {
						// Got a valid when element. Check that it's not a repeated one
					if (outElement->AddWhenElement(whenElement)) {
							// Not a repeated element. Deal with comments
						if (commentHolder != NULL) {
							commentHolder->RemoveDuplicateComments();
						}
						commentHolder = whenElement;
						ioCommentContainer->AddCommentHolder(whenElement);
					}
					else {
							// Repeated when element
						errorFormat = NBundleString(kTerminatorsElementRepeatedWhen, "", kErrorTableName);
						errorString.Format(errorFormat, whenElement->GetState());
						errorValue = ErrorMessage(XMLRepeatedWhenElement, errorString);
					}
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
				errorString = NBundleString(kTerminatorsElementInvalidNodeType, "", kErrorTableName);
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

ErrorMessage TerminatorsElement::CreateFromXML(NSXMLElement *inTree, TerminatorsElement *&outElement, boost::shared_ptr<XMLCommentContainer> ioCommentContainer) {
	ErrorMessage errorValue(XMLNoError, "");
	outElement = new TerminatorsElement;
	NString childValue;
	NString errorString;
	NString errorFormat;
	XMLCommentHolder *commentHolder = outElement;
	for (NSXMLNode *childNode in [inTree children]) {
		switch ([childNode kind]) {
			case NSXMLElementKind: {
					// An element, which should be a when element
				childValue = ToNN([childNode name]);
				if (childValue != kWhenElement) {
						// Not a when element
					errorFormat = NBundleString(kTerminatorsElementNotWhen, "", kErrorTableName);
					errorString.Format(errorFormat, childValue);
					errorValue = ErrorMessage(XMLBadElementTypeError, errorString);
					break;
				}
				WhenElement *whenElement;
				errorValue = WhenElement::CreateFromXMLTree((NSXMLElement *)childNode, whenElement);
				if (errorValue == XMLNoError &&
					(whenElement->GetNext() != "" ||
					 whenElement->GetThrough() != "" ||
					 whenElement->GetMultiplier() != "")) {
						// When element does not specify only the output attribute
					errorFormat = NBundleString(kTerminatorsElementWhenExtraAttributes, "", kErrorTableName);
					errorString.Format(errorFormat, whenElement->GetState());
					errorValue = ErrorMessage(XMLTerminatorWhenNotOutputError, errorString);
				}
				if (errorValue == XMLNoError) {
						// Got a valid when element. Check that it's not a repeated one
					if (outElement->AddWhenElement(whenElement)) {
							// Not a repeated element. Deal with comments
						if (commentHolder != NULL) {
							commentHolder->RemoveDuplicateComments();
						}
						commentHolder = whenElement;
						ioCommentContainer->AddCommentHolder(whenElement);
					}
					else {
							// Repeated when element
						errorFormat = NBundleString(kTerminatorsElementRepeatedWhen, "", kErrorTableName);
						errorString.Format(errorFormat, whenElement->GetState());
						errorValue = ErrorMessage(XMLRepeatedWhenElement, errorString);
					}
				}
			}
			break;
				
			case NSXMLCommentKind: {
					// A comment, so add it to the structure
				childValue = ToNN([childNode stringValue]);
				XMLComment *childComment = new XMLComment(childValue, commentHolder);
				commentHolder->AddXMLComment(childComment);
			}
			break;
				
			default:
					// Invalid node type
				errorString = NBundleString(kTerminatorsElementInvalidNodeType, "", kErrorTableName);
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

	// CreateXMLTree
	//	Create an XML tree for the terminators element

NXMLNode *TerminatorsElement::CreateXMLTree(void)
{
	NXMLNode *xmlTree = new NXMLNode(kNXMLNodeElement, kTerminatorsElement);
	AddCommentsToXMLTree(*xmlTree);
	for (WhenElement *whenElement = mWhenElementList->GetFirstWhenElement();
		 whenElement != NULL; whenElement = mWhenElementList->GetNextWhenElement()) {
		NXMLNode *whenElementTree = whenElement->CreateXMLTree();
		xmlTree->AddChild(whenElementTree);
		whenElement->AddCommentsToXMLTree(*xmlTree);
	}
	return xmlTree;
}

NSXMLElement *TerminatorsElement::CreateXML(void) {
	NSXMLElement *xmlTree = [NSXMLElement elementWithName:ToNS(kTerminatorsElement)];
	AddCommentsToXML(xmlTree);
	for (WhenElement *whenElement = mWhenElementList->GetFirstWhenElement(); whenElement != NULL; whenElement = mWhenElementList->GetNextWhenElement()) {
		NSXMLElement *whenElementTree = whenElement->CreateXMLNode();
		[xmlTree addChild:whenElementTree];
		whenElement->AddCommentsToXML(xmlTree);
	}
	return xmlTree;
}

NString TerminatorsElement::GetDescription(void)
{
	return NString("terminators element");
}

	// Append to list of comment holders

void TerminatorsElement::AppendToList(XMLCommentHolderList& ioList)
{
	ioList.push_back(this);
	mWhenElementList->AppendToList(ioList);
}

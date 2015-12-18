/*
 *  WhenElement.cpp
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "WhenElement.h"
#include "UkeleleConstants.h"
#include "UkeleleStrings.h"
#include "NBundle.h"
#include "XMLErrors.h"
#include "NCocoa.h"
#include "XMLUtilities.h"
#include "boost/scoped_array.hpp"
#include "NSystemUtilities.h"

	
// Key strings
const NString kWhenElementMissingState = "WhenElementMissingState";

	// Default constructor

WhenElement::WhenElement(void)
: XMLCommentHolder(kWhenElementType), mState(""), mOutput(""), mNext(""), mNextInteger(0),
mThrough(""), mThroughInteger(0), mMultiplier(""), mMultiplierInteger(0)
{
}

	// Parameterised constructor

WhenElement::WhenElement(NString inState, NString inOutput, NString inNext, NString inThrough, NString inMultiplier)
: XMLCommentHolder(kWhenElementType), mState(inState), mOutput(inOutput), mNext(inNext),
mThrough(inThrough), mMultiplier(inMultiplier)
{
	if (mNext.IsEmpty()) {
		mNextInteger = 0;
	}
	else {
		mNextInteger = NSystemUtilities::GetInt32(mNext);
	}
	if (mThrough.IsEmpty()) {
		mThroughInteger = 0;
	}
	else {
		mThroughInteger = NSystemUtilities::GetInt32(mThrough);
	}
	if (mMultiplier.IsEmpty()) {
		mMultiplierInteger = 0;
	}
	else {
		mMultiplierInteger = NSystemUtilities::GetInt32(mMultiplier);
	}
	if (!mOutput.IsEmpty()) {
		mOutput = XMLUtilities::ConvertEncodedString(inOutput);
	}
}

	// Copy constructor

WhenElement::WhenElement(const WhenElement& inOriginal)
: XMLCommentHolder(inOriginal), mState(inOriginal.mState), mOutput(inOriginal.mOutput),
mNext(inOriginal.mNext), mNextInteger(inOriginal.mNextInteger),
mThrough(inOriginal.mThrough), mThroughInteger(inOriginal.mThroughInteger),
mMultiplier(inOriginal.mMultiplier), mMultiplierInteger(inOriginal.mMultiplierInteger)
{
}

	// Destructor

WhenElement::~WhenElement(void)
{
}

#pragma mark -
#pragma mark === Set values ===

	// Set output string

void
WhenElement::SetOutput(NString inNewOutput)
{
	mOutput = inNewOutput;
}

	// Set Next string

void
WhenElement::SetNext(NString inNewNext)
{
	mNext = inNewNext;
	NNumber nextNumber(mNext);
	mNextInteger = nextNumber.GetUInt32();
}

	// Set Through string

void
WhenElement::SetThrough(NString inNewThrough)
{
	mThrough = inNewThrough;
	NNumber throughNumber(mThrough);
	mThroughInteger = throughNumber.GetUInt32();
}

	// Set Multiplier string

void
WhenElement::SetMultiplier(NString inNewMultiplier)
{
	mMultiplier = inNewMultiplier;
	NNumber multiplierNumber(mMultiplier);
	mMultiplierInteger = multiplierNumber.GetUInt32();
}

#pragma mark -

	// Get maximum output length

UInt32
WhenElement::GetMaxout(void) const
{
	UInt32 maxout = 0;
	if (mOutput.IsEmpty()) {
		maxout = 0;
	}
	else {
			// Convert string from possibly encoded value
		UInt32 stringLength = mOutput.GetSize();
		boost::scoped_array<UniChar> buffer(new UniChar(2 * (UInt16)stringLength));
		XMLUtilities::ConvertEncodedString(mOutput, buffer.get(), stringLength);
		maxout = stringLength;
	}
	return maxout;
}

	// Replace a state name

void
WhenElement::ReplaceStateName(NString inOldName, NString inNewName)
{
	if (mState == inOldName) {
		mState = inNewName;
	}
	if (mNext == inOldName) {
		mNext = inNewName;
	}
}

#pragma mark -
#pragma mark === Convert to and from XML ===

	// CreateFromXMLTree: Create a when element from an XML tree

ErrorMessage
WhenElement::CreateFromXMLTree(const NXMLNode& inTree, WhenElement*& outElement)
{
	ErrorMessage errorValue(XMLNoError, "");
		// Check that it is an element node
	NN_ASSERT(inTree.IsType(kNXMLNodeElement));
		// Check for errors
	NDictionary attributeDictionary = inTree.GetElementAttributes();
	if (!attributeDictionary.HasKey(kStateAttribute)) {
			// No state attribute
		NString errorString = NBundleString(kWhenElementMissingState, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorString);
		return errorValue;
	}
		// Get the attributes
	NString state = inTree.GetElementAttribute(kStateAttribute);
	NString output = inTree.GetElementAttribute(kOutputAttribute);
	NString next = inTree.GetElementAttribute(kNextAttribute);
	NString through = inTree.GetElementAttribute(kThroughAttribute);
	NString multiplier = inTree.GetElementAttribute(kMultiplierAttribute);
	outElement = new WhenElement(state, output, next, through, multiplier);
	return errorValue;
}

ErrorMessage
WhenElement::CreateFromXMLTree(NSXMLElement *inTree, WhenElement *&outElement) {
	ErrorMessage errorValue(XMLNoError, "");
	NSXMLNode *attributeNode = [inTree attributeForName:ToNS(kStateAttribute)];
	if (attributeNode == nil) {
			// No state attribute
		NString errorString = NBundleString(kWhenElementMissingState, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorString);
		return errorValue;
	}
		// Get the attributes
	NString state = ToNN([attributeNode stringValue]);
	NString output;
	attributeNode = [inTree attributeForName:ToNS(kOutputAttribute)];
	if (attributeNode != nil) {
		output = ToNN([attributeNode stringValue]);
	}
	NString next;
	attributeNode = [inTree attributeForName:ToNS(kNextAttribute)];
	if (attributeNode != nil) {
		next = ToNN([attributeNode stringValue]);
	}
	NString through;
	attributeNode = [inTree attributeForName:ToNS(kThroughAttribute)];
	if (attributeNode != nil) {
		through = ToNN([attributeNode stringValue]);
	}
	NString multiplier;
	attributeNode = [inTree attributeForName:ToNS(kMultiplierAttribute)];
	if (attributeNode != nil) {
		multiplier = ToNN([attributeNode stringValue]);
	}
	outElement = new WhenElement(state, output, next, through, multiplier);
	return errorValue;
}

	// CreateXMLTree: Construct an XML tree encapsulating the when element

NXMLNode *
WhenElement::CreateXMLTree(void)
{
		// Create the tree
	NXMLNode *xmlTree = new NXMLNode(kNXMLNodeElement, kWhenElement);
	xmlTree->SetElementUnpaired(true);
		// Set the attributes
	xmlTree->SetElementAttribute(kStateAttribute, XMLUtilities::ConvertToXMLString(mState));
	if (!mOutput.IsEmpty() || mNext.IsEmpty()) {
		xmlTree->SetElementAttribute(kOutputAttribute, XMLUtilities::ConvertToXMLString(mOutput));
	}
	if (!mNext.IsEmpty()) {
		xmlTree->SetElementAttribute(kNextAttribute, XMLUtilities::ConvertToXMLString(mNext));
	}
	if (!mThrough.IsEmpty()) {
		xmlTree->SetElementAttribute(kThroughAttribute, XMLUtilities::ConvertToXMLString(mThrough));
	}
	if (!mMultiplier.IsEmpty()) {
		xmlTree->SetElementAttribute(kMultiplierAttribute, XMLUtilities::ConvertToXMLString(mMultiplier));
	}
	return xmlTree;
}

NSXMLElement *
WhenElement::CreateXMLNode(void) {
	NSXMLElement *theNode = [[NSXMLElement alloc] initWithName:ToNS(kWhenElement)];
		// Set the attributes
	NSXMLNode *attributeNode = [NSXMLNode attributeWithName:ToNS(kStateAttribute) stringValue:ToNS(XMLUtilities::ConvertToXMLString(mState))];
	[theNode addAttribute:attributeNode];
	if (!mOutput.IsEmpty() || mNext.IsEmpty()) {
		attributeNode = [NSXMLNode attributeWithName:ToNS(kOutputAttribute) stringValue:ToNS(XMLUtilities::ConvertToXMLString(mOutput))];
		[theNode addAttribute:attributeNode];
	}
	if (!mNext.IsEmpty()) {
		attributeNode = [NSXMLNode attributeWithName:ToNS(kNextAttribute) stringValue:ToNS(XMLUtilities::ConvertToXMLString(mNext))];
		[theNode addAttribute:attributeNode];
	}
	if (!mThrough.IsEmpty()) {
		attributeNode = [NSXMLNode attributeWithName:ToNS(kThroughAttribute) stringValue:ToNS(XMLUtilities::ConvertToXMLString(mThrough))];
		[theNode addAttribute:attributeNode];
	}
	if (!mMultiplier.IsEmpty()) {
		attributeNode = [NSXMLNode attributeWithName:ToNS(kMultiplierAttribute) stringValue:ToNS(XMLUtilities::ConvertToXMLString(mMultiplier))];
		[theNode addAttribute:attributeNode];
	}
	return theNode;
}

NString WhenElement::GetDescription(void)
{
	NString descriptionString;
	descriptionString.Format("when state=%@", mState);
	if (!mOutput.IsEmpty()) {
		descriptionString += ", output=\"";
		descriptionString += mOutput;
		descriptionString += "\"";
	}
	if (!mNext.IsEmpty()) {
		descriptionString += ", next=";
		descriptionString += mNext;
	}
	if (!mThrough.IsEmpty()) {
		descriptionString += ", through=";
		descriptionString += mThrough;
	}
	if (!mMultiplier.IsEmpty()) {
		descriptionString += ", multiplier=";
		descriptionString += mMultiplier;
	}
	return descriptionString;
}

#pragma mark === Operators ===

	// Operator<

bool
WhenElement::operator<(const WhenElement& inCompareTo)
{
	return mState < inCompareTo.mState;
}

	// Operator==

bool
WhenElement::operator==(const WhenElement& inCompareTo)
{
	return mState == inCompareTo.mState;
}

	// Assignment

void
WhenElement::operator=(const WhenElement& inNew)
{
	mState = inNew.mState;
	mOutput = inNew.mOutput;
	mNext = inNew.mNext;
	mNextInteger = inNew.mNextInteger;
	mThrough = inNew.mThrough;
	mThroughInteger = inNew.mThroughInteger;
	mMultiplier = inNew.mMultiplier;
	mMultiplierInteger = inNew.mMultiplierInteger;
}

#pragma mark -
#pragma mark --- WhenElementSet ---

	// Default constructor

WhenElementSet::WhenElementSet(void)
{
	mIterator = mElementSet.end();
}

	// Copy constructor

WhenElementSet::WhenElementSet(const WhenElementSet& inOriginal)
{
	if (!inOriginal.mElementSet.empty()) {
		WhenElementSetIterator orig;
		for (orig = inOriginal.mElementSet.begin(); orig != inOriginal.mElementSet.end(); ++orig) {
			AddWhenElement(new WhenElement(**orig));
		}
	}
	mIterator = mElementSet.end();
}

	// Destructor

WhenElementSet::~WhenElementSet(void)
{
	if (!mElementSet.empty()) {
		WhenElementSetIterator pos;
		for (pos = mElementSet.begin(); pos != mElementSet.end(); ++pos) {
			WhenElement *element = *pos;
			delete element;
		}
	}
}

#pragma mark -

	// Add an element to the set. Returns true if the element is added,
	// false if there was already an element with that state

bool
WhenElementSet::AddWhenElement(WhenElement *inElement)
{
	std::pair<WhenElementSetIterator, bool> result = mElementSet.insert(inElement);
	return result.second;
}

	// Find an element

WhenElement *
WhenElementSet::FindWhenElement(NString inState)
{
	if (!mElementSet.empty()) {
		NString emptyString("");
		WhenElement keyElement(inState, emptyString, emptyString, emptyString, emptyString);
		WhenElementSetIterator pos = mElementSet.find(&keyElement);
		if (pos != mElementSet.end()) {
			return *pos;
		}
	}
	return NULL;
}

	// Delete an element

void
WhenElementSet::DeleteWhenElement(NString inState)
{
	if (!mElementSet.empty()) {
		NString emptyString("");
		WhenElement keyElement(inState, emptyString, emptyString, emptyString, emptyString);
		WhenElementSetIterator pos = mElementSet.find(&keyElement);
		if (pos != mElementSet.end()) {
			WhenElement *elementToDelete = *pos;
			mElementSet.erase(elementToDelete);
			delete elementToDelete;
			mIterator = mElementSet.end();
		}
	}
}

#pragma mark -

	// Tests whether any element has a multiplier attribute

bool
WhenElementSet::HasMultiplier(void)
{
	bool result = false;
	for (WhenElementSetIterator pos = mElementSet.begin(); pos != mElementSet.end(); ++pos) {
		WhenElement *whenElement = *pos;
		if (!whenElement->GetMultiplier().IsEmpty()) {
			result = true;
			break;
		}
	}
	return result;
}

	// Get the maxout

UInt32
WhenElementSet::GetMaxout(void) const
{
	UInt32 maxout = 0;
	for (WhenElementSetIterator pos = mElementSet.begin(); pos != mElementSet.end(); ++pos) {
		WhenElement *whenElement = *pos;
		UInt32 elementMaxout = whenElement->GetMaxout();
		if (elementMaxout > maxout) {
			maxout = elementMaxout;
		}
	}
	return maxout;
}

#pragma mark -

	// Get all the state names referenced by the elements

void
WhenElementSet::GetStateNames(NSMutableSet *ioStateNames, const UInt32 inReachable)
{
	for (WhenElementSetIterator pos = mElementSet.begin(); pos != mElementSet.end(); ++pos) {
		WhenElement *whenElement = *pos;
		NString stateName;
		if (inReachable == kAllStates) {
			stateName = whenElement->GetState();
			[ioStateNames addObject:ToNS(stateName)];
		}
		stateName = whenElement->GetNext();
		if (!stateName.IsEmpty()) {
			[ioStateNames addObject:ToNS(stateName)];
		}
	}
}

	// Change all occurrences of a given state name

void
WhenElementSet::ReplaceStateName(NString oldStateName, NString newStateName)
{
		// Replace an element with the old state name as its state attribute
	WhenElement *element = FindWhenElement(oldStateName);
	if (element != NULL) {
		SInt32 numRemoved = static_cast<SInt32>(mElementSet.erase(element));
		NN_ASSERT(numRemoved == 1);
		element->ReplaceStateName(oldStateName, newStateName);
		mElementSet.insert(element);
	}
		// Replace all other occurrences of the old state name
	for (WhenElementSetIterator pos = mElementSet.begin(); pos != mElementSet.end(); ++pos) {
		element = *pos;
		element->ReplaceStateName(oldStateName, newStateName);
	}
}

	// Remove elements with the given states

void
WhenElementSet::RemoveStates(NSSet *inStates)
{
		// Create a set of states that need to be deleted
	WhenElementSetType statesToDelete;
	WhenElementSetIterator pos;
	WhenElement *whenElement;
	for (pos = mElementSet.begin(); pos != mElementSet.end(); ++pos) {
		whenElement = *pos;
		const NString stateName = whenElement->GetState();
		if ([inStates containsObject:ToNS(stateName)]) {
			std::pair<std::set<WhenElement *, DereferenceLess>::iterator, bool> result =
			statesToDelete.insert(whenElement);
			NN_ASSERT(result.second);
		}
	}
		// Now run through the set of states and delete them
	for (pos = statesToDelete.begin(); pos != statesToDelete.end(); ++pos) {
		whenElement = *pos;
		mElementSet.erase(whenElement);
		delete whenElement;
	}
}

#pragma mark -

	// Add each element to an XML tree

void
WhenElementSet::AddToXMLTree(NXMLNode& inTree)
{
	WhenElement keyElement(kStateNone, "", "", "", "");
	WhenElementSetIterator pos = mElementSet.find(&keyElement);
	if (pos != mElementSet.end()) {
		WhenElement *noneElement = *pos;
			// Get the XML tree for the when element and add it
		NXMLNode *noneTree = noneElement->CreateXMLTree();
		inTree.AddChild(noneTree);
			// Add comments (deleting duplicates on the fly)
		noneElement->RemoveDuplicateComments();
		noneElement->AddCommentsToXMLTree(inTree);
	}
	for (pos = mElementSet.begin(); pos != mElementSet.end(); ++pos) {
		WhenElement *whenElement = *pos;
		if (whenElement->GetState() != kStateNone) {
				// Get the XML tree for the when element and add it
			NXMLNode *childTree = whenElement->CreateXMLTree();
			inTree.AddChild(childTree);
				// Add comments (deleting duplicates on the fly)
			whenElement->RemoveDuplicateComments();
			whenElement->AddCommentsToXMLTree(inTree);
		}
	}
}

void
WhenElementSet::AddToXML(NSXMLElement *inTree) {
	WhenElement keyElement(kStateNone, "", "", "", "");
	WhenElementSetIterator pos = mElementSet.find(&keyElement);
	if (pos != mElementSet.end()) {
		WhenElement *noneElement = *pos;
			// Get the XML tree for the when element and add it
		NSXMLElement *xmlElement = noneElement->CreateXMLNode();
		[inTree addChild:xmlElement];
			// Add comments (deleting duplicates on the fly)
		noneElement->RemoveDuplicateComments();
		noneElement->AddCommentsToXML(inTree);
	}
	for (pos = mElementSet.begin(); pos != mElementSet.end(); ++pos) {
		WhenElement *whenElement = *pos;
		if (whenElement->GetState() != kStateNone) {
				// Get the XML tree for the when element and add it
			[inTree addChild:whenElement->CreateXMLNode()];
				// Add comments (deleting duplicates on the fly)
			whenElement->RemoveDuplicateComments();
			whenElement->AddCommentsToXML(inTree);
		}
	}
}

#pragma mark -
#pragma mark === Iterator functions ===

	// Get the first when element

WhenElement *
WhenElementSet::GetFirstWhenElement(void)
{
	mIterator = mElementSet.begin();
	if (mIterator != mElementSet.end()) {
		return *mIterator;
	}
	else {
		return NULL;
	}
}

	// Get the next when element

WhenElement *
WhenElementSet::GetNextWhenElement(void)
{
	if (++mIterator != mElementSet.end()) {
		return *mIterator;
	}
	else {
		return NULL;
	}
}

	// Append to a list of comment holders

void WhenElementSet::AppendToList(XMLCommentHolderList& ioList)
{
	for (WhenElementSetIterator pos = mElementSet.begin(); pos != mElementSet.end(); ++pos) {
		ioList.push_back(*pos);
	}
}

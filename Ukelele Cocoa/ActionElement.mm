/*
 *  ActionElement.mm
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "ActionElement.h"
#include "UkeleleConstants.h"
#include "XMLErrors.h"
#include "XMLUtilities.h"
#include "NBundle.h"

	// Strings
const NString kActionsElementWrongElementType = "ActionsElementWrongElementType";
const NString kActionsElementInvalidNodeType = "ActionsElementInvalidNodeType";
const NString kActionElementMissingIDAttribute = "ActionElementMissingIDAttribute";
const NString kActionElementNotWhenElement = "ActionElementNotWhenElement";
const NString kActionElementRepeatedWhenElement = "ActionElementRepeatedWhenElement";
const NString kActionElementInvalidNodeType = "ActionElementInvalidNodeType";
const NString kActionElementEmpty = "ActionElementEmpty";
const NString kActionSetRepeatedAction = "ActionSetRepeatedAction";

	// Default constructor

ActionElement::ActionElement(void)
: XMLCommentHolder(kActionElementType), mActionID("")
{
	mWhenElementSet.reset(new WhenElementSet);
}

	// Constructor with an ID

ActionElement::ActionElement(NString inActionID)
: XMLCommentHolder(kActionElementType), mActionID(inActionID)
{
		//	NN_ASSERT(inActionID.IsNotEmpty());
	mWhenElementSet.reset(new WhenElementSet);
}

	// Copy constructor

ActionElement::ActionElement(const ActionElement& inOriginal)
: XMLCommentHolder(inOriginal)
{
	mActionID = inOriginal.mActionID;
	mWhenElementSet.reset(new WhenElementSet(*inOriginal.mWhenElementSet.get()));
}

	// Destructor

ActionElement::~ActionElement(void)
{
}

#pragma mark -

	// Set the action's ID

void ActionElement::SetActionID(NString inNewID)
{
	mActionID = inNewID;
}

	// Add a when element. Returns true if the when element was successfully
	// added, false if there was already a when element with the same state
	// name present.

bool ActionElement::AddWhenElement(WhenElement *inWhenElement)
{
	return mWhenElementSet->AddWhenElement(inWhenElement);
}

	// Find a when element with the given state name

WhenElement *ActionElement::FindWhenElement(const NString inStateID) const
{
	return mWhenElementSet->FindWhenElement(inStateID);
}

	// Delete a when element

void ActionElement::DeleteWhenElement(const NString inStateID)
{
	mWhenElementSet->DeleteWhenElement(inStateID);
}

#pragma mark -

	// Get the action type

UInt16 ActionElement::GetActionType(const NString inStateID) const
{
	WhenElement *whenElement = FindWhenElement(inStateID);
	if (whenElement == NULL) {
			// No when element means that we will produce the terminator
		return kActionTypeTerminator;
	}
	NString actionOutput = whenElement->GetOutput();
	if (!whenElement->GetNext().IsEmpty()) {
		if (actionOutput.IsEmpty()) {
				// Valid next but no output means a state transition
			return kActionTypeState;
		}
	}
	return kActionTypeOutput;
}

	// Does any of the when elements have a multiplier attribute?

bool ActionElement::HasMultiplierElement(void) const
{
	return mWhenElementSet->HasMultiplier();
}

	// Return the maximum length of an output string

UInt32 ActionElement::GetMaxout(void) const
{
	return mWhenElementSet->GetMaxout();
}

	// Return the number of when elements in this action element

SInt32 ActionElement::GetWhenElementCount(void) const
{
	return mWhenElementSet->GetWhenElementCount();
}

#pragma mark -

	// Add all state names to the given set

void ActionElement::GetStateNames(NSMutableSet *ioStateNames, const UInt32 inReachable)
{
	mWhenElementSet->GetStateNames(ioStateNames, inReachable);
}

	// Replace all instances of a given state name by a new name

void ActionElement::ReplaceStateName(const NString inOldName, const NString inNewName)
{
	mWhenElementSet->ReplaceStateName(inOldName, inNewName);
}

	// Remove all states in the given set

void ActionElement::RemoveStates(NSSet *inStates)
{
	mWhenElementSet->RemoveStates(inStates);
}

#pragma mark -

	// Static member to create an action element from an XML tree

ErrorMessage ActionElement::CreateFromXMLTree(const NXMLNode& inTree,
											  ActionElement*& outElement,
											  shared_ptr<XMLCommentContainer> ioCommentContainer)
{
	ErrorMessage errorValue(XMLNoError, "");
	NString errorString;
	NString errorFormat;
	NN_ASSERT(inTree.IsElement(kActionElement));
	NDictionary attributeDictionary = inTree.GetElementAttributes();
	if (!attributeDictionary.HasKey(kIDAttribute)) {
		errorString = NBundleString(kActionElementMissingIDAttribute, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorString);
		return errorValue;
	}
	NString actionID = inTree.GetElementAttribute(kIDAttribute);
	
	outElement = new ActionElement(actionID);
	XMLCommentHolder *commentHolder = outElement;
	const NXMLNodeList *childNodes = inTree.GetChildren();
	for (NXMLNodeListConstIterator pos = childNodes->begin(); pos != childNodes->end() && errorValue == XMLNoError; ++pos) {
		NXMLNode *childTree = *pos;
		switch (childTree->GetType()) {
			case kNXMLNodeElement:
					// An element, which should be a when element
				if (childTree->GetTextValue() != kWhenElement) {
					errorFormat = NBundleString(kActionElementNotWhenElement, "", kErrorTableName);
					errorString.Format(errorFormat, actionID, childTree->GetTextValue());
					errorValue = ErrorMessage(XMLBadElementTypeError, errorString);
					break;
				}
				WhenElement *whenElement;
				errorValue = WhenElement::CreateFromXMLTree(*childTree, whenElement);
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
						errorFormat = NBundleString(kActionElementRepeatedWhenElement, "", kErrorTableName);
						errorString.Format(errorFormat, actionID, whenElement->GetState());
						errorValue = ErrorMessage(XMLRepeatedWhenElement, errorString);
					}
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
				errorFormat = NBundleString(kActionElementInvalidNodeType, "", kErrorTableName);
				errorString.Format(errorFormat, actionID);
				errorValue = ErrorMessage(XMLWrongXMLNodeTypeError, errorString);
				break;
		}
	}
	if (errorValue == XMLNoError && outElement->mWhenElementSet->GetWhenElementCount() == 0) {
			// Empty action element
		errorFormat = NBundleString(kActionElementEmpty, "", kErrorTableName);
		errorString.Format(errorFormat, actionID);
		errorValue = ErrorMessage(XMLEmptyActionElementError, errorString);
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

	// Create an XML tree to represent the action element

NXMLNode *ActionElement::CreateXMLTree(const bool inCodeNonAscii)
{
	NXMLNode *xmlTree = new NXMLNode(kNXMLNodeElement, kActionElement);
	xmlTree->SetElementAttribute(kIDAttribute, XMLUtilities::ConvertToXMLString(mActionID, inCodeNonAscii));
	WhenElement *stateNoneElement = mWhenElementSet->FindWhenElement(kStateNone);
	if (stateNoneElement == NULL) {
			// No element for state none: create one
		stateNoneElement = new WhenElement(kStateNone, "", "", "", "");
		mWhenElementSet->AddWhenElement(stateNoneElement);
	}
	NXMLNode *stateNoneElementTree = stateNoneElement->CreateXMLTree(inCodeNonAscii);
	xmlTree->AddChild(stateNoneElementTree);
	stateNoneElement->AddCommentsToXMLTree(*xmlTree);
	for (WhenElement *whenElement = mWhenElementSet->GetFirstWhenElement();
		 whenElement != NULL; whenElement = mWhenElementSet->GetNextWhenElement()) {
		if (whenElement->GetState() != kStateNone) {
			NXMLNode *whenElementTree = whenElement->CreateXMLTree(inCodeNonAscii);
			xmlTree->AddChild(whenElementTree);
			whenElement->AddCommentsToXMLTree(*xmlTree);
		}
	}
	return xmlTree;
}

NString ActionElement::GetDescription(void)
{
	NString descriptionString;
	descriptionString.Format("action id=%@", mActionID);
	return descriptionString;
}

	// Append to list of comment holders

void ActionElement::AppendToList(XMLCommentHolderList& ioList)
{
	ioList.push_back(this);
	mWhenElementSet->AppendToList(ioList);
}

#pragma mark -

	// Comparison operator <

bool ActionElement::operator<(const ActionElement& inCompareTo) const
{
	return mActionID.Compare(inCompareTo.mActionID, kCFCompareNumerically) == kNCompareLessThan;
}

	// Comparison operator ==

bool ActionElement::operator==(const ActionElement& inCompareTo) const
{
	return mActionID == inCompareTo.mActionID;
}

	// Assignment operator

void ActionElement::operator=(const ActionElement& inOriginal)
{
	mActionID = inOriginal.mActionID;
	mWhenElementSet.reset(new WhenElementSet(*inOriginal.mWhenElementSet.get()));
}

#pragma mark === ActionElementSet ===

	// Constructor

ActionElementSet::ActionElementSet(void)
: XMLCommentHolder(kActionElementSetType)
{
}

	// Copy constructor

ActionElementSet::ActionElementSet(const ActionElementSet& inOriginal)
: XMLCommentHolder(inOriginal)
{
	if (inOriginal.mActionElementSet.empty()) {
		return;
	}
	std::set<ActionElement *, DereferenceLess>::iterator theIterator;
	for (theIterator = inOriginal.mActionElementSet.begin();
		 theIterator != inOriginal.mActionElementSet.end(); ++theIterator) {
		Boolean result = AddActionElement(new ActionElement(**theIterator));
		assert(result);
	}
	mIterator = mActionElementSet.end();
}

	// Destructor

ActionElementSet::~ActionElementSet(void)
{
	if (!mActionElementSet.empty()) {
		for (mIterator = mActionElementSet.begin();
			 mIterator != mActionElementSet.end(); ++mIterator) {
			ActionElement *actionElement = *mIterator;
			if (actionElement != NULL) {
				delete actionElement;
			}
		}
	}
}

#pragma mark -

	// Add an action element to the set

Boolean ActionElementSet::AddActionElement(ActionElement *inActionElement)
{
	std::pair<std::set<ActionElement *, DereferenceLess>::iterator, bool> result =
	mActionElementSet.insert(inActionElement);
//	assert(result.second);
	mIterator = mActionElementSet.end();
	return result.second;
}

	// Find an action with the given ID

ActionElement *ActionElementSet::FindActionElement(const NString inActionID) const
{
	if (!mActionElementSet.empty()) {
		ActionElement keyElement(inActionID);
		std::set<ActionElement *, DereferenceLess>::iterator pos =
		mActionElementSet.find(&keyElement);
		if (pos != mActionElementSet.end()) {
			return *pos;
		}
	}
	return NULL;
}

	// Remove the action element with the given ID, returning that element

ActionElement *ActionElementSet::RemoveActionElement(const NString inActionID)
{
	ActionElement *actionElement = NULL;
	if (!mActionElementSet.empty()) {
		ActionElement keyElement(inActionID);
		std::set<ActionElement *, DereferenceLess>::iterator pos =
		mActionElementSet.find(&keyElement);
		if (pos != mActionElementSet.end()) {
			actionElement = *pos;
			mActionElementSet.erase(pos);
		}
	}
	mIterator = mActionElementSet.end();
	return actionElement;
}

	// Return whether there is an action present with the given ID

bool ActionElementSet::ActionExists(const NString inActionID) const
{
	return FindActionElement(inActionID) != NULL;
}

	// Remove all action elements

void ActionElementSet::Clear(void)
{
	mActionElementSet.clear();
}

	// Return whether there are any action elements

bool ActionElementSet::IsEmpty(void) const
{
	return mActionElementSet.empty();
}

#pragma mark -

	// Create a duplicate action element to the one with a given ID, with
	// a unique ID

ActionElement *ActionElementSet::CreateDuplicateActionElement(const NString inActionID)
{
	NString baseString;
	UInt32 suffixValue;
	NString digitString("[0-9]+$");
	NRange numberRange = inActionID.Find(digitString, kNStringPattern);
	if (numberRange != kNRangeNone) {
			// The given action ID ends with a number
			// Find the number at the end
		NString numberString = inActionID.GetString(numberRange);
		NNumber numberNumber(numberString);
		int32_t numberValue = numberNumber.GetInt32();
		if (numberValue == INT_MAX) {
				// Number is too big
			baseString = inActionID + " ";
			suffixValue = 1;
		}
		else {
				// Extract the portion without the number
			NRange baseRange(0, numberRange.GetLocation());
			baseString = inActionID.GetString(baseRange);
				// Set the start suffix to be one more than the number
			suffixValue = numberValue + 1;
		}
	}
	else {
			// The given action ID does not end with a number
		baseString = inActionID + " ";
		suffixValue = 1;
	}
		// Get a unique name from the base string and suffix
	NString candidateName = GetUniqueActionName(baseString, suffixValue);
		// Duplicate the action
	ActionElement *originalAction = FindActionElement(inActionID);
	ActionElement *duplicateAction = new ActionElement(*originalAction);
		// Make the duplicate's name the new name
	duplicateAction->SetActionID(candidateName);
		// Add it to the set
	Boolean result = AddActionElement(duplicateAction);
	assert(result);
	return duplicateAction;
}

	// Create a new action name based on a given string

NString ActionElementSet::MakeActionName(const NString inBaseName)
{
	NString baseName = inBaseName;
	if (baseName.IsEmpty()) {
		baseName = "action";
	}
	NString actionName = XMLUtilities::ConvertToXMLString(baseName, false);
	if (FindActionElement(actionName) != NULL) {
			// The name was taken, so create a unique name
		NString baseString = actionName + " ";
		actionName = GetUniqueActionName(baseString, 1);
	}
	return actionName;
}

#pragma mark -

	// Get the maximum length of output for the action elements in the set

UInt32 ActionElementSet::GetMaxout(void) const
{
	UInt32 maxout = 0;
		// For each action element
	std::set<ActionElement *, DereferenceLess>::iterator elementIter;
	for (elementIter = mActionElementSet.begin();
		 elementIter != mActionElementSet.end(); ++elementIter) {
			// Get its maximum output length
		ActionElement *actionElement = *elementIter;
		UInt32 elementMaxout = actionElement->GetMaxout();
			// If it is greater than the current maxout, update maxout
		if (elementMaxout > maxout) {
			maxout = elementMaxout;
		}
	}
	return maxout;
}

	// Return true if any of the action elements has a multiplier element

bool ActionElementSet::HasMultiplierAction(void) const
{
	if (!mActionElementSet.empty()) {
		std::set<ActionElement *, DereferenceLess>::iterator elementIter;
		for (elementIter = mActionElementSet.begin();
			 elementIter != mActionElementSet.end(); ++elementIter) {
			ActionElement *actionElement = *elementIter;
			if (actionElement->HasMultiplierElement()) {
				return true;
			}
		}
	}
	return false;
}

	// Return an array containing the names of all actions in the set

NArray ActionElementSet::GetActionNames(void) const
{
	NArray actionNames;
	std::set<ActionElement *, DereferenceLess>::iterator elementIter;
	for (elementIter = mActionElementSet.begin();
		 elementIter != mActionElementSet.end(); ++elementIter) {
		ActionElement *actionElement = *elementIter;
		actionNames.AppendValue(actionElement->GetActionID());
	}
	actionNames.Sort();
	return actionNames;
}

#pragma mark -

	// Factory function to build an action element set from an XML tree

ErrorMessage ActionElementSet::CreateFromXMLTree(const NXMLNode& inTree,
												 shared_ptr<XMLCommentContainer> ioCommentContainer)
{
	ErrorMessage errorValue(XMLNoError, "");
	NString errorMessage;
	NString errorString;
	NN_ASSERT(inTree.IsElement(kActionsElement));
	XMLCommentHolder *commentHolder = this;
	const NXMLNodeList *childList = inTree.GetChildren();
	for (NXMLNodeListConstIterator pos = childList->begin(); pos != childList->end() && errorValue == XMLNoError; ++pos) {
		const NXMLNode *childTree = *pos;
		switch (childTree->GetType()) {
			case kNXMLNodeElement:
					// An element, which should be an action element
				if (childTree->GetTextValue() != kActionElement) {
						// Handle non-action element
					errorString = NBundleString(kActionsElementWrongElementType, "", kErrorTableName);
					errorMessage.Format(errorString, childTree->GetTextValue());
					errorValue = ErrorMessage(XMLBadElementTypeError, errorMessage);
				}
				else {
					ActionElement *actionElement;
					errorValue = ActionElement::CreateFromXMLTree(*childTree, actionElement, ioCommentContainer);
					if (errorValue == XMLNoError) {
						Boolean addOK = AddActionElement(actionElement);
						if (!addOK) {
							errorString = NBundleString(kActionSetRepeatedAction, "", kErrorTableName);
							errorMessage.Format(errorString, actionElement->GetActionID());
							errorValue = ErrorMessage(XMLRepeatedActionError, errorMessage);
							break;
						}
						if (commentHolder != NULL) {
							commentHolder->RemoveDuplicateComments();
						}
						commentHolder = actionElement;
						ioCommentContainer->AddCommentHolder(actionElement);
					}
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
				errorMessage = NBundleString(kActionsElementInvalidNodeType, "", kErrorTableName);
				errorValue = ErrorMessage(XMLWrongXMLNodeTypeError, errorMessage);
				break;
		}
	}
	if (errorValue == XMLNoError) {
		commentHolder->RemoveDuplicateComments();
	}
	else {
			// An error in processing, so delete the partially constructed element
		if (!mActionElementSet.empty()) {
			std::set<ActionElement *, DereferenceLess>::iterator pos;
			for (pos = mActionElementSet.begin(); pos != mActionElementSet.end(); ++pos) {
				ActionElement *actionElement = *pos;
				if (actionElement != NULL) {
					delete actionElement;
				}
			}
			Clear();
		}
	}
	return errorValue;
}

	// Create an XML tree from the action element set

NXMLNode *ActionElementSet::CreateXMLTree(const bool inCodeNonAscii)
{
	NXMLNode *xmlTree = new NXMLNode(kNXMLNodeElement, kActionsElement);
	AddCommentsToXMLTree(*xmlTree);
	std::set<ActionElement *, DereferenceLess>::iterator pos;
	for (pos = mActionElementSet.begin(); pos != mActionElementSet.end(); ++pos) {
		ActionElement *actionElement = *pos;
		NXMLNode *childTree = actionElement->CreateXMLTree(inCodeNonAscii);
		xmlTree->AddChild(childTree);
		actionElement->AddCommentsToXMLTree(*xmlTree);
	}
	return xmlTree;
}

NString ActionElementSet::GetDescription(void)
{
	return NString("actions element");
}

#pragma mark -

	// Create hex-entry keyboard actions

void ActionElementSet::CreateHexEntryActions(void) {
	for (UInt32 digit = 0; digit < 16; digit++) {
		NString actionName;
		actionName.Format("Hex entry %x", digit);
		ActionElement *actionElement = new ActionElement(actionName);
		const UInt32 firstDigitBase = 0x1101;
		NString nextState;
		nextState.Format("%d", firstDigitBase + digit);
		WhenElement *whenElement = new WhenElement(kStateNone, "", nextState, "", "");
		actionElement->AddWhenElement(whenElement);
		const UInt32 stateBlockSize = 0x100;
		for (UInt32 stateBlockIndex = 0; stateBlockIndex < 16; stateBlockIndex++) {
			NString stateBlockFirst;
			stateBlockFirst.Format("%d", stateBlockIndex * stateBlockSize + 1);
			NString stateBlockLast;
			stateBlockLast.Format("%d", (stateBlockIndex + 1) * stateBlockSize);
			NString outputString;
			outputString.Format("&#x%x00%x;", stateBlockIndex, digit);
			whenElement = new WhenElement(stateBlockFirst, outputString, "", stateBlockLast, "16");
			actionElement->AddWhenElement(whenElement);
		}
		const UInt32 secondDigitBase = 0x1001;
		NString stateFirst;
		NString stateLast;
		stateFirst.Format("%d", secondDigitBase);
		stateLast.Format("%d", secondDigitBase + 0x100 - 1);
		nextState.Format("%d", digit + 1);
		whenElement = new WhenElement(stateFirst, "", nextState, stateLast, "");
		actionElement->AddWhenElement(whenElement);
		stateFirst.Format("%d", firstDigitBase);
		stateLast.Format("%d", firstDigitBase + 15);
		nextState.Format("%d", 0x1001 + digit);
		whenElement = new WhenElement(stateFirst, "", nextState, stateLast, "");
		actionElement->AddWhenElement(whenElement);
		Boolean result = AddActionElement(actionElement);
		assert(result);
	}
}

#pragma mark -

	// Get the first element

ActionElement *ActionElementSet::GetFirstElement(void)
{
	mIterator = mActionElementSet.begin();
	if (mIterator != mActionElementSet.end()) {
		return *mIterator;
	}
	else {
		return NULL;
	}
}

	// Get the next element

ActionElement *ActionElementSet::GetNextElement(void)
{
	if (++mIterator != mActionElementSet.end()) {
		return *mIterator;
	}
	else {
		return NULL;
	}
}

	// Append to list of comment holders

void ActionElementSet::AppendToList(XMLCommentHolderList& ioList)
{
	ioList.push_back(this);
	std::set<ActionElement *, DereferenceLess>::iterator pos;
	for (pos = mActionElementSet.begin(); pos != mActionElementSet.end(); ++pos) {
		(*pos)->AppendToList(ioList);
	}
}

#pragma mark -

	// Protected method to create a unique action name

NString ActionElementSet::GetUniqueActionName(const NString inBaseString, UInt32 inSuffixStart)
{
	NString actionName;
	for (UInt32 suffixValue = inSuffixStart; suffixValue < INT_MAX; suffixValue++) {
		actionName.Format("%@%d", inBaseString, suffixValue);
		if (!ActionExists(actionName)) {
			break;
		}
	}
	return actionName;
}

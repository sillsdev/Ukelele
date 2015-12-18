/*
 *  KeyElement.mm
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "KeyElement.h"
#include "UkeleleStrings.h"
#include "XMLErrors.h"
#include "XMLUtilities.h"
#include "NBundle.h"
#include "UkeleleConstantStrings.h"
#include "NCocoa.h"

	// Key strings
const NString kKeyElementMissingCodeAttribute = "KeyElementMissingCodeAttribute";
const NString kKeyElementDoubleSpecified = "KeyElementDoubleSpecified";
const NString kKeyElementNotActionElement = "KeyElementNotActionElement";
const NString kKeyElementOverspecified = "KeyElementOverspecified";
const NString kKeyElementInvalidNodeType = "KeyElementInvalidNodeType";

	// Constructor

KeyElement::KeyElement(const UInt32 inKeyCode)
: XMLCommentHolder(kKeyElementType), mKeyCode(inKeyCode), mElementType(kKeyFormUndefined)
{
}

	// Copy constructor

KeyElement::KeyElement(const KeyElement& inOriginal)
: XMLCommentHolder(inOriginal)
{
	mKeyCode = inOriginal.mKeyCode;
	mElementType = inOriginal.mElementType;
	switch (mElementType) {
		case kKeyFormUndefined:
			mInlineAction.reset();
			break;
			
		case kKeyFormOutput:
			mOutput = inOriginal.mOutput;
			mInlineAction.reset();
			break;
			
		case kKeyFormAction:
			mActionName = inOriginal.mActionName;
			mInlineAction.reset();
			break;
			
		case kKeyFormInlineAction:
			mInlineAction.reset(new ActionElement(*inOriginal.mInlineAction));
			break;
	}
}

	// Destructor

KeyElement::~KeyElement(void)
{
}

#pragma mark -

	// Create a key element from an XML tree

ErrorMessage KeyElement::CreateFromXMLTree(const NXMLNode& inXMLTree,
										   KeyElement*& outElement,
										   shared_ptr<XMLCommentContainer> ioCommentContainer)
{
	ErrorMessage errorValue(XMLNoError, "");
	NString errorString;
	NN_ASSERT(inXMLTree.IsElement(kKeyElement));
	NDictionary attributeDictionary = inXMLTree.GetElementAttributes();
	if (!attributeDictionary.HasKey(kCodeAttribute)) {
			// No code attribute
		errorString = NBundleString(kKeyElementMissingCodeAttribute, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorString);
		return errorValue;
	}
	NString keyCodeString = inXMLTree.GetElementAttribute(kCodeAttribute);
	NNumber keyCodeNumber(keyCodeString);
	UInt32 keyCode = keyCodeNumber.GetUInt32();
	outElement = new KeyElement(keyCode);
	NString outputAttribute = inXMLTree.GetElementAttribute(kOutputAttribute);
	if (!outputAttribute.IsEmpty()) {
		outElement->NewOutputElement(outputAttribute);
	}
	if (attributeDictionary.HasKey(kActionAttribute)) {
		NString actionAttribute = inXMLTree.GetElementAttribute(kActionAttribute);
		if (outElement->mElementType != kKeyFormUndefined) {
				// Doubly specified form
			errorString = NBundleString(kKeyElementDoubleSpecified, "", kErrorTableName);
			errorValue = ErrorMessage(XMLOverSpecifiedFormError, errorString);
			delete outElement;
			outElement = NULL;
			return errorValue;
		}
		outElement->NewActionElement(actionAttribute);
	}
	NString childValue;
	XMLCommentHolder *commentHolder = outElement;
	const NXMLNodeList *childList = inXMLTree.GetChildren();
	for (NXMLNodeListConstIterator pos = childList->begin(); pos != childList->end() && errorValue == XMLNoError; ++pos) {
		const NXMLNode *childTree = *pos;
		switch (childTree->GetType()) {
			case kNXMLNodeElement:
					// An element, which should be an action element
				if (childTree->GetTextValue() != kActionElement) {
						// Not an action element
					NString errorFormat = NBundleString(kKeyElementNotActionElement, "", kErrorTableName);
					errorString.Format(errorFormat, childTree->GetTextValue());
					errorValue = ErrorMessage(XMLBadElementTypeError, errorString);
					break;
				}
					// Check whether we already have a specification
				if (outElement->mElementType != kKeyFormUndefined) {
					errorString = NBundleString(kKeyElementOverspecified, "", kErrorTableName);
					errorValue = ErrorMessage(XMLOverSpecifiedFormError, errorString);
					break;
				}
				ActionElement *actionElement;
				errorValue = ActionElement::CreateFromXMLTree(*childTree, actionElement, ioCommentContainer);
				if (errorValue == XMLNoError) {
					outElement->NewInlineActionElement(actionElement);
						// Deal with comments
					if (commentHolder != NULL) {
						commentHolder->RemoveDuplicateComments();
					}
					commentHolder = actionElement;
					ioCommentContainer->AddCommentHolder(actionElement);
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
				errorString = NBundleString(kKeyElementInvalidNodeType, "", kErrorTableName);
				errorValue = ErrorMessage(XMLWrongXMLNodeTypeError, errorString);
				break;
		}
	}
	if (errorValue == XMLNoError) {
		commentHolder->RemoveDuplicateComments();
		if (outElement->mElementType == kKeyFormUndefined) {
			outElement->NewOutputElement("");
		}
	}
	else {
			// An error in processing, so delete the partially constructed element
		delete outElement;
		outElement = NULL;
	}
	return errorValue;
}

ErrorMessage KeyElement::CreateFromXML(NSXMLElement *inXMLTree, KeyElement *&outElement, boost::shared_ptr<XMLCommentContainer> ioCommentContainer) {
	ErrorMessage errorValue(XMLNoError, "");
	NString errorString;
	NSXMLNode *attributeNode = [inXMLTree attributeForName:ToNS(kCodeAttribute)];
	if (attributeNode == nil) {
			// No code attribute
		errorString = NBundleString(kKeyElementMissingCodeAttribute, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorString);
		return errorValue;
	}
	NString keyCodeString = ToNN([attributeNode stringValue]);
	NNumber keyCodeNumber(keyCodeString);
	UInt32 keyCode = keyCodeNumber.GetUInt32();
	outElement = new KeyElement(keyCode);
	attributeNode = [inXMLTree attributeForName:ToNS(kOutputAttribute)];
	if (attributeNode != nil) {
			// Have an output attribute
		outElement->NewOutputElement(ToNN([attributeNode stringValue]));
	}
	attributeNode = [inXMLTree attributeForName:ToNS(kActionAttribute)];
	if (attributeNode != nil) {
			// Have an action attribute
		if (outElement->mElementType != kKeyFormUndefined) {
				// Doubly specified form
			errorString = NBundleString(kKeyElementDoubleSpecified, "", kErrorTableName);
			errorValue = ErrorMessage(XMLOverSpecifiedFormError, errorString);
			delete outElement;
			outElement = NULL;
			return errorValue;
		}
		outElement->NewActionElement(ToNN([attributeNode stringValue]));
	}
	NString childValue;
	XMLCommentHolder *commentHolder = outElement;
	for (NSXMLNode *childNode in [inXMLTree children]) {
		switch ([childNode kind]) {
			case NSXMLElementKind: {
					// An element node, which should be an action element
				if (ToNN([childNode name]) != kActionElement) {
						// Not an action element
					NString errorFormat = NBundleString(kKeyElementNotActionElement, "", kErrorTableName);
					errorString.Format(errorFormat, ToNN([childNode name]));
					errorValue = ErrorMessage(XMLBadElementTypeError, errorString);
					break;
				}
					// Check whether we already have a specification
				if (outElement->mElementType != kKeyFormUndefined) {
					errorString = NBundleString(kKeyElementOverspecified, "", kErrorTableName);
					errorValue = ErrorMessage(XMLOverSpecifiedFormError, errorString);
					break;
				}
				ActionElement *actionElement;
				errorValue = ActionElement::CreateFromXML((NSXMLElement *)childNode, actionElement, ioCommentContainer);
				if (errorValue == XMLNoError) {
					outElement->NewInlineActionElement(actionElement);
						// Deal with comments
					if (commentHolder != NULL) {
						commentHolder->RemoveDuplicateComments();
					}
					commentHolder = actionElement;
					ioCommentContainer->AddCommentHolder(actionElement);
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
				errorString = NBundleString(kKeyElementInvalidNodeType, "", kErrorTableName);
				errorValue = ErrorMessage(XMLWrongXMLNodeTypeError, errorString);
			break;
		}
	}
	if (errorValue == XMLNoError) {
		commentHolder->RemoveDuplicateComments();
		if (outElement->mElementType == kKeyFormUndefined) {
			outElement->NewOutputElement("");
		}
	}
	else {
			// An error in processing, so delete the partially constructed element
		delete outElement;
		outElement = NULL;
	}
	return errorValue;
}

	// Create an XML tree

NXMLNode *KeyElement::CreateXMLTree(void)
{
	NXMLNode *xmlTree = new NXMLNode(kNXMLNodeElement, kKeyElement);
	NString keyCodeString;
	keyCodeString.Format("%d", mKeyCode);
	xmlTree->SetElementAttribute(kCodeAttribute, keyCodeString);
	if (mElementType == kKeyFormAction) {
		xmlTree->SetElementAttribute(kActionAttribute, XMLUtilities::ConvertToXMLString(mActionName));
		xmlTree->SetElementUnpaired(true);
	}
	else if (mElementType == kKeyFormInlineAction) {
		NXMLNode *childTree = mInlineAction->CreateXMLTree();
		xmlTree->AddChild(childTree);
	}
	else {
		xmlTree->SetElementAttribute(kOutputAttribute, XMLUtilities::ConvertToXMLString(mOutput));
		xmlTree->SetElementUnpaired(true);
	}
	return xmlTree;
}

NSXMLElement *KeyElement::CreateXML(void) {
	NSXMLElement *xmlTree = [NSXMLElement elementWithName:ToNS(kKeyElement)];
	NSXMLNode *attributeNode = [NSXMLNode attributeWithName:ToNS(kCodeAttribute) stringValue:[NSString stringWithFormat:@"%d", mKeyCode]];
	[xmlTree addAttribute:attributeNode];
	if (mElementType == kKeyFormAction) {
		attributeNode = [NSXMLNode attributeWithName:ToNS(kActionAttribute) stringValue:ToNS(XMLUtilities::ConvertToXMLString(mActionName))];
		[xmlTree addAttribute:attributeNode];
	}
	else if (mElementType == kKeyFormInlineAction) {
		NSXMLElement *actionNode = mInlineAction->CreateXML();
		[xmlTree addChild:actionNode];
	}
	else {
		attributeNode = [NSXMLNode attributeWithName:ToNS(kOutputAttribute) stringValue:ToNS(XMLUtilities::ConvertToXMLString(mOutput))];
		[xmlTree addAttribute:attributeNode];
	}
	return xmlTree;
}

NString KeyElement::GetDescription(void)
{
	NString descriptionString;
	descriptionString.Format("key code=%d", mKeyCode);
	if (!mOutput.IsEmpty()) {
		descriptionString += NString(" output=\"");
		descriptionString += mOutput;
		descriptionString += NString("\"");
	}
	else if (!mActionName.IsEmpty()) {
		NString actionString;
		actionString.Format(" action=\"%@\"", mActionName);
		descriptionString += actionString;
	}
	else if (mElementType == kKeyFormInlineAction) {
		descriptionString += NString(" inline action");
	}
	return descriptionString;
}

	// Make the element an output element

void KeyElement::NewOutputElement(const NString inOutputString)
{
	NN_ASSERT(mElementType == kKeyFormUndefined || mElementType == kKeyFormOutput);
	NString newOutput = XMLUtilities::ConvertEncodedString(inOutputString);
	switch (mElementType) {
		case kKeyFormUndefined:
			mElementType = kKeyFormOutput;
			mOutput = newOutput;
			break;
			
		case kKeyFormOutput:
			if (mOutput != newOutput) {
				mOutput = newOutput;
			}
			break;
	}
}

void KeyElement::NewOutputElement(const UniChar *inString, const UInt32 inLength)
{
	BOOL codeNonAscii = [[NSUserDefaults standardUserDefaults] boolForKey:UKCodeNonAscii];
	NString outputString = XMLUtilities::MakeXMLString(inString, inLength, codeNonAscii);
	NewOutputElement(outputString);
}

	// Make the element an action element

void KeyElement::NewActionElement(const NString inActionName)
{
		//	NN_ASSERT(inActionName.IsNotEmpty());
	switch (mElementType) {
		case kKeyFormUndefined:
		case kKeyFormAction:
			break;
			
		case kKeyFormOutput:
			mOutput = "";
			break;
			
		case kKeyFormInlineAction:
			mInlineAction.reset();
			break;
	}
	mElementType = kKeyFormAction;
	mActionName = inActionName;
}

	// Make the element an inline action element

void KeyElement::NewInlineActionElement(ActionElement *inActionElement)
{
	NN_ASSERT(inActionElement != NULL);
	NN_ASSERT(mElementType == kKeyFormUndefined || mElementType == kKeyFormInlineAction);
	switch (mElementType) {
		case kKeyFormUndefined:
			mElementType = kKeyFormInlineAction;
			mInlineAction.reset(inActionElement);
			break;
			
		case kKeyFormInlineAction:
			mInlineAction.reset(inActionElement);
			break;
	}
}

#pragma mark -

	// Get the type of output in a particular state

UInt32 KeyElement::GetOutputType(NString inState, shared_ptr<ActionElementSet> inActionList)
{
	ActionElement *actionElement = NULL;
	bool inlineAction = false;
	switch (mElementType) {
		case kKeyFormUndefined:
			return kKeyUndefined;
			
		case kKeyFormOutput:
			return kKeyOutput;
			
		case kKeyFormAction:
			actionElement = inActionList->FindActionElement(mActionName);
			NN_ASSERT(actionElement != NULL);
			break;
			
		case kKeyFormInlineAction:
			inlineAction = true;
			actionElement = mInlineAction.get();
			break;
	}
		// Inspect the action
	assert(actionElement != NULL);
	WhenElement *whenElement = actionElement->FindWhenElement(inState);
	if (whenElement != NULL && !whenElement->GetOutput().IsEmpty()) {
		return inlineAction ? kKeyInlineActionOutput : kKeyActionOutput;
	}
	else {
		return inlineAction ? kKeyInlineActionDeadKey : kKeyActionDeadKey;
	}
}

	// Change the output to be the new string

NString KeyElement::ChangeOutput(NString inState, NString inNewOutput, shared_ptr<ActionElementSet> inActionList)
{
	ActionElement *actionElement = NULL;
	WhenElement *whenElement = NULL;
	NString newOutput = XMLUtilities::ConvertEncodedString(inNewOutput);
	NString oldOutput("");
	switch (mElementType) {
		case kKeyFormUndefined:
			mElementType = kKeyFormOutput;
			mOutput = newOutput;
			return oldOutput;
			
		case kKeyFormOutput:
			oldOutput = mOutput;
			if (oldOutput == newOutput) {
					// No change of output
				return oldOutput;
			}
			if (inState == kStateNone) {
					// Simple case: just switch to the new output
				mOutput = newOutput;
				return oldOutput;
			}
				// We need to create an action at this point
			mElementType = kKeyFormAction;
				// Make an action name based on the old output
			if (!mOutput.IsEmpty()) {
				mActionName = inActionList->MakeActionName(mOutput);
			}
			else {
				mActionName = inActionList->MakeActionName("action");
			}
			actionElement = new ActionElement(mActionName);
			inActionList->AddActionElement(actionElement);
			whenElement = new WhenElement(kStateNone, mOutput, "", "", "");
			actionElement->AddWhenElement(whenElement);
			mOutput = "";
			break;
			
		case kKeyFormAction:
			actionElement = inActionList->FindActionElement(mActionName);
			NN_ASSERT(actionElement != NULL);
			break;
			
		case kKeyFormInlineAction:
			actionElement = mInlineAction.get();
			break;
	}
		// Update the action with the new output
	assert(actionElement != NULL);
	whenElement = actionElement->FindWhenElement(inState);
	if (whenElement != NULL) {
		oldOutput = whenElement->GetOutput();
		if (!inNewOutput.IsEmpty()) {
			whenElement->SetOutput(newOutput);
		}
		else {
			actionElement->DeleteWhenElement(inState);
		}
	}
	else if (!inNewOutput.IsEmpty()) {
		whenElement = new WhenElement(inState, newOutput, "", "", "");
		actionElement->AddWhenElement(whenElement);
	}
	return oldOutput;
}

	// Convert an output element to a dead key

void KeyElement::ChangeOutputToDeadKey(NString inState, NString inDeadKeyState, shared_ptr<ActionElementSet> inActionList)
{
	ActionElement *actionElement = NULL;
	WhenElement *whenElement = NULL;
	NN_ASSERT(mElementType != kKeyFormUndefined);
	switch (mElementType) {
		case kKeyFormOutput:
				// We need to create an action
			mElementType = kKeyFormAction;
				// Make an action name based on the old output
			NN_ASSERT(mActionName.IsEmpty());
			if (!mOutput.IsEmpty()) {
				mActionName = inActionList->MakeActionName(mOutput);
			}
			else {
				mActionName = inActionList->MakeActionName("action");
			}
			actionElement = new ActionElement(mActionName);
			inActionList->AddActionElement(actionElement);
			whenElement = new WhenElement(kStateNone, "", inDeadKeyState, "", "");
			actionElement->AddWhenElement(whenElement);
			mOutput = "";
			break;
			
		case kKeyFormAction:
			actionElement = inActionList->FindActionElement(mActionName);
			NN_ASSERT(actionElement != NULL);
			break;
			
		case kKeyFormInlineAction:
			actionElement = mInlineAction.get();
			break;
	}
	assert(actionElement != NULL);
	whenElement = actionElement->FindWhenElement(inState);
	if (whenElement == NULL) {
		whenElement = new WhenElement(inState, "", inDeadKeyState, "", "");
		actionElement->AddWhenElement(whenElement);
	}
	else {
		whenElement->SetOutput("");
		whenElement->SetNext(inDeadKeyState);
	}
}

	// Convert a dead key to output

NString KeyElement::ChangeDeadKeyToOutput(NString inState, NString inNewOutput, shared_ptr<ActionElementSet> inActionList)
{
	NString oldState;
	NString newOutput = XMLUtilities::ConvertEncodedString(inNewOutput);
	ActionElement *actionElement = NULL;
	NN_ASSERT(mElementType != kKeyFormUndefined && mElementType != kKeyFormOutput);
	switch (mElementType) {
		case kKeyFormAction:
			actionElement = inActionList->FindActionElement(mActionName);
			NN_ASSERT(actionElement != NULL);
			break;
			
		case kKeyFormInlineAction:
			actionElement = mInlineAction.get();
			break;
	}
	assert(actionElement != NULL);
	WhenElement *whenElement = actionElement->FindWhenElement(inState);
	NN_ASSERT(whenElement != NULL);
	assert(whenElement != NULL);
	oldState = whenElement->GetNext();
	if (inState == kStateNone && actionElement->GetWhenElementCount() == 1) {
		if (mElementType == kKeyFormAction) {
			mActionName = "";
		}
		else {
			mInlineAction.reset();
		}
		if (!inNewOutput.IsEmpty()) {
			mOutput = newOutput;
		}
		else {
			mOutput = "";
		}
		mElementType = kKeyFormOutput;
	}
	else {
		if (!inNewOutput.IsEmpty()) {
			whenElement->SetNext("");
			whenElement->SetOutput(newOutput);
		}
		else {
			actionElement->DeleteWhenElement(oldState);
		}
	}
	return oldState;
}

	// Make the element a dead key

void KeyElement::MakeDeadKey(NString inState, NString inDeadKeyState, shared_ptr<ActionElementSet> inActionList)
{
	ActionElement *actionElement = NULL;
	WhenElement *whenElement = NULL;
	switch (mElementType) {
		case kKeyFormUndefined:
		case kKeyFormOutput: {
				// We need to create an action
			NString baseName;
			if (mElementType == kKeyFormOutput && !mOutput.IsEmpty()) {
					// Make an action name based on the old output
				baseName = mOutput;
			}
			else {
					// Make an action name based on the new state
				baseName = inDeadKeyState;
			}
			NN_ASSERT(mActionName.IsEmpty());
			mActionName = inActionList->MakeActionName(baseName);
			actionElement = new ActionElement(mActionName);
			inActionList->AddActionElement(actionElement);
			if (mElementType == kKeyFormOutput) {
					// If it is not state "none", then make the old output the output
					// for state "none".
				if (inState != kStateNone) {
					whenElement = new WhenElement(kStateNone, mOutput, "", "", "");
					actionElement->AddWhenElement(whenElement);
				}
				mOutput = "";
			}
			mElementType = kKeyFormAction;
			break;
		}
			
		case kKeyFormAction:
			actionElement = inActionList->FindActionElement(mActionName);
			NN_ASSERT(actionElement != NULL);
			break;
			
		case kKeyFormInlineAction:
			actionElement = mInlineAction.get();
			break;
	}
	assert(actionElement != NULL);
	whenElement = actionElement->FindWhenElement(inState);
	if (whenElement == NULL) {
		whenElement = new WhenElement(inState, "", inDeadKeyState, "", "");
		actionElement->AddWhenElement(whenElement);
	}
	else {
		whenElement->SetOutput("");
		whenElement->SetNext(inDeadKeyState);
	}
}

	// Convert an output element to an action element

void KeyElement::MakeActionElement(NString inState, shared_ptr<ActionElementSet> inActionList)
{
	NN_ASSERT(mElementType == kKeyFormOutput);
		// Make an action name based on the old output
	if (!mOutput.IsEmpty()) {
		mActionName = inActionList->MakeActionName(mOutput);
	}
	else {
		mActionName = inActionList->MakeActionName("action");
	}
	ActionElement *actionElement = new ActionElement(mActionName);
	inActionList->AddActionElement(actionElement);
	WhenElement *whenElement = new WhenElement(inState, mOutput, "", "", "");
	actionElement->AddWhenElement(whenElement);
	mOutput = "";
	mElementType = kKeyFormAction;
}

	// Change the key code of the element

void KeyElement::ChangeKeyCode(const UInt32 inNewKeyCode)
{
	mKeyCode = inNewKeyCode;
}

	// Return the type of key for a given state

UInt32 KeyElement::GetTypeForState(NString inState, const shared_ptr<ActionElementSet> inActionList, NString& outString)
{
	UInt32 result;
	ActionElement *actionElement = NULL;
	switch (mElementType) {
		case kKeyFormUndefined:
			return kStateNull;
			
		case kKeyFormOutput:
			outString = mOutput;
			return kStateOutput;
			
		case kKeyFormAction:
			actionElement = inActionList->FindActionElement(mActionName);
			NN_ASSERT(actionElement != NULL);
			break;
			
		case kKeyFormInlineAction:
			actionElement = mInlineAction.get();
			break;
	}
	assert(actionElement != NULL);
	WhenElement *whenElement = actionElement->FindWhenElement(inState);
	if (whenElement == NULL) {
		result = kStateNull;
	}
	else if (!whenElement->GetNext().IsEmpty()) {
		result = kStateNext;
		outString = whenElement->GetNext();
	}
	else {
		result = kStateOutput;
		outString = whenElement->GetOutput();
	}
	return result;
}

bool KeyElement::HasInlineAction(void) const
{
	return mElementType == kKeyFormInlineAction;
}

#pragma mark -

	// Get all state names referred to by the key element

void KeyElement::GetStateNames(NSMutableSet *ioStateNames, const UInt32 inReachable)
{
	if (mElementType == kKeyFormInlineAction) {
		NN_ASSERT(mInlineAction.get() != NULL);
		mInlineAction->GetStateNames(ioStateNames, inReachable);
	}
}

	// Replace a state name by a new name

void KeyElement::ReplaceStateName(NString inOldName, NString inNewName)
{
	if (mElementType == kKeyFormInlineAction) {
		NN_ASSERT(mInlineAction.get() != NULL);
		mInlineAction->ReplaceStateName(inOldName, inNewName);
	}
}

	// Remove all reference to the states in the given set

void KeyElement::RemoveStates(NSSet *inStates)
{
	if (mElementType == kKeyFormInlineAction) {
		NN_ASSERT(mInlineAction.get() != NULL);
		mInlineAction->RemoveStates(inStates);
	}
}

	// Change the name of an action

void KeyElement::ChangeActionName(NString inOldName, NString inNewName)
{
	if (mElementType == kKeyFormAction) {
		if (mActionName == inOldName) {
			mActionName = inNewName;
		}
	}
}

	// Get the maximum length of an output string

UInt32 KeyElement::GetMaxout(void) const
{
	UInt32 maxout = 0;
	if (mElementType == kKeyFormOutput) {
			// Get the length of the decoded string
		if (mOutput.IsEmpty()) {
			maxout = 0;
		}
		else {
			UInt32 stringLength = mOutput.GetSize();
			UniChar *buffer = new UniChar[stringLength];
			XMLUtilities::ConvertEncodedString(mOutput, buffer, stringLength);
			maxout = stringLength;
			delete [] buffer;
		}
	}
	else if (mElementType == kKeyFormInlineAction) {
		maxout = mInlineAction->GetMaxout();
	}
	return maxout;
}

	// Append to a list of comment holders

void KeyElement::AppendToList(XMLCommentHolderList& ioList)
{
	ioList.push_back(this);
	if (mElementType == kKeyFormInlineAction) {
		mInlineAction->AppendToList(ioList);
	}
}

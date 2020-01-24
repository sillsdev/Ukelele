/*
 *  UkeleleKeyboard.mm
 *  Ukelele 3
 *
 *  Created by John Brownie on 10/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "UkeleleKeyboard.h"
#include "XMLErrors.h"
#include "NBundle.h"
#include "boost/tuple/tuple.hpp"
#include "KeyStrokeLookupTable.h"
#include "NCoreFoundation.h"

// Strings
const NString kUkeleleKeyboardWrongXMLType = "UkeleleKeyboardWrongXMLType";
const NString kUkeleleKeyboardUnknownNodeType = "UkeleleKeyboardUnknownNodeType";
const NString kUkeleleKeyboardRepeatedXMLHeader = "UkeleleKeyboardRepeatedXMLHeader";
const NString kUkeleleKeyboardRepeatedDTD = "UkeleleKeyboardRepeatedDTD";
NSString *dateFormat = @" 'on' yyyy-MM-dd 'at' HH:mm (zzz)";

// Constructor

UkeleleKeyboard::UkeleleKeyboard(void)
	: XMLCommentHolder(kDocumentType), mCommentContainer(new XMLCommentContainer)
{
	mCommentContainer->AddCommentHolder(this);
}

// Destructor

UkeleleKeyboard::~UkeleleKeyboard(void)
{
}

// Create from an XML tree

ErrorMessage UkeleleKeyboard::CreateKeyboardFromXMLTree(const NXMLNode& inXMLTree)
{
	ErrorMessage errorValue(XMLNoError, "");
	NString errorString;
	const NXMLNodeList *childList = inXMLTree.GetChildren();
	for (NXMLNodeListConstIterator pos = childList->begin(); pos != childList->end() && errorValue == XMLNoError; ++pos) {
		const NXMLNode *childTree = *pos;
		switch (childTree->GetType()) {
//			case kCFXMLNodeTypeProcessingInstruction:
//				// A processing instruction, which we ignore
//			break;
//			
			case kNXMLNodeDocType:
				// The DTD header
				if (!mDTDHeader.IsEmpty()) {
					// Handle repeated DTD
					errorString = NBundleString(kUkeleleKeyboardRepeatedDTD, "", kErrorTableName);
					errorValue = ErrorMessage(XMLRepeatedDTDError, errorString);
				}
				else {
					mDTDHeader = childTree->GetDocTypePublicID();
					if (mDTDHeader == "") {
						mDTDHeader = childTree->GetDocTypeSystemID();
					}
				}
			break;
			
			case kNXMLNodeElement: {
				// An element, which should be the keyboard layout
				NString nodeString = childTree->GetTextValue();
				if (nodeString != kKeyboardElement) {
					// Handle non-keyboard files
					NString formatString = NBundleString(kUkeleleKeyboardWrongXMLType, "", kErrorTableName);
					errorString.Format(formatString, nodeString);
					errorValue = ErrorMessage(XMLBadElementTypeError, errorString);
				}
				KeyboardElement *keyboardElement;
				errorValue = KeyboardElement::CreateFromXMLTree(*childTree, keyboardElement, mCommentContainer);
				if (errorValue == XMLNoError) {
					mKeyboard.reset(keyboardElement);
					mCommentContainer->AddCommentHolder(keyboardElement);
				}
			}
			break;
			
			case kNXMLNodeComment: {
				XMLComment *childComment = new XMLComment(childTree->GetTextValue(), this);
				AddXMLComment(childComment);
			}
			break;
			
			default:
				errorString = NBundleString(kUkeleleKeyboardUnknownNodeType, "", kErrorTableName);
				errorValue = ErrorMessage(XMLUnknownNodeTypeError, errorString);
			break;
		}
	}
	if (errorValue != XMLNoError) {
		// An error occurred, so delete the partially created layout
		mDTDHeader = "";
		mKeyboard.reset();
	}
	else {
		if (mDTDHeader.IsEmpty()) {
			mDTDHeader = kDefaultDTD;
		}
	}
	return errorValue;
}

// Create an XML tree representing the keyboard layout

NXMLNode *UkeleleKeyboard::CreateXMLTree(const bool inCodeNonAscii)
{
	NXMLNode *xmlTree = new NXMLNode(kNXMLNodeDocument, "");
	NXMLNode *childTree = new NXMLNode(kNXMLNodeDocType, kDefaultXMLName);
	childTree->SetDocTypeSystemID(mDTDHeader);
	xmlTree->AddChild(childTree);
	AddCommentsToXMLTree(*xmlTree);
	childTree = mKeyboard->CreateXMLTree(inCodeNonAscii);
	xmlTree->AddChild(childTree);
	return xmlTree;
}

// Create a basic keyboard layout

void UkeleleKeyboard::CreateBasicKeyboard(NString inName)
{
	mDTDHeader = kDefaultDTD;
	mKeyboard.reset(KeyboardElement::CreateBasicKeyboard(inName));
	mCommentContainer->AddCommentHolder(mKeyboard.get());
	AddCreationComment();
}

void UkeleleKeyboard::CreateStandardKeyboard(NString inName, UInt32 inBaseLayout, UInt32 inCommandLayout, UInt32 inCapsLockLayout) {
	mDTDHeader = kDefaultDTD;
	mKeyboard.reset(KeyboardElement::CreateStandardKeyboard(inName, inBaseLayout, inCommandLayout, inCapsLockLayout));
	mCommentContainer->AddCommentHolder(mKeyboard.get());
	AddCreationComment();
}

shared_ptr<KeyStrokeLookUpTable> UkeleleKeyboard::CreateKeyStrokeLookUpTable(const UInt32 inKeyboardID)
{
	std::vector<boost::tuple<NString, KeyStroke, NString> > keyStrokeList;
	shared_ptr<StateTransitionTable> transitionTable(new StateTransitionTable);
	shared_ptr<ActionElementSet> actionElementSet = mKeyboard->GetActionList();
	ModifierMap *modifierMap = mKeyboard->GetModifierMap(inKeyboardID);
	KeyMapSet *keyMapSet = mKeyboard->GetKeyMapSet(inKeyboardID);
	UInt32 keyElementCount = keyMapSet->GetKeyMapSize();
	UInt32 modifierCount = modifierMap->GetKeyMapSelectCount();
	for (UInt32 i = 0; i < modifierCount; i++) {
		UInt32 modifierCombination = modifierMap->GetMatchingModifiers(i);
		for (UInt32 keyCode = 0; keyCode < keyElementCount; keyCode++) {
			KeyElement *keyElement = mKeyboard->GetKeyElement(inKeyboardID, keyCode, modifierCombination, true);
			if (keyElement != NULL) {
				ActionElement *actionElement = NULL;
				KeyStroke keyStroke((SInt16)keyCode, modifierCombination);
				switch (keyElement->GetElementType()) {
					case kKeyFormOutput:
						// Have output, so call it from state none
						keyStrokeList.push_back(boost::make_tuple(kStateNone, keyStroke, keyElement->GetOutputString()));
					break;
					
					case kKeyFormInlineAction:
						actionElement = keyElement->GetInlineAction();
					break;
				
					case kKeyFormAction:
						actionElement = actionElementSet->FindActionElement(keyElement->GetActionName());
					break;
				}
				if (actionElement != NULL) {
					for (WhenElement *whenElement = actionElement->GetFirstWhenElement();
						whenElement != NULL; whenElement = actionElement->GetNextWhenElement()) {
						NString stateName = whenElement->GetState();
						NString outputString = whenElement->GetOutput();
						NString transitionState = whenElement->GetNext();
						if (outputString != "") {
							// Output in the given state
							keyStrokeList.push_back(boost::make_tuple(stateName, keyStroke, outputString));
						}
						else if (transitionState != "") {
							// Transition from stateName to transitionState
							if (!transitionTable->HasTransition(stateName, transitionState)) {
								transitionTable->AddTransition(stateName, transitionState, (SInt16)keyCode, modifierCombination);
							}
						}
					}
				}
			}
		}
	}
	// Create the lookup table
	shared_ptr<KeyStrokeLookUpTable> lookupTable(new KeyStrokeLookUpTable);
	// Set the transition table
	lookupTable->SetTransitionTable(transitionTable);
	// Add the outputs
	std::vector<boost::tuple<NString, KeyStroke, NString> >::iterator keyIter;
	for (keyIter = keyStrokeList.begin(); keyIter != keyStrokeList.end(); ++keyIter) {
		NString stateName;
		KeyStroke keyStroke(0, 0);
		NString outputString;
		boost::tie(stateName, keyStroke, outputString) = *keyIter;
		lookupTable->AddKeyStroke(stateName, keyStroke, outputString);
	}
	// Now handle the terminators
	TerminatorsElement *terminatorsElement = mKeyboard->GetTerminatorsElement();
	if (terminatorsElement != NULL) {
		NSMutableSet *stateSet = [NSMutableSet setWithCapacity:terminatorsElement->GetWhenElementCount()];
		terminatorsElement->GetStateNames(stateSet, kAllStates);
		KeyStroke terminatorKeyStroke(kNoKeyCode, 0);
		for (NSString *stateID in stateSet) {
			NString stateName = ToNN(stateID);
			WhenElement *whenElement = terminatorsElement->FindWhenElement(stateName);
			lookupTable->AddKeyStroke(stateName, terminatorKeyStroke, whenElement->GetOutput());
		}
	}
	return lookupTable;
}

// Description for XML comment holder

NString UkeleleKeyboard::GetDescription(void)
{
	return NString("Top level of document");
}

#pragma mark -
#pragma mark === Comments ===

// Add a comment indicating when the keyboard layout was created

void UkeleleKeyboard::AddCreationComment(void)
{
	// Get the application version
	NString versionString = ToNN((CFStringRef)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey));
	// Get the current time stamp
	NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0.0];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:dateFormat];
	NSString *dateStampString = [dateFormatter stringFromDate:date];
	NString dateStamp;
	dateStamp = ToNN(dateStampString);
	// Build the comment
	NString commentString = kCreationComment;
	commentString += versionString;
	commentString += dateStamp;
	// Add the comment
	XMLComment *creationComment;
	if (!FindCommentWithPrefix(kCreationComment, creationComment)) {
		AddXMLComment(commentString);
	}
	else {
		creationComment->SetCommentString(commentString);
	}
}

// Add or update the comment indicating when the keyboard layout was last edited

void UkeleleKeyboard::UpdateEditingComment(void)
{
	// Get the application version
	NString versionString = ToNN((CFStringRef)CFBundleGetValueForInfoDictionaryKey(CFBundleGetMainBundle(), kCFBundleVersionKey));
	// Get the current time stamp
	NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0.0];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:dateFormat];
	NSString *dateStampString = [dateFormatter stringFromDate:date];
	NString dateStamp;
	dateStamp = ToNN(dateStampString);
	// Build the comment
	NString commentString = kEditComment;
	commentString += versionString;
	commentString += dateStamp;
	// Add the comment
	XMLComment creationComment;
	if (!ReplaceCommentWithPrefix(kEditComment, commentString)) {
		AddXMLComment(commentString);
	}
}

XMLComment *UkeleleKeyboard::GetCurrentComment(void)
{
	XMLComment *currentComment;
	bool gotComment = mCommentContainer->GetCurrentComment(currentComment);
	if (gotComment) {
		return currentComment;
	}
	else {
		return NULL;
	}
}

XMLComment *UkeleleKeyboard::GetFirstComment(void)
{
	XMLComment *currentComment;
	bool gotComment = mCommentContainer->GetFirstComment(currentComment);
#pragma unused(gotComment)
	NN_ASSERT(gotComment || currentComment == NULL);
	return currentComment;
}

XMLComment *UkeleleKeyboard::GetPreviousComment(void)
{
	XMLComment *currentComment;
	bool gotComment = mCommentContainer->GetPreviousComment(currentComment);
#pragma unused(gotComment)
	NN_ASSERT(gotComment || currentComment == NULL);
	return currentComment;
}

XMLComment *UkeleleKeyboard::GetNextComment(void)
{
	XMLComment *currentComment;
	bool gotComment = mCommentContainer->GetNextComment(currentComment);
#pragma unused(gotComment)
	NN_ASSERT(gotComment || currentComment == NULL);
	return currentComment;
}

XMLComment *UkeleleKeyboard::GetLastComment(void)
{
	XMLComment *currentComment;
	bool gotComment = mCommentContainer->GetLastComment(currentComment);
#pragma unused(gotComment)
	NN_ASSERT(gotComment || currentComment == NULL);
	return currentComment;
}

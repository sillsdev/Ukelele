/*
 *  KeyboardElement.mm
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "KeyboardElement.h"
#include "XMLErrors.h"
#include "UkeleleStrings.h"
#include "RandomNumberGenerator.h"
#include "NBundle.h"
#include "NCocoa.h"

const UInt32 kStateMaximum = 1 << 30;

	// Strings
const NString kStateNameGenerator = "%@ %d";
const NString kKeyboardElementMissingAttributes = "KeyboardElementMissingAttributes";
const NString kKeyboardElementNoElements = "KeyboardElementNoElements";
const NString kKeyboardElementRepeatedLayoutsElement = "KeyboardElementRepeatedLayoutsElement";
const NString kKeyboardElementRepeatedActionsElement = "KeyboardElementRepeatedActionsElement";
const NString kKeyboardElementRepeatedTerminatorsElement = "KeyboardElementRepeatedTerminatorsElement";
const NString kKeyboardElementInvalidElementType = "KeyboardElementInvalidElementType";
const NString kKeyboardElementWrongNodeType = "KeyboardElementWrongNodeType";
const NString kMissingLayoutsElement = "MissingLayoutsElement";
const NString kKeyboardRepeatedModifierMap = "KeyboardRepeatedModifierMap";
const NString kKeyboardElementRepeatedKeyMapSet = "KeyboardElementRepeatedKeyMapSet";
const NString kKeyboardElementEmptyLayoutsElement = "KeyboardElementEmptyLayoutsElement";
const NString kMissingModifierMapElement = "MissingModifierMapElement";
const NString kMissingSpecialKeyOutput = "MissingSpecialKeyOutput";
const NString kKeyMapSetGap = "KeyMapSetGap";
const NString kInvalidBaseIndex = "InvalidBaseIndex";
const NString kExtraKeyMapSet = "ExtraKeyMapSet";
const NString kInvalidKeyboardID = "InvalidKeyboardID";

	// Constructor

KeyboardElement::KeyboardElement(const SInt32 inGroup, const SInt32 inID, const NString inName, const UInt32 inMaxout)
: XMLCommentHolder(kKeyboardElementType), mGroup(inGroup), mID(inID), mName(inName), mMaxout(inMaxout),
mRepairsNeeded(0), mKeyMapSetList(new KeyMapSetList), mActionList(new ActionElementSet)
{
}

	// Destructor

KeyboardElement::~KeyboardElement(void)
{
	for (ModifierMapIterator pos = mModifierMapList.begin(); pos != mModifierMapList.end(); ++pos) {
		ModifierMap *theMap = *pos;
		delete theMap;
	}
}

ErrorMessage KeyboardElement::CreateFromXMLTree(const NXMLNode& inTree,
												KeyboardElement *&outElement,
												shared_ptr<XMLCommentContainer> ioCommentContainer)
{
	ErrorMessage errorValue(XMLNoError, "");
	NString errorMessage;
	NN_ASSERT(inTree.IsElement(kKeyboardElement));
	NString groupAttribute = inTree.GetElementAttribute(kGroupAttribute);
	NString idAttribute = inTree.GetElementAttribute(kIDAttribute);
	NString nameAttribute = inTree.GetElementAttribute(kNameAttribute);
	NString maxoutAttribute = inTree.GetElementAttribute(kMaxoutAttribute);
	if (groupAttribute.IsEmpty() || idAttribute.IsEmpty() || nameAttribute.IsEmpty()) {
			// Handle missing attributes
		errorMessage = NBundleString(kKeyboardElementMissingAttributes, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingAttributeError, errorMessage);
		return errorValue;
	}
	NNumber groupNumber(groupAttribute);
	int32_t groupValue = groupNumber.GetInt32();
	NNumber idNumber(idAttribute);
	int32_t idValue = idNumber.GetInt32();
	NNumber maxoutNumber(maxoutAttribute);
	UInt32 maxoutValue = maxoutNumber.GetUInt32();
	const NXMLNodeList *childList = inTree.GetChildren();
	if (childList->size() == 0) {
			// Handle empty keyboard
		errorMessage = NBundleString(kKeyboardElementNoElements, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingChildrenError, errorMessage);
		return errorValue;
	}
	outElement = new KeyboardElement(groupValue, idValue, nameAttribute, maxoutValue);
	outElement->mLayouts.reset();
	outElement->mTerminatorsElement.reset();
	XMLCommentHolder *commentHolder = outElement;
	ioCommentContainer->AddCommentHolder(outElement);
	for (NXMLNodeListConstIterator pos = childList->begin(); pos != childList->end() && errorValue == XMLNoError; ++pos) {
		const NXMLNode *childTree = *pos;
		NString childString = childTree->GetTextValue();
		NString errorFormat;
		switch (childTree->GetType()) {
			case kNXMLNodeElement:
					// An element, the type of which can vary
				if (childString == kLayoutsElement) {
						// A layouts element, which must be unique
					if (outElement->mLayouts.get() != NULL) {
							// Repeated layouts element
						errorMessage = NBundleString(kKeyboardElementRepeatedLayoutsElement, "", kErrorTableName);
						errorValue = ErrorMessage(XMLRepeatedElementError, errorMessage);
					}
					else {
						LayoutsElement *layoutsElement;
						errorValue = LayoutsElement::CreateFromXMLTree(*childTree, layoutsElement, ioCommentContainer);
						if (errorValue == XMLNoError && layoutsElement->IsEmpty()) {
								// Layouts element is empty
							errorMessage = NBundleString(kKeyboardElementEmptyLayoutsElement, "", kErrorTableName);
							errorValue = ErrorMessage(XMLEmptyLayoutsElementError, errorMessage);
						}
						if (errorValue == XMLNoError) {
							outElement->AddLayoutsElement(layoutsElement);
							if (commentHolder != NULL) {
								commentHolder->RemoveDuplicateComments();
							}
							commentHolder = layoutsElement;
							ioCommentContainer->AddCommentHolder(commentHolder);
						}
					}
				}
				else if (childString == kModifierMapElement) {
						// A modifier map element
					ModifierMap *modifierMap;
					errorValue = ModifierMap::CreateFromXMLTree(*childTree, modifierMap, ioCommentContainer);
					if (errorValue == XMLNoError) {
							// Check whether we already have a modifier map with the same id
						if (outElement->FindModifierMap(modifierMap->GetID()) != NULL) {
							errorFormat = NBundleString(kKeyboardRepeatedModifierMap, "", kErrorTableName);
							errorMessage.Format(errorFormat, modifierMap->GetID());
							errorValue = ErrorMessage(XMLRepeatedModifierMapError, errorMessage);
						}
					}
					if (errorValue == XMLNoError) {
						outElement->AddModifierMap(modifierMap);
						if (commentHolder != NULL) {
							commentHolder->RemoveDuplicateComments();
						}
						commentHolder = modifierMap;
						ioCommentContainer->AddCommentHolder(commentHolder);
					}
				}
				else if (childString == kKeyMapSetElement) {
						// A keyMapSet element
					KeyMapSet *keyMapSet;
					errorValue = KeyMapSet::CreateFromXMLTree(*childTree, keyMapSet, ioCommentContainer);
					if (errorValue == XMLNoError) {
							// Check for a repeated key map set
						if (outElement->mKeyMapSetList->FindKeyMapSet(keyMapSet->GetID()) != NULL) {
							errorFormat = NBundleString(kKeyboardElementRepeatedKeyMapSet, "", kErrorTableName);
							errorMessage.Format(errorFormat, keyMapSet->GetID());
							errorValue = ErrorMessage(XMLRepeatedKeyMapSetError, errorMessage);
						}
					}
					if (errorValue == XMLNoError) {
						outElement->AddKeyMapSet(keyMapSet);
						if (commentHolder != NULL) {
							commentHolder->RemoveDuplicateComments();
						}
						commentHolder = keyMapSet;
						ioCommentContainer->AddCommentHolder(commentHolder);
					}
				}
				else if (childString == kActionsElement) {
						// An actions element, which must be unique
					if (!outElement->mActionList->IsEmpty()) {
							// Repeated actions element
						errorMessage = NBundleString(kKeyboardElementRepeatedActionsElement, "", kErrorTableName);
						errorValue = ErrorMessage(XMLRepeatedElementError, errorMessage);
					}
					else {
						errorValue = outElement->mActionList->CreateFromXMLTree(*childTree, ioCommentContainer);
						if (errorValue == XMLNoError) {
							if (commentHolder != NULL) {
								commentHolder->RemoveDuplicateComments();
							}
							commentHolder = outElement->mActionList.get();
							ioCommentContainer->AddCommentHolder(commentHolder);
						}
					}
				}
				else if (childString == kTerminatorsElement) {
						// A terminators element, which must be unique
					if (outElement->mTerminatorsElement.get() != NULL) {
							// Repeated terminators element
						errorMessage = NBundleString(kKeyboardElementRepeatedTerminatorsElement, "", kErrorTableName);
						errorValue = ErrorMessage(XMLRepeatedElementError, errorMessage);
					}
					else {
						TerminatorsElement *terminatorsElement;
						errorValue = TerminatorsElement::CreateFromXMLTree(*childTree, terminatorsElement, ioCommentContainer);
						if (errorValue == XMLNoError) {
							outElement->AddTerminatorsElement(terminatorsElement);
							if (commentHolder != NULL) {
								commentHolder->RemoveDuplicateComments();
							}
							commentHolder = terminatorsElement;
							ioCommentContainer->AddCommentHolder(commentHolder);
						}
					}
				}
				else {
						// Not a valid element
					errorFormat = NBundleString(kKeyboardElementInvalidElementType, "", kErrorTableName);
					errorMessage.Format(errorFormat, childString);
					errorValue = ErrorMessage(XMLBadElementTypeError, errorMessage);
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
				errorFormat = NBundleString(kKeyboardElementWrongNodeType, "", kErrorTableName);
				errorMessage.Format(errorFormat, static_cast<SInt32>(childTree->GetType()));
				errorValue = ErrorMessage(XMLWrongXMLNodeTypeError, errorMessage);
				break;
		}
	}
	if (errorValue == XMLNoError && outElement->mLayouts.get() == NULL) {
			// Missing layouts attribute
		errorMessage = NBundleString(kMissingLayoutsElement, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingLayoutsError, errorMessage);
	}
	if (errorValue == XMLNoError && outElement->mModifierMapList.empty()) {
			// Missing modifierMap element
		errorMessage = NBundleString(kMissingModifierMapElement, "", kErrorTableName);
		errorValue = ErrorMessage(XMLMissingChildrenError, errorMessage);
	}
	if (errorValue == XMLNoError) {
		outElement->mKeyMapSetList->CompleteSet();
		commentHolder->RemoveDuplicateComments();
	}
	else {
			// An error in processing, so delete the partially constructed element
		delete outElement;
		outElement = NULL;
	}
	return errorValue;
}

NXMLNode *KeyboardElement::CreateXMLTree(void)
{
		// Make sure that maxout is correct
	UpdateMaxout();
		// Create the tree
	NXMLNode *xmlTree = new NXMLNode(kNXMLNodeElement, kKeyboardElement);
		// Add the attributes, converting to string as necessary
	NString attributeString;
	attributeString.Format("%d", mGroup);
	xmlTree->SetElementAttribute(kGroupAttribute, attributeString);
	attributeString.Format("%d", mID);
	xmlTree->SetElementAttribute(kIDAttribute, attributeString);
	xmlTree->SetElementAttribute(kNameAttribute, mName);
	attributeString.Format("%d", mMaxout);
	xmlTree->SetElementAttribute(kMaxoutAttribute, attributeString);
		// Add comments
	AddCommentsToXMLTree(*xmlTree);
		// Add the Layouts element
	NXMLNode *childTree = mLayouts->CreateXMLTree();
	xmlTree->AddChild(childTree);
		// Add Modifier Map elements
	ModifierMapConstIterator modIter;
	for (modIter = mModifierMapList.begin(); modIter != mModifierMapList.end(); ++modIter) {
		ModifierMap *childElement = *modIter;
		childTree = childElement->CreateXMLTree();
		xmlTree->AddChild(childTree);
	}
		// Add Key Map Set elements
	SInt32 keyMapSetCount = mKeyMapSetList->GetCount();
	for (SInt32 i = 1; i <= keyMapSetCount; i++) {
		KeyMapSet *keyMapSet = mKeyMapSetList->GetKeyMapSet(i);
		childTree = keyMapSet->CreateXMLTree();
		xmlTree->AddChild(childTree);
	}
		// Add Actions element, if not empty
	if (!mActionList->IsEmpty()) {
		childTree = mActionList->CreateXMLTree();
		xmlTree->AddChild(childTree);
	}
		// Add terminators element, if any
	if (mTerminatorsElement.get() != NULL && mTerminatorsElement->GetWhenElementCount() > 0) {
		childTree = mTerminatorsElement->CreateXMLTree();
		xmlTree->AddChild(childTree);
	}
	return xmlTree;
}

NString KeyboardElement::GetDescription(void)
{
	NString descriptionString;
	descriptionString.Format("keyboard group=%d, id=%d, name=%@, maxout=%d", mGroup, mID, mName, mMaxout);
	return descriptionString;
}

	// Create a basic keyboard element

KeyboardElement *KeyboardElement::CreateBasicKeyboard(NString inName)
{
	SInt32 keyboardID = GetRandomKeyboardID(kTextEncodingMacUnicode);
	KeyboardElement *newKeyboard = new KeyboardElement(kTextEncodingMacUnicode,
													   keyboardID, inName, 1);
	LayoutsElement *layoutsElement = LayoutsElement::CreateBasicLayoutsElement();
	newKeyboard->AddLayoutsElement(layoutsElement);
	ModifierMap *modifierMap = ModifierMap::CreateBasicModifierMap();
	newKeyboard->AddModifierMap(modifierMap);
	KeyMapSet *ansiKeyMapSet = KeyMapSet::CreateBasicKeyMapSet(kANSIKeyMapName, "");
	newKeyboard->AddKeyMapSet(ansiKeyMapSet);
	KeyMapSet *jisKeyMapSet = KeyMapSet::CreateBasicKeyMapSet(kJISKeyMapName, kANSIKeyMapName);
	newKeyboard->AddKeyMapSet(jisKeyMapSet);
	newKeyboard->mKeyMapSetList->CompleteSet();
	return newKeyboard;
}

KeyboardElement *KeyboardElement::CreateStandardKeyboard(NString inName, UInt32 inBaseLayout, UInt32 inCommandLayout, UInt32 inCapsLockLayout) {
	KeyboardElement *newKeyboard = new KeyboardElement(kTextEncodingMacUnicode, GetRandomKeyboardID(kTextEncodingMacUnicode), inName, 1);
	LayoutsElement *layoutsElement = LayoutsElement::CreateBasicLayoutsElement();
	newKeyboard->AddLayoutsElement(layoutsElement);
	bool hasCapsLockLayout = inBaseLayout != inCapsLockLayout;
	bool hasCommandLayout = inBaseLayout != inCommandLayout;
	ModifierMap *modifierMap = ModifierMap::CreateStandardModifierMap(hasCapsLockLayout, hasCommandLayout);
	newKeyboard->AddModifierMap(modifierMap);
	KeyMapSet *ansiKeyMapSet = KeyMapSet::CreateStandardKeyMapSet(kANSIKeyMapName, "", inBaseLayout, inCommandLayout, inCapsLockLayout, modifierMap);
	newKeyboard->AddKeyMapSet(ansiKeyMapSet);
	KeyMapSet *jisKeyMapSet = KeyMapSet::CreateStandardJISKeyMapSet(kJISKeyMapName, kANSIKeyMapName, modifierMap);
	newKeyboard->AddKeyMapSet(jisKeyMapSet);
	newKeyboard->mKeyMapSetList->CompleteSet();
	return newKeyboard;
}

	// Create a keyboard with standard modifiers and some things filled in

KeyboardElement *KeyboardElement::CreateKeyboad(NString inName, UInt32 inScript, UInt32 inStandardKeyboard, UInt32 inCommandKeyboard) {
#pragma unused(inStandardKeyboard)
#pragma unused(inCommandKeyboard)
	SInt32 keyboardID = GetRandomKeyboardID(inScript);
	KeyboardElement *newKeyboard = new KeyboardElement(inScript, keyboardID, inName, 1);
	LayoutsElement *layoutsElement = LayoutsElement::CreateBasicLayoutsElement();
	newKeyboard->AddLayoutsElement(layoutsElement);
	ModifierMap *modifierMap = ModifierMap::CreateStandardModifierMap();
	newKeyboard->AddModifierMap(modifierMap);
	return newKeyboard;
}

#pragma mark -

	// Add a layouts element

void KeyboardElement::AddLayoutsElement(LayoutsElement *inLayoutsElement)
{
	NN_ASSERT(inLayoutsElement != NULL);
	mLayouts.reset(inLayoutsElement);
}

ModifierMap *KeyboardElement::FindModifierMap(NString inID) const
{
	ModifierMap *currentModifierMap = NULL;
	for (ModifierMapConstIterator pos = mModifierMapList.begin(); pos != mModifierMapList.end(); ++pos) {
		currentModifierMap = *pos;
		if (inID == currentModifierMap->GetID()) {
			break;
		}
	}
	return currentModifierMap;
}

	// Get the modifier map for the given keyboard ID

ModifierMap *KeyboardElement::GetModifierMap(const UInt32 inKeyboardID) const
{
		// Find the layout corresponding to the given keyboard ID
	LayoutElement *currentLayout = mLayouts->FindLayout(inKeyboardID);
		// We now need the name of the modifier map
	NString modifierMapName = currentLayout->GetModifiers();
		// Find the modifier map in the list
	return FindModifierMap(modifierMapName);
}

	// Add a modifier map

void KeyboardElement::AddModifierMap(ModifierMap *inModifierMap)
{
	NN_ASSERT(inModifierMap != NULL);
	mModifierMapList.push_back(inModifierMap);
}

	// Add a key map set

void KeyboardElement::AddKeyMapSet(KeyMapSet *inKeyMapSet)
{
	NN_ASSERT(inKeyMapSet != NULL);
	mKeyMapSetList->AddKeyMapSet(inKeyMapSet);
}

	// Add an action list

void KeyboardElement::AddActionList(shared_ptr<ActionElementSet> inActionList)
{
	mActionList = inActionList;
}

	// Add a terminators element

void KeyboardElement::AddTerminatorsElement(TerminatorsElement *inTerminatorsElement)
{
	NN_ASSERT(inTerminatorsElement != NULL);
	mTerminatorsElement.reset(inTerminatorsElement);
}

	// Get the key element corresponding to the key code and the combination of modifiers
	// specified by the parameters, for the given keyboard ID

KeyElement *KeyboardElement::GetKeyElement(const UInt32 inKeyboardID,
										   const UInt32 inKeyCode,
										   const UInt32 inModifierCombination,
										   const bool inUseBaseMapSet) const
{
		// Find the layout corresponding to the given keyboard ID and the correct
		// modifier map
	LayoutElement *currentLayout;
	ModifierMap *currentModifierMap;
	GetLayoutAndModifierMap(inKeyboardID, currentLayout, currentModifierMap);
		// Find appropriate key map
	KeyMapSet *keyMapSet = mKeyMapSetList->FindKeyMapSet(currentLayout->GetMapSet());
	UInt32 keyMapTableNumber = currentModifierMap->GetMatchingKeyMapSelect(inModifierCombination);
	KeyMapElement *keyMapElement = keyMapSet->GetKeyMapElement(keyMapTableNumber);
	KeyElement *keyElement = keyMapElement->GetKeyElement(inKeyCode);
		// If the key element is null, then we have to fall back to the base map
		// set, if any
	while (keyElement == NULL && inUseBaseMapSet && !keyMapElement->GetBaseMapSet().IsEmpty()) {
		keyMapSet = mKeyMapSetList->FindKeyMapSet(keyMapElement->GetBaseMapSet());
		keyMapElement = keyMapSet->GetKeyMapElement(keyMapElement->GetBaseIndex());
		keyElement = keyMapElement->GetKeyElement(inKeyCode);
	}
	if (keyElement == NULL && inUseBaseMapSet) {
		keyElement = new KeyElement(inKeyCode);
		keyMapElement->AddKeyElement(inKeyCode, keyElement);
	}
	return keyElement;
}

	// Add a key element

void KeyboardElement::AddKeyElement(const UInt32 inKeyboardID,
									const UInt32 inKeyCode,
									const UInt32 inModifierCombination,
									KeyElement *inKeyElement)
{
		// Find the layout corresponding to the given keyboard ID and the correct
		// modifier map
	LayoutElement *currentLayout;
	ModifierMap *currentModifierMap;
	GetLayoutAndModifierMap(inKeyboardID, currentLayout, currentModifierMap);
		// Find appropriate key map
	KeyMapSet *keyMapSet = mKeyMapSetList->FindKeyMapSet(currentLayout->GetMapSet());
	UInt32 keyMapTableNumber = currentModifierMap->GetMatchingKeyMapSelect(inModifierCombination);
	KeyMapElement *keyMapElement = keyMapSet->GetKeyMapElement(keyMapTableNumber);
	keyMapElement->AddKeyElement(inKeyCode, inKeyElement);
}

	// Get the character string produced by the given key with the specified
	// combination of modifier keys. Also returns whether the key is a dead key,
	// i.e. it initiates a state without producing immediate output.

NString KeyboardElement::GetCharOutput(const UInt32 inKeyboardID,
									   const UInt32 inKeyCode,
									   const UInt32 inModifierCombination,
									   const NString inState,
									   bool &outDeadKey,
									   NString& outNextState) const
{
	NString outputString("");
	outDeadKey = false;
	KeyElement *keyElement = GetKeyElement(inKeyboardID, inKeyCode, inModifierCombination, true);
	if (keyElement == NULL) {
			// There is no entry for this key combination, so there is no
			// output, and we return the empty string
		return outputString;
	}
	
	switch (keyElement->GetElementType()) {
		case kKeyFormOutput:
			if (inState == kStateNone) {
				outputString = keyElement->GetOutputString();
			}
			break;
			
		case kKeyFormAction:
		case kKeyFormInlineAction: {
			ActionElement *actionElement;
			if (keyElement->GetElementType() == kKeyFormAction) {
				NString actionName = keyElement->GetActionName();
				actionElement = mActionList->FindActionElement(actionName);
			}
			else {
				actionElement = keyElement->GetInlineAction();
			}
			UInt16 keyType = actionElement->GetActionType(inState);
			WhenElement *whenElement = NULL;
			WhenElement *terminatorElement = NULL;
			switch (keyType) {
				case kActionTypeOutput:
					whenElement = actionElement->FindWhenElement(inState);
					outputString = whenElement->GetOutput();
					break;
					
				case kActionTypeTerminator:
						// No output in this state
					break;
					
				case kActionTypeState:
					whenElement = actionElement->FindWhenElement(inState);
					outNextState = whenElement->GetNext();
					NN_ASSERT(!outNextState.IsEmpty());
						// We have to dip into the terminators list
					if (mTerminatorsElement.get() != NULL) {
						terminatorElement = mTerminatorsElement->FindWhenElement(outNextState);
						if (terminatorElement != NULL) {
							outputString = terminatorElement->GetOutput();
						}
					}
					outDeadKey = true;
					break;
			}
		}
			break;
			
		default:
			break;
	}
	return outputString;
}

	// Is the given key a dead key?

bool KeyboardElement::IsDeadKey(const UInt32 inKeyboardID,
								const UInt32 inKeyCode,
								const UInt32 inModifierCombination,
								const NString inState) const
{
	KeyElement *keyElement = GetKeyElement(inKeyboardID, inKeyCode, inModifierCombination, true);
	if (keyElement == NULL) {
			// There is no entry for this key combination, so there is no
			// output, and so it is not a dead key
		return false;
	}
	bool result = false;
	
	UInt32 keyType = keyElement->GetElementType();
	if (keyType == kKeyFormAction || keyType == kKeyFormInlineAction) {
		ActionElement *actionElement;
		if (keyElement->GetElementType() == kKeyFormAction) {
			NString actionName = keyElement->GetActionName();
			actionElement = mActionList->FindActionElement(actionName);
		}
		else {
			actionElement = keyElement->GetInlineAction();
		}
		if (actionElement->GetActionType(inState) == kActionTypeState) {
			result = true;
		}
	}
	return result;
}

	// Get the next state for the given key/modifier/state combination

NString KeyboardElement::GetNextState(const UInt32 inKeyboardID,
									  const UInt32 inKeyCode,
									  const UInt32 inModifierCombination,
									  const NString inState) const
{
	KeyElement *keyElement = GetKeyElement(inKeyboardID, inKeyCode, inModifierCombination, true);
	if (keyElement == NULL) {
			// There is no entry for this key combination, so there is no
			// output, and so it is not a dead key
		return "";
	}
	NString result = "";
	
	UInt32 keyType = keyElement->GetElementType();
	if (keyType == kKeyFormAction || keyType == kKeyFormInlineAction) {
		ActionElement *actionElement;
		if (keyElement->GetElementType() == kKeyFormAction) {
			NString actionName = keyElement->GetActionName();
			actionElement = mActionList->FindActionElement(actionName);
		}
		else {
			actionElement = keyElement->GetInlineAction();
		}
		if (actionElement->GetActionType(inState) == kActionTypeState) {
			WhenElement *whenElement = actionElement->FindWhenElement(inState);
			result = whenElement->GetNext();
		}
	}
	return result;
}

	// Add an action

void KeyboardElement::AddAction(ActionElement *inAction)
{
	mActionList->AddActionElement(inAction);
}

	// Get the action element with the name

ActionElement *KeyboardElement::GetActionElement(const NString inActionName) const
{
	return mActionList->FindActionElement(inActionName);
}

	// Get a key map element

KeyMapElement *KeyboardElement::GetKeyMapElement(const UInt32 inKeyboardID, const UInt32 inModifierCombination) const
{
		// Find the layout corresponding to the given keyboard ID and the correct
		// modifier map
	LayoutElement *currentLayout;
	ModifierMap *currentModifierMap;
	GetLayoutAndModifierMap(inKeyboardID, currentLayout, currentModifierMap);
		// Find appropriate key map
	KeyMapSet *keyMapSet = mKeyMapSetList->FindKeyMapSet(currentLayout->GetMapSet());
	UInt32 keyMapTableNumber = currentModifierMap->GetMatchingKeyMapSelect(inModifierCombination);
	KeyMapElement *keyMapElement = keyMapSet->GetKeyMapElement(keyMapTableNumber);
	return keyMapElement;
}

	// Get a key map set

KeyMapSet *KeyboardElement::GetKeyMapSet(const UInt32 inKeyboardID) const
{
		// Find the layout corresponding to the given keyboard ID and the correct
		// modifier map
	LayoutElement *currentLayout;
	ModifierMap *currentModifierMap;
	GetLayoutAndModifierMap(inKeyboardID, currentLayout, currentModifierMap);
		// Find the appropriate key map
	KeyMapSet *keyMapSet = mKeyMapSetList->FindKeyMapSet(currentLayout->GetMapSet());
	return keyMapSet;
}

KeyMapSet *KeyboardElement::GetKeyMapSet(NString inID) const
{
	return mKeyMapSetList->FindKeyMapSet(inID);
}

	// For a given keyboard, find all the key map sets referenced by it

KeyMapSetList *KeyboardElement::GetKeyMapSetsForKeyboard(const UInt32 inKeyboardID) const
{
		// Find the layout corresponding to the given keyboard ID
	LayoutElement *currentLayout = mLayouts->FindLayout(inKeyboardID);
		// Get the modifier map and find all layouts that use it
	NString modifiersID = currentLayout->GetModifiers();
	LayoutElementList *layoutList = mLayouts->GetLayoutsForModifierMap(modifiersID);
		// For each layout element, get the name of the key map set
	NString mapSetID;
	NSMutableSet *mapSetIDs = [NSMutableSet setWithCapacity:layoutList->size()];
	for (LayoutElementIterator pos = layoutList->begin(); pos != layoutList->end(); ++pos) {
		LayoutElement *theLayout = *pos;
		mapSetID = theLayout->GetMapSet();
		[mapSetIDs addObject:ToNS(mapSetID)];
	}
	layoutList->clear();
	delete layoutList;
	layoutList = NULL;
		// Now go through each key map set and pick out any base maps which haven't
		// yet been added
	SInt32 mapSetIDCount = (SInt32)[mapSetIDs count];
	NArray mapSetIDArray;
	for (NSString *theID in mapSetIDs) {
		mapSetIDArray.AppendValue(ToNN(theID));
	}
	for (SInt32 setIndex = 0; setIndex < mapSetIDCount; setIndex++) {
		mapSetID = mapSetIDArray.GetValueString(setIndex);
		KeyMapSet *keyMapSet = mKeyMapSetList->FindKeyMapSet(mapSetID);
		UInt32 keyMapCount = keyMapSet->GetKeyMapCount();
		for (UInt32 keyMapIndex = 0; keyMapIndex < keyMapCount; keyMapIndex++) {
			KeyMapElement *keyMap = keyMapSet->GetKeyMapElement(keyMapIndex);
			NString baseMapSetID = keyMap->GetBaseMapSet();
			if (!baseMapSetID.IsEmpty()) {
				[mapSetIDs addObject:ToNS(baseMapSetID)];
			}
		}
	}
	mapSetIDArray.Clear();
	for (NSString *theID in mapSetIDs) {
		mapSetIDArray.AppendValue(ToNN(theID));
	}
		// Finally, put the key maps into the result list
	KeyMapSetList *keyMapSetList = new KeyMapSetList;
	mapSetIDCount = (SInt32)[mapSetIDs count];
	for (SInt32 setIndex = 0; setIndex < mapSetIDCount; setIndex++) {
		KeyMapSet *keyMapSet = mKeyMapSetList->FindKeyMapSet(mapSetIDArray.GetValueString(setIndex));
		keyMapSetList->AddKeyMapSet(keyMapSet);
	}
	keyMapSetList->CompleteSet();
	return keyMapSetList;
}

	// Remove the speficied key map select

KeyMapSelect *KeyboardElement::RemoveKeyMapSelect(const UInt32 inKeyboardID,
												  const SInt32 inIndex,
												  KeyMapElementList *outKeyMapList)
{
	ModifierMap *modifierMap = GetModifierMap(inKeyboardID);
	KeyMapSelect *keyMapSelect = modifierMap->RemoveKeyMapSelectElement(inIndex);
	SInt32 numKeyMapSets = mKeyMapSetList->GetCount();
	for (SInt32 i = 1; i <= numKeyMapSets; i++) {
			// Remove the appropriate key map element
		KeyMapSet *keyMapSet = mKeyMapSetList->GetKeyMapSet(i);
		KeyMapElement *keyMap = keyMapSet->RemoveKeyMapElement(inIndex);
		outKeyMapList->InsertKeyMapElementAtIndex(i, keyMap);
	}
	return keyMapSelect;
}

	// Remove a modifier element

ModifierElement *KeyboardElement::RemoveModifierElement(const UInt32 inKeyboardID,
														const SInt32 inIndex,
														const SInt32 inSubIndex)
{
	ModifierMap *modifierMap = GetModifierMap(inKeyboardID);
	assert(modifierMap != NULL);
	KeyMapSelect *keyMapSelect = modifierMap->GetKeyMapSelectElement(inIndex);
	assert(keyMapSelect != NULL);
	ModifierElement *modifierElement = keyMapSelect->RemoveModifierElement(inSubIndex);
	NN_ASSERT(modifierElement != NULL);
	return modifierElement;
}

	// Remove a key element
void KeyboardElement::RemoveKeyElement(const UInt32 inKeyboardID,
									   const UInt32 inKeyCode,
									   const UInt32 inModifierCombination)
{
		// Find the layout corresponding to the given keyboard ID and the correct
		// modifier map
	LayoutElement *currentLayout;
	ModifierMap *currentModifierMap;
	GetLayoutAndModifierMap(inKeyboardID, currentLayout, currentModifierMap);
		// Find appropriate key map
	KeyMapSet *keyMapSet = mKeyMapSetList->FindKeyMapSet(currentLayout->GetMapSet());
	UInt32 keyMapTableNumber = currentModifierMap->GetMatchingKeyMapSelect(inModifierCombination);
	KeyMapElement *keyMapElement = keyMapSet->GetKeyMapElement(keyMapTableNumber);
	keyMapElement->RemoveKeyElement(inKeyCode);
}

	// Create a duplicate of the action with the given name, and return its name

NString KeyboardElement::CreateDuplicateAction(const NString inActionName)
{
	ActionElement *duplicateAction = mActionList->CreateDuplicateActionElement(inActionName);
	return duplicateAction->GetActionID();
}

	// Import a dead key from another keyboard layout

void KeyboardElement::ImportDeadKey(const NString inLocalState,
									const NString inSourceState,
									const KeyboardElement *inSource)
{
		// Handle the key map sets and the actions
	LayoutElement *layoutElement = mLayouts->FindLayout(gestaltUSBAndyANSIKbd);
	NString keyMapID = layoutElement->GetMapSet();
	KeyMapSet *keyMapSet = mKeyMapSetList->FindKeyMapSet(keyMapID);
	LayoutElement *sourceLayoutElement = inSource->mLayouts->FindLayout(gestaltUSBAndyANSIKbd);
	NString sourceKeyMapID = sourceLayoutElement->GetMapSet();
	KeyMapSet *sourceKeyMapSet = inSource->mKeyMapSetList->FindKeyMapSet(sourceKeyMapID);
	keyMapSet->ImportDeadKey(inLocalState, inSourceState, sourceKeyMapSet, mActionList, inSource->mActionList);
	if (mLayouts->FindLayout(gestaltUSBAndyJISKbd) != layoutElement && inSource->mLayouts->FindLayout(gestaltUSBAndyJISKbd) != sourceLayoutElement) {
			// We have JIS overrides for both
		layoutElement = mLayouts->FindLayout(gestaltUSBAndyJISKbd);
		keyMapID = layoutElement->GetMapSet();
		keyMapSet = mKeyMapSetList->FindKeyMapSet(keyMapID);
		sourceLayoutElement = inSource->mLayouts->FindLayout(gestaltUSBAndyJISKbd);
		sourceKeyMapID = sourceLayoutElement->GetMapSet();
		sourceKeyMapSet = inSource->mKeyMapSetList->FindKeyMapSet(sourceKeyMapID);
		keyMapSet->ImportDeadKey(inLocalState, inSourceState, sourceKeyMapSet, mActionList, inSource->mActionList);
	}
//	mKeyMapSetList->ImportDeadKey(inSource->mKeyMapSetList.get(), inLocalState, inSourceState,
//								  mActionList, inSource->mActionList);
		// Handle the terminators
	TerminatorsElement *sourceTerminators = inSource->GetTerminatorsElement();
	if (mTerminatorsElement.get() == NULL) {
		mTerminatorsElement.reset(new TerminatorsElement);
	}
	mTerminatorsElement->ImportDeadKey(inLocalState, sourceTerminators->FindWhenElement(inSourceState));
}

	// Get the terminator of the given state

NString KeyboardElement::GetTerminator(const NString inState) const
{
	WhenElement *terminatorElement = mTerminatorsElement->FindWhenElement(inState);
	NString terminatorString;
	if (terminatorElement == NULL) {
		terminatorString = "";
	}
	else {
		terminatorString = terminatorElement->GetOutput();
	}
	return terminatorString;
}

	// Replace the terminator of the given state

void KeyboardElement::ReplaceTerminator(const NString inState, const NString inNewTerminator)
{
	WhenElement *terminatorElement = mTerminatorsElement->FindWhenElement(inState);
	if (terminatorElement == NULL) {
		terminatorElement = new WhenElement(inState, inNewTerminator, "", "", "");
		mTerminatorsElement->AddWhenElement(terminatorElement);
	}
	else {
		terminatorElement->SetOutput(inNewTerminator);
	}
}

ModifierMapList *KeyboardElement::SimplifiedModifierMaps(void)
{
    ModifierMapList *simplifiedList = new ModifierMapList;
    ModifierMapIterator pos;
    for (pos = mModifierMapList.begin(); pos != mModifierMapList.end(); ++pos) {
        ModifierMap *modifierMap = *pos;
        simplifiedList->push_back(modifierMap->SimplifiedModifierMap());
    }
    return simplifiedList;
}

bool KeyboardElement::HasSimplifiedModifierMaps(void)
{
    ModifierMapIterator pos;
    for (pos = mModifierMapList.begin(); pos != mModifierMapList.end(); ++pos) {
        if (!(*pos)->IsSimplified()) {
            return false;
        }
    }
    return true;
}

NStringList *KeyboardElement::KeyMapsForModifierMap(NString inModifierMapID) {
	NStringList *result = mLayouts->GetKeyMapsForModifierMap(inModifierMapID);
		// Add any base maps to the list
	NStringListIterator pos;
	for (pos = result->begin(); pos != result->end(); ++pos) {
		NString keyMapID = *pos;
		KeyMapSet *keyMapSet = mKeyMapSetList->FindKeyMapSet(keyMapID);
			// Get the base maps
		NStringList baseMapNames = keyMapSet->GetBaseMaps();
		NStringListIterator baseMapPos;
		for (baseMapPos = baseMapNames.begin(); baseMapPos != baseMapNames.end(); ++baseMapPos) {
			NString baseMapName = *baseMapPos;
				// Add if we don't already have it
			if (std::find(result->begin(), result->end(), baseMapName) == result->end()) {
				result->push_back(baseMapName);
			}
		}
	}
	return result;
}

#pragma mark -

	// Change a modifier element

void KeyboardElement::ChangeModifierElement(const UInt32 inKeyboardID,
											const UInt32 inIndex,
											const UInt32 inSubIndex,
											const UInt32 inShift,
											const UInt32 inCapsLock,
											const UInt32 inOption,
											const UInt32 inCommand,
											const UInt32 inControl)
{
	ModifierMap *modifierMap = GetModifierMap(inKeyboardID);
	KeyMapSelect *keyMapSelect = modifierMap->GetKeyMapSelectElement(inIndex);
	assert(keyMapSelect != NULL);
	ModifierElement *modifierElement = keyMapSelect->GetModifierElement(inSubIndex);
	modifierElement->SetModifierStatus(inShift, inCapsLock, inOption, inCommand, inControl);
}

void KeyboardElement::ChangeDeadKeyNextState(const UInt32 inKeyboardID,
											 const UInt32 inKeyCode,
											 const UInt32 inModifierCombination,
											 const NString inState,
											 const NString inNewState)
{
	KeyElement *keyElement = GetKeyElement(inKeyboardID, inKeyCode, inModifierCombination, true);
	ActionElement *actionElement = NULL;
	switch (keyElement->GetElementType()) {
		case kKeyFormAction: {
			NString actionName = keyElement->GetActionName();
			actionElement = mActionList->FindActionElement(actionName);
		}
			break;
			
		case kKeyFormInlineAction:
			actionElement = keyElement->GetInlineAction();
			break;
	}
	assert(actionElement != NULL);
	WhenElement *whenElement = actionElement->FindWhenElement(inState);
	assert(whenElement != NULL);
	whenElement->SetNext(inNewState);
}

void KeyboardElement::MakeKeyDeadKey(const UInt32 inKeyboardID,
									 const UInt32 inKeyCode,
									 const UInt32 inModifierCombination,
									 const NString inState,
									 const NString inNewState)
{
	KeyElement *keyElement = GetKeyElement(inKeyboardID, inKeyCode, inModifierCombination, true);
	if (keyElement == NULL) {
		keyElement = new KeyElement(inKeyCode);
		AddKeyElement(inKeyboardID, inKeyCode, inModifierCombination, keyElement);
	}
	keyElement->MakeDeadKey(inState, inNewState, mActionList);
}

void KeyboardElement::MakeDeadKeyOutput(const UInt32 inKeyboardID,
										const UInt32 inKeyCode,
										const UInt32 inModifierCombination,
										const NString inState,
										const NString inNewOutput)
{
	KeyElement *keyElement = GetKeyElement(inKeyboardID, inKeyCode, inModifierCombination, true);
	assert(keyElement != NULL);
	NString oldState = keyElement->ChangeDeadKeyToOutput(inState, inNewOutput, mActionList);
	NN_ASSERT(oldState != "");
}

ModifierMapList *KeyboardElement::ReplaceModifierMaps(ModifierMapList *inNewModifierMapList)
{
    ModifierMapList *oldList = new ModifierMapList;
    ModifierMapIterator pos;
    for (pos = mModifierMapList.begin(); pos != mModifierMapList.end(); ++pos) {
        oldList->push_back(*pos);
    }
    mModifierMapList.clear();
    for (pos = inNewModifierMapList->begin(); pos != inNewModifierMapList->end(); ++pos) {
        mModifierMapList.push_back(*pos);
    }
    return oldList;
}

void KeyboardElement::MoveModifierMap(const UInt32 inFromIndex, const UInt32 inToIndex, const UInt32 inKeyboardID) {
	LayoutElement *layout = mLayouts->FindLayout(inKeyboardID);
	NString modifiersName = layout->GetModifiers();
	ModifierMap *modifierMap = GetModifierMap(inKeyboardID);
		// Calculate the mappings involved
	std::vector<SInt32> indexMap;
	SInt32 keyMapSelectCount = modifierMap->GetKeyMapSelectCount();
	for (SInt32 j = 0; j < keyMapSelectCount; j++) {
		if (modifierMap->GetKeyMapSelectElement(j)) {
			indexMap.push_back(j);
		}
	}
	std::vector<SInt32> reverseIndexMap;
	reverseIndexMap.insert(reverseIndexMap.begin(), keyMapSelectCount, -1);
	UInt32 i;
	for (i = 0; i < indexMap.size(); i++) {
		reverseIndexMap[indexMap[i]] = i;
	}
	std::vector<SInt32> newIndexes;
	newIndexes.insert(newIndexes.begin(), keyMapSelectCount, -1);
	UInt32 lowerBound, upperBound;
	if (inFromIndex < inToIndex) {
		lowerBound = inFromIndex;
		upperBound = inToIndex;
	}
	else {
		lowerBound = inToIndex;
		upperBound = inFromIndex;
	}
		// Handle the unchanging entries
	for (i = 0; i < (UInt32)lowerBound; i++) {
		if (modifierMap->GetKeyMapSelectElement(i)) {
			newIndexes[i] = i;
		}
	}
	for (i = upperBound + 1; i < (UInt32)keyMapSelectCount; i++) {
		if (modifierMap->GetKeyMapSelectElement(i)) {
			newIndexes[i] = i;
		}
	}
	newIndexes[inFromIndex] = inToIndex;
	if (inFromIndex > inToIndex) {
			// Moving it to a lower index
		for (i = inToIndex; i < (UInt32)inFromIndex; i++) {
			SInt32 oldIndex = reverseIndexMap[i];
			if (oldIndex == -1) {
				newIndexes[i] = -1;
			}
			else {
				newIndexes[i] = indexMap[oldIndex + 1];
			}
		}
	}
	else {
			// Moving it to a higher index
		for (i = inFromIndex + 1; i <= (UInt32)inToIndex; i++) {
			SInt32 oldIndex = reverseIndexMap[i];
			if (oldIndex == -1) {
				newIndexes[i] = -1;
			}
			else {
				newIndexes[i] = indexMap[oldIndex - 1];
			}
		}
	}
		// Now that we have the mappings, we can rearrange the modifier map
	modifierMap->RenumberKeyMapSelects(newIndexes);
		// Find out which key map sets are referenced by these modifiers
	NStringList *mapNames = KeyMapsForModifierMap(modifiersName);
		// For each key map set, move the key maps within it
	for (NStringListIterator pos = mapNames->begin(); pos != mapNames->end(); ++pos) {
		NString mapName = *pos;
		KeyMapSet *keyMapSet = mKeyMapSetList->FindKeyMapSet(mapName);
		keyMapSet->RenumberKeyMaps(newIndexes);
	}
}

#pragma mark -

	// GetRandomKeyboardID: Static method to generate a random ID for a
	// keyboard in the given script

SInt32 KeyboardElement::GetRandomKeyboardID(const SInt32 inScriptCode)
{
	SInt32 minID = 0;
	SInt32 maxID = 0;
	switch (inScriptCode) {
		case kTextEncodingMacUnicode:
			minID = kIDMinimumUnicode;
			maxID = kIDMaximumUnicode;
			break;
			
		case kTextEncodingMacRoman:
			minID = kIDMinimumRoman;
			maxID = kIDMaximumRoman;
			break;
			
		case kTextEncodingMacJapanese:
			minID = kIDMinimumJapanese;
			maxID = kIDMaximumJapanese;
			break;
			
		case kTextEncodingMacChineseSimp:
			minID = kIDMinimumSimplifiedChinese;
			maxID = kIDMaximumSimplifiedChinese;
			break;
			
		case kTextEncodingMacChineseTrad:
			minID = kIDMinimumTraditionalChinese;
			maxID = kIDMaximumTraditionalChinese;
			break;
			
		case kTextEncodingMacKorean:
			minID = kIDMinimumKorean;
			maxID = kIDMaximumKorean;
			break;
			
		case kTextEncodingMacCyrillic:
			minID = kIDMinimumCyrillic;
			maxID = kIDMaximumCyrillic;
			break;
			
		case kTextEncodingMacCentralEurRoman:
			minID = kIDMinimumCentralEuropean;
			maxID = kIDMaximumCentralEuropean;
			break;
	}
	RandomNumberGenerator *randomGenerator = RandomNumberGenerator::GetInstance();
	SInt32 result = randomGenerator->GetRandomSInt32(minID, maxID);
	return result;
}

bool KeyboardElement::HasValidID() {
	SInt32 minID = 0;
	SInt32 maxID = 0;
	switch (mGroup) {
		case kTextEncodingMacUnicode:
			minID = kIDMinimumUnicode;
			maxID = kIDMaximumUnicode;
			break;
			
		case kTextEncodingMacRoman:
			minID = kIDMinimumRoman;
			maxID = kIDMaximumRoman;
			break;
			
		case kTextEncodingMacJapanese:
			minID = kIDMinimumJapanese;
			maxID = kIDMaximumJapanese;
			break;
			
		case kTextEncodingMacChineseSimp:
			minID = kIDMinimumSimplifiedChinese;
			maxID = kIDMaximumSimplifiedChinese;
			break;
			
		case kTextEncodingMacChineseTrad:
			minID = kIDMinimumTraditionalChinese;
			maxID = kIDMaximumTraditionalChinese;
			break;
			
		case kTextEncodingMacKorean:
			minID = kIDMinimumKorean;
			maxID = kIDMaximumKorean;
			break;
			
		case kTextEncodingMacCyrillic:
			minID = kIDMinimumCyrillic;
			maxID = kIDMaximumCyrillic;
			break;
			
		case kTextEncodingMacCentralEurRoman:
			minID = kIDMinimumCentralEuropean;
			maxID = kIDMaximumCentralEuropean;
			break;
	}
	return mID >= minID && mID <= maxID;
}

#pragma mark -

	// Get all the action names

NArray KeyboardElement::GetActionNames(void) const
{
	return mActionList->GetActionNames();
}

	// Change an action name to a new name

void KeyboardElement::ChangeActionName(const NString inOldName, const NString inNewName)
{
		// Change the actions in the key map sets
	mKeyMapSetList->ChangeActionName(inOldName, inNewName);
		// Rename the action in the action list
	ActionElement *actionElement = mActionList->RemoveActionElement(inOldName);
	actionElement->SetActionID(inNewName);
	mActionList->AddActionElement(actionElement);
}

	// Is there an action with the given name?

bool KeyboardElement::ActionExists(const NString inActionName) const
{
	return mActionList->ActionExists(inActionName);
}

	// Remove actions that are not referenced

shared_ptr<ActionElementSet> KeyboardElement::RemoveUnusedActions(void)
{
	NSSet *usedActions = mKeyMapSetList->GetUsedActions();
	NArray allActions = mActionList->GetActionNames();
	UInt32 actionCount = allActions.GetSize();
	NArray unusedActions;
	NString actionName;
	for (UInt32 i = 0; i < actionCount; i++) {
		actionName = allActions.GetValueString(i);
		if (![usedActions containsObject:ToNS(actionName)]) {
			unusedActions.AppendValue(actionName);
		}
	}
	shared_ptr<ActionElementSet> removedActions(new ActionElementSet);
	actionCount = unusedActions.GetSize();
	for (UInt32 u = 0; u < actionCount; u++) {
		actionName = unusedActions.GetValueString(u);
		ActionElement *oldElement = mActionList->RemoveActionElement(actionName);
		removedActions->AddActionElement(oldElement);
	}
	return removedActions;
}

void KeyboardElement::ReplaceActions(shared_ptr<ActionElementSet> inActions)
{
	for (ActionElement *actionElement = inActions->GetFirstElement(); actionElement != NULL; actionElement = inActions->GetNextElement()) {
		mActionList->AddActionElement(actionElement);
	}
}

#pragma mark -

	// Is there a state with the given name?

bool KeyboardElement::StateExists(const NString inStateName)
{
	NSSet *stateNames = GetStateNameSet(kAllStates);
	return [stateNames containsObject:ToNS(inStateName)];
}

	// Create a new state name

NString KeyboardElement::CreateStateName(void)
{
	NString baseStateName = "State";
//	NCFPreferences *thePrefs = NCFPreferences::GetPrefs();
//	if (thePrefs->HasKey(kPrefBaseStateName)) {
//		baseStateName = thePrefs->GetValueString(kPrefBaseStateName);
//	}
//	else {
//		NApplication *theApp = NApplication::GetApp();
//		NN_ASSERT(theApp != NULL);
//		NDictionary *theProperties = theApp->GetProperties();
//		NN_ASSERT(theProperties != NULL);
//		baseStateName = theProperties->GetValueString(kPrefBaseStateName);
//	}
	return CreateStateName(baseStateName);
}

NString KeyboardElement::CreateStateName(NString inBaseName)
{
	NSSet *stateNames = GetStateNameSet(kAllStates);
	NString candidateName;
	for (UInt32 i = 0; i < kStateMaximum; i++) {
		candidateName.Format(kStateNameGenerator, inBaseName, i);
		if (![stateNames containsObject:ToNS(candidateName)]) {
			break;
		}
	}
	return candidateName;
}

	// Create a new state with the given name and terminator string

void KeyboardElement::CreateState(const NString inStateName, const NString inTerminatorString)
{
	WhenElement *whenElement = new WhenElement(inStateName, inTerminatorString, "", "", "");
	if (mTerminatorsElement.get() == NULL) {
		AddTerminatorsElement(new TerminatorsElement);
	}
	mTerminatorsElement->AddWhenElement(whenElement);
}

	// Get the next state

NString KeyboardElement::GetNextState(const UInt32 inKeyboardID,
									  const UInt32 inKeyCode,
									  const UInt32 inModifierCombination,
									  const NString inState,
									  bool& outDeadKey) const
{
	outDeadKey = false;
	KeyElement *keyElement = GetKeyElement(inKeyboardID, inKeyCode, inModifierCombination, true);
	if (keyElement == NULL) {
			// There is no entry for this key combination, so we simply return
			// the current state.
		return inState;
	}
	NString resultState;
	switch (keyElement->GetElementType()) {
		case kKeyFormOutput:
			resultState = inState;
			break;
			
		case kKeyFormAction:
		case kKeyFormInlineAction: {
			ActionElement *actionElement;
			if (keyElement->GetElementType() == kKeyFormAction) {
				NString actionName = keyElement->GetActionName();
				actionElement = mActionList->FindActionElement(actionName);
			}
			else {
				actionElement = keyElement->GetInlineAction();
			}
			UInt16 keyType = actionElement->GetActionType(inState);
			WhenElement *whenElement = NULL;
			switch (keyType) {
				case kOutputType:
					whenElement = actionElement->FindWhenElement(inState);
					resultState = whenElement->GetNext();
					if (resultState.IsEmpty()) {
						resultState = inState;
					}
					break;
					
				case kTerminatorType:
					resultState = inState;
					break;
					
				case kStateType:
					whenElement = actionElement->FindWhenElement(inState);
					resultState = whenElement->GetNext();
					outDeadKey = true;
					break;
			}
		}
			break;
	}
	return resultState;
}

	// Get all the state names

NArray KeyboardElement::GetStateNames(const NString inOmitName, const UInt32 inReachable)
{
	NSMutableSet *stateNames = GetStateNameSet(inReachable);
	[stateNames removeObject:ToNS(kStateNone)];
	if (!inOmitName.IsEmpty()) {
		[stateNames removeObject:ToNS(inOmitName)];
	}
	NArray stateNameList;
	for (NSString *stateName in stateNames) {
		stateNameList.AppendValue(ToNN(stateName));
	}
	stateNameList.Sort();
	return stateNameList;
}

NArray KeyboardElement::GetStateNames(const NArray inOmitStates, const UInt32 inReachable)
{
	NSMutableSet *stateNames = GetStateNameSet(inReachable);
	NIndex arraySize = inOmitStates.GetSize();
	for (NIndex index = 0; index < arraySize; index++) {
		NString omitState = inOmitStates.GetValueString(index);
		[stateNames removeObject:ToNS(omitState)];
	}
	NArray stateNameList;
	for (NSString *stateName in stateNames) {
		stateNameList.AppendValue(ToNN(stateName));
	}
	stateNameList.Sort();
	return stateNameList;
}

	// Replace a state name

void KeyboardElement::ReplaceStateName(const NString inOldName, const NString inNewName)
{
		// Replace the state name in the actions
	ActionElement *actionElement;
	for (actionElement = mActionList->GetFirstElement(); actionElement != NULL;
		 actionElement = mActionList->GetNextElement()) {
		actionElement->ReplaceStateName(inOldName, inNewName);
	}
		// Replace state name in inline actions in key elements
	mKeyMapSetList->ReplaceStateName(inOldName, inNewName);
		// Replace state name in the terminators
	mTerminatorsElement->ReplaceStateName(inOldName, inNewName);
}

RemoveStateData *KeyboardElement::RemoveState(const NString inState) {
	RemoveStateData *stateData = [[RemoveStateData alloc] init];
	RemoveStateDataBlock *dataBlock;
	if (HasInlineAction()) {
		dataBlock = new RemoveStateDataBlock(shared_ptr<KeyMapSetList>(), mActionList, mTerminatorsElement);
	}
	else {
		dataBlock = new RemoveStateDataBlock(mKeyMapSetList, mActionList, mTerminatorsElement);
	}
	[stateData setDataBlock:dataBlock];
	NSSet *statesToRemove = [NSSet setWithObject:ToNS(inState)];
	ActionElement *actionElement;
	for (actionElement = mActionList->GetFirstElement(); actionElement != NULL; actionElement = mActionList->GetNextElement()) {
		actionElement->RemoveStates(statesToRemove);
	}
	mKeyMapSetList->RemoveStates(statesToRemove);
	if (mTerminatorsElement.get() != NULL) {
		mTerminatorsElement->RemoveStates(statesToRemove);
	}
	return stateData;
}

	// Remove all states that are not reachable

RemoveStateData *KeyboardElement::RemoveUnusedStates(void)
{
	RemoveStateData *stateData = nil;
	NSMutableSet *allStates = GetStateNameSet(kAllStates);
	NSMutableSet *reachableStates = GetStateNameSet(kReachableStates);
		// Remove state "none"
	[allStates removeObject:ToNS(kStateNone)];
		// Remove the reachable states
	NArray reachableStateList;
	for (NSString *stateName in reachableStates) {
		reachableStateList.AppendValue(ToNN(stateName));
	}
	SInt32 stateCount = reachableStateList.GetSize();
	for (SInt32 i = 0; i < stateCount; i++) {
		NString stateName = reachableStateList.GetValueString(i);
		[allStates removeObject:ToNS(stateName)];
	}
		// We now have only the unreachable state names in allStates.
		// Run through the layout and remove references to them.
	if ([allStates count] > 0) {
		stateData = [[RemoveStateData alloc] init];
		RemoveStateDataBlock *dataBlock;
		if (HasInlineAction()) {
			dataBlock = new RemoveStateDataBlock(shared_ptr<KeyMapSetList>(), mActionList, mTerminatorsElement);
		}
		else {
			dataBlock = new RemoveStateDataBlock(mKeyMapSetList, mActionList, mTerminatorsElement);
		}
		[stateData setDataBlock:dataBlock];
		ActionElement *actionElement;
		for (actionElement = mActionList->GetFirstElement(); actionElement != NULL;
			 actionElement = mActionList->GetNextElement()) {
			actionElement->RemoveStates(allStates);
		}
		mKeyMapSetList->RemoveStates(allStates);
			// Remove states from terminators
		if (mTerminatorsElement.get() != NULL) {
			mTerminatorsElement->RemoveStates(allStates);
		}
	}
	return stateData;
}

void KeyboardElement::ReplaceRemovedStates(RemoveStateData *inStateData)
{
	if (nil == inStateData) {
		return;
	}
	RemoveStateDataBlock *dataBlock = [inStateData dataBlock];
	if (NULL != dataBlock->KeyMapSets().get()) {
		mKeyMapSetList = dataBlock->KeyMapSets();
	}
	mActionList = dataBlock->ActionElements();
	mTerminatorsElement = dataBlock->Terminators();
}

#pragma mark -

bool KeyboardElement::NeedsRepair() {
	bool result = false;
	if (IsMissingSpecialKeyOutput()) {
		result = true;
		mRepairsNeeded |= kRepairMissingSpecialKeyOutput;
	}
	if (!HasValidID()) {
		result = true;
		mRepairsNeeded |= kRepairInvalidKeyboardID;
	}
	if (mKeyMapSetList->HasKeyMapSetGap()) {
		result = true;
		mRepairsNeeded |= kRepairKeyMapSetGap;
	}
	if (mKeyMapSetList->HasInvalidBaseIndex()) {
		result = true;
		mRepairsNeeded |= kRepairInvalidBaseIndex;
	}
	if (HasExtraKeyMapSet()) {
		result = true;
		mRepairsNeeded |= kRepairExtraKeyMapSet;
	}
	return result;
}

	// Does any key map have an indirect base map reference, i.e. a key map refers
	// to a base map with an index other than its own?

bool KeyboardElement::HasIndirectBaseMapReference(void) const
{
	bool result = false;
	UInt32 numKeyMapSets = mKeyMapSetList->GetCount();
	for (UInt32 keyMapSetIndex = 1; keyMapSetIndex <= numKeyMapSets && !result; keyMapSetIndex++) {
		KeyMapSet *keyMapSet = mKeyMapSetList->GetKeyMapSet(keyMapSetIndex);
		UInt32 numKeyMaps = keyMapSet->GetKeyMapCount();
		for (UInt32 keyMapIndex = 0; keyMapIndex < numKeyMaps && !result; keyMapIndex++) {
			KeyMapElement *keyMap = keyMapSet->GetKeyMapElement(keyMapIndex);
			if (keyMap != NULL && !keyMap->GetBaseMapSet().IsEmpty()) {
				result = keyMap->GetBaseIndex() != keyMapIndex;
			}
		}
	}
	return result;
}

	// Does any action use a multiplier?

bool KeyboardElement::HasMultiplierAction(void) const
{
	bool result = false;
		// First, look through the action list
	if (mActionList->HasMultiplierAction()) {
		return true;
	}
		// Now go through all the key elements to find any inline actions
	SInt32 numKeyMapSets = mKeyMapSetList->GetCount();
	for (SInt32 keyMapSetIndex = 1; keyMapSetIndex <= numKeyMapSets && !result; keyMapSetIndex++) {
		KeyMapSet *keyMapSet = mKeyMapSetList->GetKeyMapSet(keyMapSetIndex);
		SInt32 numKeyMaps = keyMapSet->GetKeyMapCount();
		for (SInt32 keyMapIndex = 0; keyMapIndex < numKeyMaps && !result; keyMapIndex++) {
			KeyMapElement *keyMapElement = keyMapSet->GetKeyMapElement(keyMapIndex);
			SInt32 numKeyElements = keyMapElement == NULL ? 0 : keyMapElement->GetKeyElementCount();
			for (SInt32 keyIndex = 0; keyIndex < numKeyElements && !result; keyIndex++) {
				KeyElement *keyElement = keyMapElement->GetKeyElement(keyIndex);
				if (keyElement != NULL && keyElement->GetElementType() == kKeyFormInlineAction) {
					result = keyElement->GetInlineAction()->HasMultiplierElement();
				}
			}
		}
	}
	if (result) {
		return result;
	}
		// Finally, go through the terminators
	if (mTerminatorsElement.get() != NULL) {
		result = mTerminatorsElement->HasMultiplier();
	}
	return result;
}

	// Are any actions named but not defined?

bool KeyboardElement::HasMissingActions(NArray *outActions) const
{
	bool result = false;
	NSMutableSet *missingActions = [NSMutableSet setWithCapacity:128];
		// Go through all the key elements to find any action names
	SInt32 numKeyMapSets = mKeyMapSetList->GetCount();
	for (SInt32 keyMapSetIndex = 1; keyMapSetIndex <= numKeyMapSets; keyMapSetIndex++) {
		KeyMapSet *keyMapSet = mKeyMapSetList->GetKeyMapSet(keyMapSetIndex);
		SInt32 numKeyMaps = keyMapSet->GetKeyMapCount();
		for (SInt32 keyMapIndex = 0; keyMapIndex < numKeyMaps; keyMapIndex++) {
			KeyMapElement *keyMapElement = keyMapSet->GetKeyMapElement(keyMapIndex);
			SInt32 numKeyElements = keyMapElement == NULL ? 0 : keyMapElement->GetKeyElementCount();
			for (SInt32 keyIndex = 0; keyIndex < numKeyElements; keyIndex++) {
				KeyElement *keyElement = keyMapElement->GetKeyElement(keyIndex);
				if (keyElement != NULL && keyElement->GetElementType() == kKeyFormAction) {
						// Get the action name and see if it exists
					NString actionName = keyElement->GetActionName();
					if (mActionList->FindActionElement(actionName) == NULL) {
						result = true;
						[missingActions addObject:ToNS(actionName)];
					}
				}
			}
		}
	}
	if (result) {
		outActions->Clear();
		for (NSString *actionName in missingActions) {
			outActions->AppendValue(ToNN(actionName));
		}
		outActions->Sort();
	}
	return result;
}

	// Is any special key output missing?

bool KeyboardElement::IsMissingSpecialKeyOutput(void) const
{
	return mKeyMapSetList->IsMissingSpecialKeyOutput();
}

	// Does the given keyboard layout have an equivalent modifier map, i.e. all
	// the modifier combinations map to the same values?

bool KeyboardElement::HasEquivalentModifierMap(const KeyboardElement *inKeyboard) const
{
		// Check that there are the same number of modifier maps
	if (mModifierMapList.size() != inKeyboard->mModifierMapList.size()) {
		return false;
	}
		// Check that each modifier map is equivalent
	ModifierMapConstIterator pos1 = mModifierMapList.begin();
	ModifierMapConstIterator pos2 = inKeyboard->mModifierMapList.begin();
	while (pos1 != mModifierMapList.end()) {
		ModifierMap *map1 = *pos1;
		ModifierMap *map2 = *pos2;
		if (!map1->IsEquivalent(map2)) {
			return false;
		}
		++pos1;
		++pos2;
	}
	return true;
}

	// Is any referenced keyMapSet missing?

bool KeyboardElement::IsMissingKeyMapSets(NStringList& outMissingKeyMapSets) const
{
	bool result = false;
	NStringList *keyMapSetList = mLayouts->GetKeyMapSetNames();
	NStringList baseMapSetList = mKeyMapSetList->GetKeyMapSets();
	keyMapSetList->insert(keyMapSetList->end(), baseMapSetList.begin(), baseMapSetList.end());
	for (NStringListIterator pos = keyMapSetList->begin(); pos != keyMapSetList->end(); ++pos) {
		if (mKeyMapSetList->FindKeyMapSet(*pos) == NULL) {
				// This keyMapSet is missing
			result = true;
			outMissingKeyMapSets.push_back(*pos);
		}
	}
	return result;
}

	// Is any referenced keyMap missing?

bool KeyboardElement::IsMissingKeyMap(NString& outModifierMapID, NString& outKeyMapSetID, UInt32& outKeyMapIndex) const
{
	for (ModifierMapConstIterator pos = mModifierMapList.begin(); pos != mModifierMapList.end(); ++pos) {
		ModifierMap *modifierMap = *pos;
		std::vector<UInt32> indexReferences = modifierMap->GetReferencedIndices();
		UInt32 indexListSize = static_cast<UInt32>(indexReferences.size());
		UInt32 keyMapSetCount = mKeyMapSetList->GetCount();
		for (UInt32 i = 1; i <= keyMapSetCount; i++) {
			KeyMapSet *keyMapSet = mKeyMapSetList->GetKeyMapSet(i);
			for (UInt32 j = 0; j < indexListSize; j++) {
				if (j >= keyMapSet->GetKeyMapCount() || keyMapSet->GetKeyMapElement(indexReferences[j]) == NULL) {
					outModifierMapID = modifierMap->GetID();
					outKeyMapSetID = keyMapSet->GetID();
					outKeyMapIndex = indexReferences[j];
					return true;
				}
			}
		}
	}
	return false;
}

bool KeyboardElement::HasExtraKeyMapSet(void) const {
	bool result = false;
	for (ModifierMapConstIterator pos = mModifierMapList.begin(); !result && pos != mModifierMapList.end(); ++pos) {
		ModifierMap *modMap = *pos;
		NStringList *keyMapSetIDs = mLayouts->GetKeyMapsForModifierMap(modMap->GetID());
		UInt32 modifierCount = modMap->GetKeyMapSelectCount();
		for (NStringListIterator keyMaps = keyMapSetIDs->begin(); keyMaps != keyMapSetIDs->end(); ++keyMaps) {
			KeyMapSet *keyMapSet = mKeyMapSetList->FindKeyMapSet(*keyMaps);
			if (keyMapSet == NULL) {
					// Missing key map set
				result = true;
				break;
			}
			if (keyMapSet->GetKeyMapCount() > modifierCount) {
					// Extra key maps
				result = true;
				break;
			}
		}
	}
	return result;
}

bool KeyboardElement::HasInlineAction(void) const
{
	return mKeyMapSetList->HasInlineAction();
}

#pragma mark -

	// Repair problems in the JIS mapping caused by early versions of Ukelele.
	// Returns true if the repair was needed (and done).

bool KeyboardElement::RepairJIS(void)
{
	bool isRepaired = false;
	if (mKeyMapSetList.get() == NULL) {
		return isRepaired;
	}
	KeyMapSet *keyMapSet = mKeyMapSetList->FindKeyMapSet(kJISKeyMapName);
	if (keyMapSet == NULL) {
		return isRepaired;
	}
	SInt32 keyMapCount = keyMapSet->GetKeyMapCount();
	bool isRelative = false;
	bool hasEmptyKeyMap = false;
	for (SInt32 i = 0; i < keyMapCount; i++) {
		KeyMapElement *keyMap = keyMapSet->GetKeyMapElement(i);
		if (!keyMap->GetBaseMapSet().IsEmpty()) {
			isRelative = true;
			break;
		}
		if (keyMap->IsEmpty()) {
			hasEmptyKeyMap = true;
		}
	}
	if (!isRelative && hasEmptyKeyMap) {
		keyMapSet->MakeRelative(kANSIKeyMapName);
		isRepaired = true;
	}
	return isRepaired;
}

	// Add any missing special key output

AddMissingOutputData *KeyboardElement::AddSpecialKeyOutput(void)
{
	AddMissingOutputData *data = [[AddMissingOutputData alloc] init];
	AddMissingOutputDataBlock *dataBlock = new AddMissingOutputDataBlock(mKeyMapSetList);
	[data setDataBlock:dataBlock];
	mKeyMapSetList->AddSpecialKeyOutput();
	return data;
}

	// Replace the old output data

void KeyboardElement::ReplaceOldOutput(AddMissingOutputData *oldData)
{
	mKeyMapSetList = [oldData dataBlock]->keyMapSetList();
}

#pragma mark -

	// Swap two keys

void KeyboardElement::SwapKeys(const UInt32 inKeyCode1, const UInt32 inKeyCode2)
{
	SInt32 listSize = mKeyMapSetList->GetCount();
	for (SInt32 i = 1; i <= listSize; i++) {
		KeyMapSet *keyMapSet = mKeyMapSetList->GetKeyMapSet(i);
		keyMapSet->SwapKeys(inKeyCode1, inKeyCode2);
	}
}

#pragma mark -

	// Build a key bundle

shared_ptr<KeyElementBundle> KeyboardElement::BuildKeyBundle(const UInt32 inKeyCode) const
{
	shared_ptr<KeyElementBundle> theBundle(new KeyElementBundle);
	SInt32 keyMapSetCount = mKeyMapSetList->GetCount();
	for (SInt32 keyMapSetIndex = 1; keyMapSetIndex <= keyMapSetCount; keyMapSetIndex++) {
		KeyMapSet *keyMapSet = mKeyMapSetList->GetKeyMapSet(keyMapSetIndex);
		SInt32 keyMapCount = keyMapSet->GetKeyMapCount();
		for (SInt32 keyMapIndex = 0; keyMapIndex < keyMapCount; keyMapIndex++) {
			KeyMapElement *keyMapElement = keyMapSet->GetKeyMapElement(keyMapIndex);
			KeyElement *keyElement = keyMapElement->GetKeyElement(inKeyCode);
			theBundle->AddKeyElement(keyMapSetIndex - 1, keyMapIndex, keyElement);
		}
	}
	return theBundle;
}

	// Make the value of the key bundle the actual value of the keys

void KeyboardElement::SetKeyBundle(const UInt32 inKeyCode, shared_ptr<KeyElementBundle> inKeyBundle)
{
	SInt32 keyMapSetCount = mKeyMapSetList->GetCount();
	for (SInt32 keyMapSetIndex = 1; keyMapSetIndex <= keyMapSetCount; keyMapSetIndex++) {
		KeyMapSet *keyMapSet = mKeyMapSetList->GetKeyMapSet(keyMapSetIndex);
		SInt32 keyMapCount = keyMapSet->GetKeyMapCount();
		for (SInt32 keyMapIndex = 0; keyMapIndex < keyMapCount; keyMapIndex++) {
			KeyMapElement *keyMapElement = keyMapSet->GetKeyMapElement(keyMapIndex);
			KeyElement *keyElement = inKeyBundle->GetKeyElement(keyMapSetIndex - 1, keyMapIndex);
			KeyElement *newKeyElement = keyElement != NULL ? new KeyElement(*keyElement) : NULL;
			if (newKeyElement) {
				newKeyElement->ChangeKeyCode(inKeyCode);
			}
			keyMapElement->AddKeyElement(inKeyCode, newKeyElement);
		}
	}
}

	// Cut the key elements with the given key code, and add them to the bundle

void KeyboardElement::CutKeyBundle(const UInt32 inKeyCode, shared_ptr<KeyElementBundle> ioKeyBundle)
{
	SInt32 keyMapSetCount = mKeyMapSetList->GetCount();
	for (SInt32 keyMapSetIndex = 1; keyMapSetIndex <= keyMapSetCount; keyMapSetIndex++) {
		KeyMapSet *keyMapSet = mKeyMapSetList->GetKeyMapSet(keyMapSetIndex);
		SInt32 keyMapCount = keyMapSet->GetKeyMapCount();
		for (SInt32 keyMapIndex = 0; keyMapIndex < keyMapCount; keyMapIndex++) {
			KeyMapElement *keyMapElement = keyMapSet->GetKeyMapElement(keyMapIndex);
			KeyElement *keyElement = keyMapElement->GetKeyElement(inKeyCode);
			ioKeyBundle->AddKeyElement(keyMapSetIndex - 1, keyMapIndex, keyElement);
			keyMapElement->RemoveKeyElement(inKeyCode);
		}
	}
}

#pragma mark -

	// Get all the state names anywhere in the keyboard layout

NSMutableSet *KeyboardElement::GetStateNameSet(const UInt32 inReachable)
{
	NSMutableSet *stateNames = [NSMutableSet setWithCapacity:128];
		// Get states from the actions
	ActionElement *actionElement;
	for (actionElement = mActionList->GetFirstElement(); actionElement != NULL;
		 actionElement = mActionList->GetNextElement()) {
		actionElement->GetStateNames(stateNames, inReachable);
	}
		// Get states from inline actions in key elements
	mKeyMapSetList->GetStateNames(stateNames, inReachable);
		// Get states from the terminators
	if (mTerminatorsElement.get() != NULL) {
		mTerminatorsElement->GetStateNames(stateNames, inReachable);
	}
	return stateNames;
}

	// Update the maxout value

void KeyboardElement::UpdateMaxout(void)
{
		// Initialize maxout to 0
	UInt32 maxout = 0;
		// Find the maximum output length from the key map sets
	UInt32 keyMapSetMaxout = mKeyMapSetList->GetMaxout();
	if (keyMapSetMaxout > maxout) {
		maxout = keyMapSetMaxout;
	}
		// Find the maximum output length from the actions
	UInt32 actionsMaxout = mActionList->GetMaxout();
	if (actionsMaxout > maxout) {
		maxout = actionsMaxout;
	}
		// Find the maximum output length from the terminators
	if (mTerminatorsElement.get() != NULL) {
		UInt32 terminatorsMaxout = mTerminatorsElement->GetMaxout();
		if (terminatorsMaxout > maxout) {
			maxout = terminatorsMaxout;
		}
	}
	mMaxout = maxout;
}

	// Get the layout and modifier map for the given keyboard ID

void KeyboardElement::GetLayoutAndModifierMap(const UInt32 inKeyboardID,
											  LayoutElement*& outCurrentLayout,
											  ModifierMap*& outModifierMap) const
{
		// Find the layout corresponding to the given keyboard ID
	outCurrentLayout = mLayouts->FindLayout(inKeyboardID);
		// Get the correct modifier map
	outModifierMap = GetModifierMap(inKeyboardID);
}

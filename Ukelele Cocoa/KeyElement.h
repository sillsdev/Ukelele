/*
 *  KeyElement.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _KEYELEMENT_H_
#define _KEYELEMENT_H_

#include "ActionElement.h"
#include "XMLCommentHolder.h"
#include "NXMLNode.h"
#include "ErrorMessage.h"
using std::tr1::shared_ptr;

enum {
	kKeyUndefined,
	kKeyOutput,
	kKeyActionOutput,
	kKeyActionDeadKey,
	kKeyInlineActionOutput,
	kKeyInlineActionDeadKey,
	kKeyOther
};

enum {
	kStateNull,
	kStateOutput,
	kStateNext
};

enum {
	kKeyFormUndefined,
	kKeyFormOutput,
	kKeyFormAction,
	kKeyFormInlineAction
};

class KeyElement : public XMLCommentHolder {
public:
	KeyElement(const UInt32 inKeyCode);
	KeyElement(const KeyElement& inOriginal);
	virtual ~KeyElement(void);
	
	virtual NString GetDescription(void);
	
		// Creator functions
	static ErrorMessage CreateFromXMLTree(const NXMLNode& inXMLTree, KeyElement*& outElement, shared_ptr<XMLCommentContainer> ioCommentContainer);
	NXMLNode *CreateXMLTree(const bool inCodeNonAscii);
	void NewOutputElement(const NString inOutputString);
	void NewOutputElement(const UniChar *inString, const UInt32 inLength);
	void NewActionElement(const NString inActionName);
	void NewInlineActionElement(ActionElement *inActionElement);
	
		// Access functions
	UInt32 GetKeyCode(void) const { return mKeyCode; }
	UInt32 GetElementType(void) const { return mElementType; }
	NString GetOutputString(void) const { return mOutput; }
	NString GetActionName(void) const { return mActionName; }
	ActionElement *GetInlineAction(void) const { return mInlineAction.get(); }
	
		// Inspection and modification
	NString ChangeOutput(NString inState, NString inNewOutput, shared_ptr<ActionElementSet> inActionList);
	void ChangeOutputToDeadKey(NString inState, NString inDeadKeyState, shared_ptr<ActionElementSet> inActionList);
	NString ChangeDeadKeyToOutput(NString inState, NString inNewOutput, shared_ptr<ActionElementSet> inActionList);
	void MakeDeadKey(NString inState, NString inDeadKeyState, shared_ptr<ActionElementSet> inActionList);
	void MakeActionElement(NString inState, shared_ptr<ActionElementSet> inActionList);
	void ChangeKeyCode(const UInt32 inNewKeyCode);
	UInt32 GetTypeForState(NString inState, const shared_ptr<ActionElementSet> inActionList, NString& outString);
	bool HasInlineAction(void) const;
	
	void GetStateNames(NSMutableSet *ioStateNames, const UInt32 inReachable);
	void ReplaceStateName(NString inOldName, NString inNewName);
	void RemoveStates(NSSet *inStates);
	void ChangeActionName(NString inOldName, NString inNewName);
	UInt32 GetMaxout(void) const;
	
		// Get list of comment holders
	void AppendToList(XMLCommentHolderList& ioList);
	
private:
	UInt32 mKeyCode;
	UInt32 mElementType;
	NString mOutput;
	NString mActionName;
	shared_ptr<ActionElement> mInlineAction;
	
		// Forbid assignment
	void operator=(const KeyElement& inOriginal);
};

typedef std::vector<KeyElement *> KeyElementList;
typedef KeyElementList::iterator KeyElementIterator;
typedef KeyElementList::const_iterator KeyElementConstIterator;

typedef std::vector<KeyElementList *> KeyElementListVector;
typedef KeyElementListVector::iterator KeyElementListIterator;
typedef KeyElementListVector::const_iterator KeyElementListConstIterator;

#endif /* _KEYELEMENT_H_ */

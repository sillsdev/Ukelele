/*
 *  KeyMapSet.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _KeyMapSet_h_
#define _KeyMapSet_h_

#include <vector>
#include "XMLCommentHolder.h"
#include "ErrorMessage.h"
#include "KeyMapElement.h"
#include "ActionElement.h"
#include "NXMLNode.h"
#include "ModifierMap.h"
using std::tr1::shared_ptr;

class KeyMapSet : public XMLCommentHolder {
public:
	KeyMapSet(NString inID);
	KeyMapSet(const KeyMapSet& inOriginal);
	virtual ~KeyMapSet(void);
	
	void operator=(const KeyMapSet& inOriginal);
	bool operator<(const KeyMapSet& inCompareTo) const;
	
	virtual NString GetDescription(void);
	
	static KeyMapSet *CreateBasicKeyMapSet(NString inID, NString inBaseMapID);
	static KeyMapSet *CreateStandardKeyMapSet(NString inID, NString inBaseMapID, UInt32 inStandardKeyboard, UInt32 inCommandKeyboard, UInt32 inCapsLockKeyboard, ModifierMap *inModifierMap);
	static KeyMapSet *CreateStandardJISKeyMapSet(NString inID, NString inBaseMapID, ModifierMap *inModifierMap);
	static ErrorMessage CreateFromXMLTree(const NXMLNode& inXMLTree, KeyMapSet*& outElement, shared_ptr<XMLCommentContainer> ioCommentContainer);
	static ErrorMessage CreateFromXML(NSXMLElement *inXMLTree, KeyMapSet*& outElement, shared_ptr<XMLCommentContainer> ioCommentContainer);
	NXMLNode *CreateXMLTree(void);
	NSXMLElement *CreateXML(void);
	
	NString GetID(void) const { return mID; }
	UInt32 GetKeyMapCount(void) const;
	UInt32 GetMaxout(void) const;
	bool IsMissingSpecialKeyOutput(void) const;
	NStringList GetBaseMaps(void) const;
	UInt32 GetKeyMapSize(void) const { return mKeyMapTable->GetKeyMapSize(); }
	bool IsRelative(void) const;
	bool HasInlineAction(void) const;
	
	KeyMapElement *GetKeyMapElement(const UInt32 inIndex) const;
	bool HasKeyMapElement(const UInt32 inIndex) const;
	void InsertKeyMapAtIndex(const UInt32 inIndex, KeyMapElement *inKeyMap);
	KeyMapElement *RemoveKeyMapElement(const UInt32 inIndex);
	void RenumberKeyMaps(std::vector<SInt32>& inIndexMap);
	
	void MakeRelative(NString inBaseMapSet);
	void ImportDeadKey(NString inLocalState, NString inSourceState, KeyMapSet *inSource,
		shared_ptr<ActionElementSet> inLocalActionList, const shared_ptr<ActionElementSet> inSourceActionList);
	void AddSpecialKeyOutput(void);
	void SwapKeys(const UInt32 inKeyCode1, const UInt32 inKeyCode2);
	
	void GetStateNames(NSMutableSet *ioStateNames, const UInt32 inReachable) const
		{ mKeyMapTable->GetStateNames(ioStateNames, inReachable); }
	void ReplaceStateName(const NString inOldName, const NString inNewName)
		{ mKeyMapTable->ReplaceStateName(inOldName, inNewName); }
	void RemoveStates(NSSet *inStates) { mKeyMapTable->RemoveStates(inStates); }
	void ChangeActionName(const NString inOldName, const NString inNewName)
		{ mKeyMapTable->ChangeActionName(inOldName, inNewName); }
	void GetUsedActions(NSMutableSet *ioActionSet) const { mKeyMapTable->GetUsedActions(ioActionSet); }
	
	// Get list of comment holders
	void AppendToList(XMLCommentHolderList& ioList);

private:
	NString mID;
	shared_ptr<KeyMapElementList> mKeyMapTable;
};

#endif /* _KeyMapSet_h_ */

/*
 *  KeyMapElement.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _KEYMAPELEMENT_H_
#define _KEYMAPELEMENT_H_

#include "XMLCommentHolder.h"
#include "KeyElementTable.h"
#include "NXMLNode.h"
#include <vector>
using std::tr1::shared_ptr;

class KeyMapElement : public XMLCommentHolder {
public:
	KeyMapElement(const UInt32 inIndex, const NString inBaseMapSet, const UInt32 inBaseIndex, const UInt32 inTableSize);
	KeyMapElement(const KeyMapElement& inOriginal);
	virtual ~KeyMapElement(void);
	
	virtual NString GetDescription(void);
	
	UInt32 GetIndex(void) const { return mIndex; }
	void SetIndex(const UInt32 inIndex) { mIndex = inIndex; }
	NString GetBaseMapSet(void) const { return mBaseMapSet; }
	void SetBaseMapSet(const NString inBaseMapSet) { mBaseMapSet = inBaseMapSet; }
	UInt32 GetBaseIndex(void) const  { return mBaseIndex; }
	void SetBaseIndex(const UInt32 inIndex) { mBaseIndex = inIndex; }
	
	UInt32 GetKeyElementCount(void) const { return mElementTable->GetTableSize(); }
	bool IsEmpty(void) const;
	UInt32 GetMaxout(void) const;
	bool IsMissingSpecialKeyOutput(void) const;
	bool HasInlineAction(void) const;
	
	void AddKeyElement(const UInt32 inIndex, KeyElement *inKeyElement);
	KeyElement *GetKeyElement(const UInt32 inIndex) const;
	void RemoveKeyElement(const UInt32 inIndex);
	
	void GetStateNames(NSMutableSet *ioStates, const UInt32 inReachable) const;
	void ReplaceStateName(const NString inOldName, const NString inNewName);
	void RemoveStates(NSSet *inStates);
	void ChangeActionName(const NString inOldName, const NString inNewName);
	void GetUsedActions(NSMutableSet *ioActionSet) const;
	
	NString GetSpecialKeyOutput(const UInt32 inKeyCode);
	void AddSpecialKeyOutput(void);
	
	void ImportDeadKey(const KeyMapElement *inSource, const NString inLocalState,
		const NString inSourceState, const shared_ptr<ActionElementSet> inSourceActionList,
		shared_ptr<ActionElementSet> inLocalActionList);
	void SwapKeyElements(const UInt32 inKeyCode1, const UInt32 inKeyCode2);
	void UnlinkKeyMapElement(shared_ptr<ActionElementSet> inActionList);
	
	static ErrorMessage CreateFromXMLTree(const NXMLNode& inXMLTree, KeyMapElement*& outElement, shared_ptr<XMLCommentContainer> ioCommentContainer);
	NXMLNode *CreateXMLTree(void);
	
	// Get list of comment holders
	void AppendToList(XMLCommentHolderList& ioList);
	
	static KeyMapElement *CreateDefaultKeyMapElement(const UInt32 inIndex,
		const NString inBaseMapSet, const UInt32 inBaseIndex);
	static KeyMapElement *CreateDefaultKeyMapElement(const UInt32 inSourceType,
		const UInt32 inIndex, const NString inBaseMapSet, const UInt32 inBaseIndex);
	static KeyMapElement *CreateBasicKeyMapElement(void);
	static NString GetStandardSpecialOutput(const UInt32 inKeyCode);

private:
	UInt32 mIndex;
	NString mBaseMapSet;
	UInt32 mBaseIndex;
	shared_ptr<KeyElementTable> mElementTable;
	static std::pair<UInt32, NString> sSpecialKeyList[];
	
	// Forbid assignment
	void operator=(const KeyMapElement& inOriginal);
};

typedef std::vector<KeyMapElement *> KeyMapElementVector;
typedef KeyMapElementVector::iterator KeyMapElementIterator;
typedef KeyMapElementVector::const_iterator KeyMapElementConstIterator;

class KeyMapElementList {
public:
	KeyMapElementList(void);
	KeyMapElementList(const KeyMapElementList& inOriginal);
	virtual ~KeyMapElementList();
	
	UInt32 GetKeyMapCount(void) const { return mElementList.size(); }
	UInt32 GetMaxout(void) const;
	UInt32 GetKeyMapSize(void) const;
	
	void InsertKeyMapElementAtIndex(const UInt32 inIndex, KeyMapElement *inKeyMapElement);
	void AppendKeyMapElement(KeyMapElement *inKeyMapElement);
	KeyMapElement *GetKeyMapElement(const UInt32 inIndex) const;
	KeyMapElement *RemoveKeyMapElement(const UInt32 inIndex);
	void Clear(void);
	void MakeRelative(const NString inBaseMapSet);
	
	void GetStateNames(NSMutableSet *ioStates, const UInt32 inReachable) const;
	void ReplaceStateName(const NString inOldName, const NString inNewName);
	void RemoveStates(NSSet *inStates);
	void ChangeActionName(const NString inOldName, const NString inNewName);
	void GetUsedActions(NSMutableSet *ioActionSet) const;
	
	void AddToXMLTree(NXMLNode& inXMLTree);
	
	// Get list of comment holders
	void AppendToList(XMLCommentHolderList& ioList);

private:
	KeyMapElementVector mElementList;
};

#endif /* _KEYMAPELEMENT_H_ */

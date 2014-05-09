/*
 *  KeyMapSetList.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _KeyMapSetList_h_
#define _KeyMapSetList_h_

#include <vector>
#include "DereferenceLess.h"
#include "KeyMapSet.h"
#include "NXMLNode.h"

typedef std::vector<KeyMapSet *> KeyMapSetVector;
typedef KeyMapSetVector::iterator KeyMapSetIterator;
typedef KeyMapSetVector::const_iterator KeyMapSetConstIterator;

class KeyMapSetList {
public:
	KeyMapSetList(void);
	KeyMapSetList(const KeyMapSetList& inOriginal);
	virtual ~KeyMapSetList(void);
	
	SInt32 GetCount(void) const { return mList.size(); }
	UInt32 GetMaxout(void) const;
	bool IsMissingSpecialKeyOutput(void) const;
	NStringList GetKeyMapSets(void) const;
	bool HasInlineAction(void) const;
	
	void AddKeyMapSet(KeyMapSet *inKeyMapSet);
	void CompleteSet(void);
	KeyMapSet *GetKeyMapSet(const UInt32 inIndex) const;
	KeyMapSet *FindKeyMapSet(NString inID) const;
	void Clear(void);
	void ImportDeadKey(KeyMapSetList *inSource, const NString inLocalState,
		const NString inSourceState, shared_ptr<ActionElementSet> inLocalActionList,
		const shared_ptr<ActionElementSet> inSourceActionList);
	
	void GetStateNames(NSMutableSet *ioStateNames, const UInt32 inReachable) const;
	void ReplaceStateName(const NString inOldName, const NString inNewName);
	void RemoveStates(NSSet *inStates);
	void ChangeActionName(const NString inOldName, const NString inNewName);
	NSSet *GetUsedActions(void) const;
	
	void AddSpecialKeyOutput(void);
	
	// Get list of comment holders
	void AppendToList(XMLCommentHolderList& ioList);

private:
	KeyMapSetVector mList;
};

#endif /* _KeyMapSetList_h_ */

/*
 *  KeyElementTable.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _KEYELEMENTTABLE_H_
#define _KEYELEMENTTABLE_H_

#include "KeyElement.h"
#include <vector>

const UInt32 kDefaultKeyElementTableSize = 128;

class KeyElementTable {
public:
	KeyElementTable(const UInt32 inTableSize);
	KeyElementTable(const KeyElementTable& inOriginal);
	virtual ~KeyElementTable();
	
	UInt32 GetTableSize(void) const { return mTableSize; }
	bool IsEmpty(void) const;
	UInt32 GetMaxout(void) const;
	void GetUsedActions(NSMutableSet *ioActionSet) const;
	bool HasInlineAction(void) const;
	
	void AddKeyElement(const UInt32 inIndex, KeyElement *inKeyElement);
	KeyElement *GetKeyElement(const UInt32 inIndex);
	void RemoveKeyElement(const UInt32 inIndex);
	void SwapKeyElements(const UInt32 inKeyCode1, const UInt32 inKeyCode2);
	
	// Get list of comment holders
	void AppendToList(XMLCommentHolderList& ioList);

private:
	KeyElementList mElementTable;
	UInt32 mTableSize;
	
	// Forbid assignment
	void operator=(const KeyElement& inOriginal);
};

#endif /* _KEYELEMENTTABLE_H_ */

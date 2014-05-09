/*
 *  ModifierList.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _MODIFIERLIST_H_
#define _MODIFIERLIST_H_

#include "ModifierElement.h"

typedef std::vector<ModifierElement *> ModifierElementList;
typedef ModifierElementList::iterator ModifierElementIterator;

class ModifierList {
public:
	ModifierList(void);
	ModifierList(const ModifierList& inOriginal);
	virtual ~ModifierList();
	
	void AddModifierElement(ModifierElement *inModifier);
	void InsertModifierElement(ModifierElement *inModifier, const SInt32 inIndex);
	ModifierElement *GetModifierElement(const SInt32 inIndex) const;
	SInt32 GetElementCount(void) const { return mModifierElementList.size(); }
	ModifierElement *RemoveModifierElement(const SInt32 inIndex);
    
    ModifierList *SimplifiedModifierList(void);
    bool IsSimplified(void);
	
	// Get list of comment holders
	void AppendToList(XMLCommentHolderList& ioList);

private:
	ModifierElementList mModifierElementList;
	
	// Forbid assignment
	void operator=(const ModifierList& inOriginal);
};

#endif /* _MODIFIERLIST_H_ */

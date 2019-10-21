/*
 *  KeyMapSelect.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _KEYMAPSELECT_H_
#define _KEYMAPSELECT_H_

#include "ModifierList.h"
#include "XMLCommentHolder.h"
#include "NXMLNode.h"
#include "NString.h"
using std::shared_ptr;

class KeyMapSelect : public XMLCommentHolder {
public:
	KeyMapSelect(const UInt32 inTableNumber);
	KeyMapSelect(const KeyMapSelect& inOriginal);
	virtual ~KeyMapSelect(void);
	
	virtual NString GetDescription(void);
	
	SInt32 GetModifierElementCount(void) const { return mModifierList->GetElementCount(); }
	UInt32 GetKeyMapSelectIndex(void) const { return mMapIndexNumber; }
	void SetKeyMapSelectIndex(const UInt32 inIndex) { mMapIndexNumber = inIndex; }

	void AddModifierElement(ModifierElement *inModifierElement);
	void InsertModifierElementAtIndex(ModifierElement *inModifierElement, const SInt32 inIndex);
	ModifierElement *GetModifierElement(const SInt32 inIndex) const;
	ModifierElement *RemoveModifierElement(const SInt32 inIndex);
	bool ModifierMatches(const UInt32 inModifierCombination) const;
	bool RequiresModifier(const UInt32 inModifier) const;
    
    KeyMapSelect *SimplifiedKeyMapSelect(void);
    bool IsSimplified(void);
	
	static KeyMapSelect *CreateBasicKeyMapSelect(const UInt32 inID, const NString inModifiers);
	static ErrorMessage CreateFromXMLTree(const NXMLNode& inXMLTree, KeyMapSelect*& outElement, shared_ptr<XMLCommentContainer> ioCommentContainer);
	NXMLNode *CreateXMLTree(void);
	
	// Get list of comment holders
	void AppendToList(XMLCommentHolderList& ioList);

private:
	UInt32 mMapIndexNumber;
	shared_ptr<ModifierList> mModifierList;
};

#endif /* _KEYMAPSELECT_H_ */

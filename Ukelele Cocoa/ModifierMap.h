/*
 *  ModifierMap.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _MODIFIERMAP_H_
#define _MODIFIERMAP_H_

#include "XMLCommentHolder.h"
#include "ErrorMessage.h"
#include "KeyMapSelect.h"
#include <vector>
#include "NXMLNode.h"
using std::tr1::shared_ptr;

const UInt32 kModifierKeyCount = 8;
const UInt32 kModifierMapLength = 1 << kModifierKeyCount;
const UInt32 kModifierKeyList[] = {
	cmdKey,
	shiftKey,
	alphaLock,
	optionKey,
	controlKey,
	rightShiftKey,
	rightOptionKey,
	rightControlKey
};
const UInt32 kModifierMapShift = cmdKeyBit;

typedef std::vector<KeyMapSelect *> KeyMapSelectList;
typedef KeyMapSelectList::iterator KeyMapSelectIterator;

class ModifierMap : public XMLCommentHolder {
public:
	ModifierMap(const NString inID, const UInt32 inDefaultIndex);
	virtual ~ModifierMap(void);
	
	virtual NString GetDescription(void);
	
	NString GetID(void) const { return mID; }
	UInt32 GetDefaultIndex(void) const { return mDefaultIndex; }
	void SetDefaultIndex(const UInt32 inDefaultIndex);
	SInt32 GetKeyMapSelectCount(void) const { return mKeyMapSelectList.size(); }
	
	void AddKeyMapSelectElement(KeyMapSelect *inKeyMapSelect, bool inCalculateMap = true);
	void InsertKeyMapSelectAtIndex(KeyMapSelect *inKeyMapSelect, const SInt32 inIndex, bool inCalculateMap = true);
	KeyMapSelect *GetKeyMapSelectElement(const SInt32 inIndex);
	KeyMapSelect *RemoveKeyMapSelectElement(const SInt32 inIndex);
	void RenumberKeyMapSelects(std::vector<SInt32>& inIndexMap);
	
	void InsertModifierElementAtIndex(ModifierElement *inModifierElement, const SInt32 inIndex,
		const SInt32 inSubIndex);
	ModifierElement *RemoveModifierElement(const SInt32 inIndex, const SInt32 inSubIndex);
	
	UInt32 GetMatchingKeyMapSelect(const UInt32 inModifiers);
	UInt32 GetMatchingModifiers(const UInt32 inKeyMapSelectIndex);
	bool IsEquivalent(const ModifierMap *inMap) const;
	std::vector<UInt32> GetReferencedIndices(void) const;
    
    ModifierMap *SimplifiedModifierMap(void);
    bool IsSimplified(void);
	
	static ModifierMap *CreateBasicModifierMap(void);
	static ErrorMessage CreateFromXMLTree(const NXMLNode& inXMLTree, ModifierMap*& outElement, shared_ptr<XMLCommentContainer> ioCommentContainer);
	NXMLNode *CreateXMLTree(void);
	
	// Get list of comment holders
	void AppendToList(XMLCommentHolderList& ioList);
	
protected:
	void CalculateModifierMap(void);
	UInt32 IndexToModifier(const UInt32 inIndex);
	UInt32 ModifierToIndex(const UInt32 inModifier);
	UInt32 ModifierToTable(const UInt32 inModifier);

private:
	NString mID;
	UInt32 mDefaultIndex;
	KeyMapSelectList mKeyMapSelectList;
	UInt32 mModifierMap[kModifierMapLength];
	
	// Forbid copy and assignment
	ModifierMap(const ModifierMap& inOriginal);
	void operator=(const ModifierMap& inOriginal);
};

typedef std::vector<ModifierMap *> ModifierMapList;
typedef ModifierMapList::iterator ModifierMapIterator;
typedef ModifierMapList::const_iterator ModifierMapConstIterator;

#endif /* _MODIFIERMAP_H_ */

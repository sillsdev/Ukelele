/*
 *  ModifierElement.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _MODIFIERELEMENT_H_
#define _MODIFIERELEMENT_H_

#include "NString.h"
#include "XMLCommentHolder.h"
#include "NXMLNode.h"
#include <vector>
#include "ErrorMessage.h"
#include "ModifierConstants.h"

// Constants for the different modifier keys
const UInt32 kModifierStringCount = 22;
enum {
	kAnyControlIndex = 0,
	kAnyControlOptIndex = 1,
	kAnyOptionIndex = 2,
	kAnyOptionOptIndex = 3,
	kAnyShiftIndex = 4,
	kAnyShiftOptIndex = 5,
	kCapsLockIndex = 6,
	kCapsLockOptIndex = 7,
	kCommandIndex = 8,
	kCommandOptIndex = 9,
	kControlIndex = 10,
	kControlOptIndex = 11,
	kOptionIndex = 12,
	kOptionOptIndex = 13,
	kRightControlIndex = 14,
	kRightControlOptIndex = 15,
	kRightOptionIndex = 16,
	kRightOptionOptIndex = 17,
	kRightShiftIndex = 18,
	kRightShiftOptIndex = 19,
	kShiftIndex = 20,
	kShiftOptIndex = 21
};

class ModifierElement : public XMLCommentHolder {
public:
	ModifierElement(void);
	ModifierElement(const ModifierElement& inOriginal);
	virtual ~ModifierElement(void);
	
	virtual NString GetDescription(void);
	
	ErrorMessage AddModifierKey(const UInt32 inModifier, const UInt32 inStatus);
	ErrorMessage AddModifierKey(NString inModifierName);
	ErrorMessage AddModifierKeyList(NString inModifierList);
	UInt32 GetModifierStatus(const UInt32 inModifier);
	UInt32 GetModifierPairStatus(const UInt32 inLeftModifier, const UInt32 inRightModifier);
	void GetModifierStatus(UInt32& outShift, UInt32& outCapsLock, UInt32& outOption, UInt32& outCommand, UInt32& outControl);
	NString GetModifierKeyList(void);
	void SetModifierStatus(const UInt32 inShift, const UInt32 inCapsLock, const UInt32 inOption,
		const UInt32 inCommand, const UInt32 inControl);
	bool ModifierMatches(const UInt32 inModifierCombination);
    
    ModifierElement *SimplifiedModifierElement(void);
    bool IsSimplified(void);
	
	static ErrorMessage CreateFromXMLTree(const NXMLNode& inXMLTree, ModifierElement*& outElement);
	NXMLNode *CreateXMLTree(void);
	
	// Get list of comment holders
	void AppendToList(XMLCommentHolderList& ioList);
	
protected:
	NString CreateModifierString(void);
	void AddModifier(const UInt32 key1, const UInt32 key2, const UInt32 status);
	void AddModifierName(NString inName);
	void AddModifierPair(const UInt32 inLeft, const UInt32 inRight, const UInt32 inStatus);
    UInt32 SimplifiedModifier(const UInt32 inStatus);
    bool IsSimple(const UInt32 inStatus);

private:
	std::vector<UInt32> mModifierMap;
	NString mModifierString;
};

class ModifierKeyStringTable {
public:
	ModifierKeyStringTable(void);
	virtual ~ModifierKeyStringTable();
	
	static ModifierKeyStringTable *GetInstance(void);
	bool GetMatchKeys(NString inString, UInt32& outLeftModifier, UInt32& outRightModifier, UInt32& outStatus);
	NString GetKeyString(const UInt32 inLeftKey, const UInt32 inStatus);
	
protected:
	void SetupStringTable(void);
	bool Match(NString inString, UInt32& outLeftModifier, UInt32& outRightModifier, UInt32& outStatus);

private:
	UInt32 mNumberStrings;
	NString *mStringTable;
	UInt32 *mLeftModifierTable;
	UInt32 *mRightModifierTable;
	UInt32 *mStatusTable;
	static ModifierKeyStringTable *sModifierKeyStringTable;
	
	// Forbid copy and assignment
	ModifierKeyStringTable(const ModifierKeyStringTable& inOriginal);
	void operator=(const ModifierKeyStringTable& inOriginal);
};

#endif /* _MODIFIERELEMENT_H_ */

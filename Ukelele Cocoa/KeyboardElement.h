/*
 *  KeyboardElement.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _KeyboardElement_h_
#define _KeyboardElement_h_

#include "NString.h"
#include "XMLCommentHolder.h"
#include "NXMLNode.h"
#include "UkeleleConstants.h"
#include "LayoutsElement.h"
#include "ModifierMap.h"
#include "KeyMapSetList.h"
#include "ActionElement.h"
#include "TerminatorsElement.h"
#include "KeyElementBundle.h"
#include "RemoveStateData.h"
#include "AddMissingOutputData.h"
#include "ScriptRanges.h"
using std::tr1::shared_ptr;

class KeyboardElement : public XMLCommentHolder {
public:
	KeyboardElement(const SInt32 inGroup, const SInt32 inID, const NString inName, const UInt32 inMaxout = 0);
	virtual ~KeyboardElement(void);
	
	virtual NString GetDescription(void);
	
	static ErrorMessage CreateFromXMLTree(const NXMLNode& inTree, KeyboardElement *&outElement, shared_ptr<XMLCommentContainer> ioCommentContainer);
	static ErrorMessage CreateFromXML(NSXMLElement *inTree, KeyboardElement*& outElement, shared_ptr<XMLCommentContainer> ioCommentContainer);
	NXMLNode *CreateXMLTree(void);
	NSXMLElement *CreateXML(void);
	static KeyboardElement *CreateBasicKeyboard(NString inName);
	static KeyboardElement *CreateStandardKeyboard(NString inName, UInt32 inBaseLayout, UInt32 inCommandLayout, UInt32 inCapsLockLayout);
	static KeyboardElement *CreateKeyboad(NString inName, UInt32 inScript, UInt32 inStandardKeyboard, UInt32 inCommandKeyboard);
	
	NString GetKeyboardName(void) const { return mName; }
	void SetKeyboardName(const NString inName) { mName = inName; }
	SInt32 GetKeyboardID(void) const { return mID; }
	void SetKeyboardID(const SInt32 inNewID) { mID = inNewID; }
	SInt32 GetKeyboardGroup(void) const { return mGroup; }
	void SetKeyboardGroup(const SInt32 inNewGroup) { mGroup = inNewGroup; }
	UInt32 GetMaxout(void) const { return mMaxout; }
	void SetMaxout(const UInt32 inMaxout) { mMaxout = inMaxout; }
	shared_ptr<ActionElementSet> GetActionList(void) { return mActionList; }
	TerminatorsElement *GetTerminatorsElement(void) const { return mTerminatorsElement.get(); }
	
	void AddLayoutsElement(LayoutsElement *inLayoutsElement);
	ModifierMap *GetModifierMap(const UInt32 inKeyboardID) const;
	void AddModifierMap(ModifierMap *inModifierMap);
	void AddKeyMapSet(KeyMapSet *inKeyMapSet);
	void AddActionList(shared_ptr<ActionElementSet> inActionList);
	void AddTerminatorsElement(TerminatorsElement *inTerminatorsElement);
	KeyElement *GetKeyElement(const UInt32 inKeyboardID, const UInt32 inKeyCode, const UInt32 inModifierCombination, const bool inUseBaseMapSet) const;
	void AddKeyElement(const UInt32 inKeyboardID, const UInt32 inKeyCode, const UInt32 inModifierCombination, KeyElement *inKeyElement);
	NString GetCharOutput(const UInt32 inKeyboardID, const UInt32 inKeyCode, const UInt32 inModifierCombination, const NString inState, bool &outDeadKey, NString& outNextState) const;
	bool IsDeadKey(const UInt32 inKeyboardID, const UInt32 inKeyCode, const UInt32 inModifierCombination, const NString inState) const;
	NString GetNextState(const UInt32 inKeyboardID, const UInt32 inKeyCode, const UInt32 inModifierCombination, const NString inState) const;
	void AddAction(ActionElement *inAction);
	ActionElement *GetActionElement(const NString inActionName) const;
	KeyMapElement *GetKeyMapElement(const UInt32 inKeyboardID, const UInt32 inModifierCombination) const;
	KeyMapSet *GetKeyMapSet(const UInt32 inKeyboardID) const;
	KeyMapSet *GetKeyMapSet(NString inID) const;
	KeyMapSetList *GetKeyMapSetsForKeyboard(const UInt32 inKeyboardID) const;
	KeyMapSelect *RemoveKeyMapSelect(const UInt32 inKeyboardID, const SInt32 inIndex, KeyMapElementList *outKeyMapList);
	ModifierElement *RemoveModifierElement(const UInt32 inKeyboardID, const SInt32 inIndex, const SInt32 inSubIndex);
	void RemoveKeyElement(const UInt32 inKeyboardID, const UInt32 inKeyCode, const UInt32 inModifierCombination);
	NString CreateDuplicateAction(const NString inActionName);
	void ImportDeadKey(const NString inLocalState, const NString inSourceState, const KeyboardElement *inSource);
	NString GetTerminator(const NString inState) const;
	void ReplaceTerminator(const NString inState, const NString inNewTerminator);
    ModifierMapList *SimplifiedModifierMaps(void);
    bool HasSimplifiedModifierMaps(void);
	NStringList *KeyMapsForModifierMap(NString inModifierMapID);
	
	void ChangeModifierElement(const UInt32 inKeyboardID, const UInt32 inIndex, const UInt32 inSubIndex,
		const UInt32 inShift, const UInt32 inCapsLock, const UInt32 inOption, const UInt32 inCommand, const UInt32 inControl);
	void ChangeDeadKeyNextState(const UInt32 inKeyboardID, const UInt32 inKeyCode, const UInt32 inModifierCombination,
		const NString inState, const NString inNewState);
	void MakeKeyDeadKey(const UInt32 inKeyboardID, const UInt32 inKeyCode, const UInt32 inModifierCombination, const NString inState, const NString inNewState);
	void MakeDeadKeyOutput(const UInt32 inKeyboardID, const UInt32 inKeyCode, const UInt32 inModifierCombination, const NString inState, const NString inNewOutput);
    ModifierMapList *ReplaceModifierMaps(ModifierMapList *inNewModifierMaps);
	void MoveModifierMap(const UInt32 inFromIndex, const UInt32 inToIndex, const UInt32 inKeyboardID);
	
	static SInt32 GetRandomKeyboardID(const SInt32 inScriptCode);
	void AssignRandomKeyboardID(void);
	
	NArray GetActionNames(void) const;
	void ChangeActionName(const NString inOldName, const NString inNewName);
	bool ActionExists(const NString inActionName) const;
	shared_ptr<ActionElementSet> RemoveUnusedActions(void);
	void ReplaceActions(shared_ptr<ActionElementSet> inActions);
	
	bool StateExists(const NString inStateName);
	NString CreateStateName(void);
	NString CreateStateName(NString inBaseName);
	void CreateState(const NString inStateName, const NString inTerminatorString);
	NString GetNextState(const UInt32 inKeyboardID, const UInt32 inKeyCode, const UInt32 inModifierCombination, const NString inState, bool& outDeadKey) const;
	NArray GetStateNames(const NString inOmitName, const UInt32 inReachable);
	NArray GetStateNames(const NArray inOmitStates, const UInt32 inReachable);
	void ReplaceStateName(const NString inOldName, const NString inNewName);
	RemoveStateData *RemoveState(const NString inState);
	RemoveStateData *RemoveUnusedStates(void);
	void ReplaceRemovedStates(RemoveStateData *inStateData);
	
	bool HasIndirectBaseMapReference(void) const;
	bool HasMultiplierAction(void) const;
	bool HasMissingActions(NArray *outActions) const;
	bool IsMissingSpecialKeyOutput(void) const;
	bool HasEquivalentModifierMap(const KeyboardElement *inKeyboard) const;
	bool IsMissingKeyMapSets(NStringList& outMissingKeyMapSets) const;
	bool IsMissingKeyMap(NString& outModifierMapID, NString& outKeyMapSetID, UInt32& outKeyMapIndex) const;
	bool HasInlineAction(void) const;
	
	bool RepairJIS(void);
	AddMissingOutputData *AddSpecialKeyOutput(void);
	void ReplaceOldOutput(AddMissingOutputData *oldData);
	
	void SwapKeys(const UInt32 inKeyCode1, const UInt32 inKeyCode2);
	
	shared_ptr<KeyElementBundle> BuildKeyBundle(const UInt32 inKeyCode) const;
	void SetKeyBundle(const UInt32 inKeyCode, shared_ptr<KeyElementBundle> inKeyBundle);
	void CutKeyBundle(const UInt32 inKeyCode, shared_ptr<KeyElementBundle> ioKeyBundle);
	
private:
	NSMutableSet *GetStateNameSet(const UInt32 inReachable);
	void UpdateMaxout(void);
	ModifierMap *FindModifierMap(NString inID) const;
	void GetLayoutAndModifierMap(const UInt32 inKeyboardID, LayoutElement*& outCurrentLayout, ModifierMap*& outModifierMap) const;

private:
	SInt32 mGroup;
	SInt32 mID;
	NString mName;
	UInt32 mMaxout;
	shared_ptr<LayoutsElement> mLayouts;
	ModifierMapList mModifierMapList;
	shared_ptr<KeyMapSetList> mKeyMapSetList;
	shared_ptr<ActionElementSet> mActionList;
	shared_ptr<TerminatorsElement> mTerminatorsElement;
	
	// Forbid copy and assignment
	KeyboardElement(const KeyboardElement&);
	void operator=(const KeyboardElement&);
};

#endif /* _KeyboardElement_h_ */

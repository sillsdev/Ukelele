/*
 *  ActionElement.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _ACTIONELEMENT_H_
#define _ACTIONELEMENT_H_

#include "UkeleleStrings.h"
#include "UkeleleConstants.h"
#include "XMLCommentHolder.h"
#include "WhenElement.h"
#include "NCocoa.h"
#include "NXMLNode.h"
#include "DereferenceLess.h"
#include "NArray.h"
#include "ErrorMessage.h"
using std::tr1::shared_ptr;

enum {
	kActionTypeTerminator,
	kActionTypeState,
	kActionTypeOutput
};

class ActionElement : public XMLCommentHolder {
public:
	ActionElement(void);
	ActionElement(NString inActionID);
	ActionElement(const ActionElement& inOriginal);
	virtual ~ActionElement(void);
	
	virtual NString GetDescription(void);
	
		// Get and set the action ID
	NString GetActionID(void) const { return mActionID; }
	void SetActionID(NString inNewID);
	
		// Add, find and delete when elements
	bool AddWhenElement(WhenElement *inWhenElement);
	WhenElement *FindWhenElement(const NString inStateID) const;
	void DeleteWhenElement(const NString inStateID);
	WhenElement *GetFirstWhenElement(void) { return mWhenElementSet->GetFirstWhenElement(); }
	WhenElement *GetNextWhenElement(void) { return mWhenElementSet->GetNextWhenElement(); }
	
		// Get various attributes
	UInt16 GetActionType(const NString inStateID) const;
	bool HasMultiplierElement(void) const;
	UInt32 GetMaxout(void) const;
	SInt32 GetWhenElementCount(void) const;
	
		// Get and modify state names
	void GetStateNames(NSMutableSet *ioStateNames, const UInt32 inReachable);
	void ReplaceStateName(const NString inOldName, const NString inNewName);
	void RemoveStates(NSSet *inStates);
	
		// Convert to and from an XML tree
	static ErrorMessage CreateFromXMLTree(const NXMLNode& inTree, ActionElement*& outElement, shared_ptr<XMLCommentContainer> ioCommentContainer);
	NXMLNode *CreateXMLTree(const bool inCodeNonAscii);
	
		// Get list of comment holders
	void AppendToList(XMLCommentHolderList& ioList);
	
		// Operators
	bool operator<(const ActionElement& inCompareTo) const;
	bool operator==(const ActionElement& inCompareTo) const;
	void operator=(const ActionElement& inOriginal);
	
private:
	NString mActionID;
	shared_ptr<WhenElementSet> mWhenElementSet;
};

class ActionElementSet : public XMLCommentHolder {
public:
	ActionElementSet(void);
	ActionElementSet(const ActionElementSet& inOriginal);
	virtual ~ActionElementSet(void);
	
	virtual NString GetDescription(void);
	
		// Add, find and delete action elements
	Boolean AddActionElement(ActionElement *inActionElement);
	ActionElement *FindActionElement(const NString inActionID) const;
	ActionElement *RemoveActionElement(const NString inActionID);
	bool ActionExists(const NString inActionID) const;
	void Clear(void);
	bool IsEmpty(void) const;
	
		// Create new action names
	ActionElement *CreateDuplicateActionElement(const NString inActionID);
	NString MakeActionName(const NString inBaseName);
	
		// Access various attributes
	UInt32 GetMaxout(void) const;
	bool HasMultiplierAction(void) const;
	NArray GetActionNames(void) const;
	
		// XML tree creation and construction
	ErrorMessage CreateFromXMLTree(const NXMLNode& inTree, shared_ptr<XMLCommentContainer> ioCommentContainer);
	NXMLNode *CreateXMLTree(const bool inCodeNonAscii);
	
		// Iterator functions
	ActionElement *GetFirstElement(void);
	ActionElement *GetNextElement(void);
	
		// Get list of comment holders
	void AppendToList(XMLCommentHolderList& ioList);
	
protected:
	NString GetUniqueActionName(const NString inBaseString, UInt32 inSuffixStart);
	
private:
	std::set<ActionElement *, DereferenceLess> mActionElementSet;
	std::set<ActionElement *, DereferenceLess>::iterator mIterator;
};

#endif /* _ACTIONELEMENT_H_ */

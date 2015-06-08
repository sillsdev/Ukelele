/*
 *  WhenElement.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _WhenElement_h_
#define _WhenElement_h_

#include "XMLCommentHolder.h"
#include "NXMLNode.h"
#include "ErrorMessage.h"
#include "DereferenceLess.h"
#include <set>

class WhenElement : public XMLCommentHolder {
public:
	WhenElement();
	WhenElement(NString inState, NString inOutput, NString inNext, NString inThrough, NString inMultiplier);
	WhenElement(const WhenElement& inOriginal);
	virtual ~WhenElement();
	
	virtual NString GetDescription(void);
	
		// Get values
	NString GetState(void) const { return mState; }
	NString GetOutput(void) const { return mOutput; }
	NString GetNext(void) const { return mNext; }
	SInt32 GetNextInteger(void) const { return mNextInteger; }
	NString GetThrough(void) const { return mThrough; }
	SInt32 GetThroughInteger(void) const { return mThroughInteger; }
	NString GetMultiplier(void) const { return mMultiplier; }
	SInt32 GetMultiplierInteger(void) const { return mMultiplierInteger; }
	
		// Set values
	void SetOutput(NString inNewOutput);
	void SetNext(NString inNewNext);
	void SetThrough(NString inNewThrough);
	void SetMultiplier(NString inNewMultiplier);
	
		// Get the maximum output length
	UInt32 GetMaxout(void) const;
	
		// Replace state name
	void ReplaceStateName(NString inOldName, NString inNewName);
	
		// Convert to and from XML
	static ErrorMessage CreateFromXMLTree(const NXMLNode& inTree, WhenElement*& outElement);
	NXMLNode *CreateXMLTree(void);
	static ErrorMessage CreateFromXMLTree(NSXMLElement *inTree, WhenElement*& outElement);
	NSXMLElement *CreateXMLNode(void);
	
		// Operators
	bool operator<(const WhenElement& inCompareTo);
	bool operator==(const WhenElement& inCompareTo);
	void operator=(const WhenElement& inNew);
	
private:
	NString mState;
	NString mOutput;
	NString mNext;
	SInt32 mNextInteger;
	NString mThrough;
	SInt32 mThroughInteger;
	NString mMultiplier;
	SInt32 mMultiplierInteger;
};

typedef std::set<WhenElement *, DereferenceLess> WhenElementSetType;
typedef std::set<WhenElement *, DereferenceLess>::iterator WhenElementSetIterator;

class WhenElementSet {
public:
	WhenElementSet(void);
	WhenElementSet(const WhenElementSet& inOriginal);
	virtual ~WhenElementSet(void);
	
		// Add, find and delete
	bool AddWhenElement(WhenElement *inElement);
	WhenElement *FindWhenElement(NString inState);
	void DeleteWhenElement(NString inState);
	
		// Access attributes
	SInt32 GetWhenElementCount(void) const { return static_cast<SInt32>(mElementSet.size()); }
	bool HasMultiplier(void);
	UInt32 GetMaxout(void) const;
	
		// Get all state names
	void GetStateNames(NSMutableSet *ioStateNames, const UInt32 inReachable);
	
		// Change state name
	void ReplaceStateName(NString inOldName, NString inNewName);
	
		// Remove elements with given states
	void RemoveStates(NSSet *inStates);
	
		// Convert to XML tree
	void AddToXMLTree(NXMLNode& inTree);
	void AddToXML(NSXMLElement *inTree);
	
		// Iterator functions
	WhenElement *GetFirstWhenElement(void);
	WhenElement *GetNextWhenElement(void);
	
		// Get list of comment holders
	void AppendToList(XMLCommentHolderList& ioList);
	
private:
	WhenElementSetType mElementSet;
	WhenElementSetIterator mIterator;
	
		// Forbid assignment
	void operator=(const WhenElementSet& inOriginal);
};

#endif // _WhenElement_h_

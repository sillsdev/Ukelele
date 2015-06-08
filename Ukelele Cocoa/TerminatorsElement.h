/*
 *  TerminatorsElement.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _TERMINATORSELEMENT_H_
#define _TERMINATORSELEMENT_H_

#include "XMLCommentHolder.h"
#include "WhenElement.h"
#include "ErrorMessage.h"
using std::tr1::shared_ptr;

class TerminatorsElement : public XMLCommentHolder {
public:
	TerminatorsElement(void);
	TerminatorsElement(const TerminatorsElement& inOriginal);
	virtual ~TerminatorsElement(void);
	
	virtual NString GetDescription(void);
	
	bool AddWhenElement(WhenElement *inElement);
	WhenElement *FindWhenElement(NString inStateID) const;
	
	SInt32 GetWhenElementCount(void) const;
	UInt32 GetMaxout(void) const;
	void GetStateNames(NSMutableSet *ioStateNames, const UInt32 inReachable);
	bool HasMultiplier(void) const;
	
	void ReplaceStateName(NString inOldName, NString inNewName);
	void RemoveStates(NSSet *inStates);
	void ImportDeadKey(NString inLocalState, WhenElement *inWhenElement);
	
	static ErrorMessage CreateFromXMLTree(const NXMLNode& inTree, TerminatorsElement*& outElement, shared_ptr<XMLCommentContainer> ioCommentContainer);
	static ErrorMessage CreateFromXML(NSXMLElement *inTree, TerminatorsElement*& outElement, boost::shared_ptr<XMLCommentContainer> ioCommentContainer);
	NXMLNode *CreateXMLTree(void);
	NSXMLElement *CreateXML(void);
	
		// Get list of comment holders
	void AppendToList(XMLCommentHolderList& ioList);
	
private:
	shared_ptr<WhenElementSet> mWhenElementList;
};

#endif /* _TERMINATORSELEMENT_H_ */

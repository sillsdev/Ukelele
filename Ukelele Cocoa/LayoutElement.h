/*
 *  LayoutElement.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _LAYOUTELEMENT_H_
#define _LAYOUTELEMENT_H_

#include "XMLCommentHolder.h"
#include "NXMLNode.h"
#include "NString.h"
#include "ErrorMessage.h"

class LayoutElement : public XMLCommentHolder {
public:
	LayoutElement(const UInt32 inFirst, const UInt32 inLast, const NString inModifiers, const NString inMapSet);
	LayoutElement(const LayoutElement& inOriginal);
	virtual ~LayoutElement(void);
	
	virtual NString GetDescription(void);
	
	UInt32 GetFirst() const { return mFirst; }
	UInt32 GetLast() const { return mLast; }
	NString GetModifiers() const { return mModifiers; }
	NString GetMapSet() const { return mMapSet; }
	
	static ErrorMessage CreateFromXMLTree(const NXMLNode& inXMLTree, LayoutElement*& outElement);
	static ErrorMessage CreateFromXML(NSXMLElement *inXMLTree, LayoutElement*& outElement);
	NXMLNode *CreateXMLTree(void);
	NSXMLElement *CreateXML(void);
	
	// Get list of comment holders
	void AppendToList(XMLCommentHolderList& ioList);

private:
	UInt32 mFirst;
	UInt32 mLast;
	NString mModifiers;
	NString mMapSet;
};

typedef std::vector<LayoutElement *> LayoutElementList;
typedef LayoutElementList::iterator LayoutElementIterator;
typedef LayoutElementList::const_iterator LayoutElementConstIterator;

#endif /* _LAYOUTELEMENT_H_ */

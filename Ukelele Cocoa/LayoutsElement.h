/*
 *  LayoutsElement.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _LAYOUTSELEMENT_H_
#define _LAYOUTSELEMENT_H_

#include "XMLCommentHolder.h"
#include "LayoutElement.h"
#include <vector>
#include "NXMLNode.h"
#include "ErrorMessage.h"
using std::tr1::shared_ptr;

class LayoutsElement : public XMLCommentHolder {
public:
	LayoutsElement(void);
	virtual ~LayoutsElement(void);
	
	virtual NString GetDescription(void);
	bool IsEmpty(void) const { return mLayoutList.empty(); }
	
	void AddLayout(LayoutElement *inLayout);
	LayoutElement *FindLayout(const UInt32 inKeyboardType);
	LayoutElementList *GetLayoutsForModifierMap(const NString inModifierMapID);
	NStringList *GetKeyMapSetNames(void) const;
	NStringList *GetKeyMapsForModifierMap(const NString inModifierMapID);
	
	static LayoutsElement *CreateBasicLayoutsElement(void);
	static ErrorMessage CreateFromXMLTree(const NXMLNode& inXMLTree, LayoutsElement*& outElement, shared_ptr<XMLCommentContainer> ioCommentContainer);
	NXMLNode *CreateXMLTree(void);
	
	// Get list of comment holders
	void AppendToList(XMLCommentHolderList& ioList);

private:
	LayoutElementList mLayoutList;
	
	// Prohibit copy and assignment
	LayoutsElement(const LayoutsElement& inOriginal);
	void operator=(const LayoutsElement& inOriginal);
};

#endif /* _LAYOUTSELEMENT_H_ */

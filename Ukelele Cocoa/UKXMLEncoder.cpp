//
//  UKXMLEncoder.cpp
//  Ukelele
//
//  Created by John Brownie on 28/03/2016.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#include "UKXMLEncoder.h"
	
// Constructor
UKXMLEncoder::UKXMLEncoder(void) {
		// Nothing to do
}

	// Destructor
UKXMLEncoder::~UKXMLEncoder() {
		// Nothing to do
}

NString UKXMLEncoder::EncodeElement(const NXMLNode *theNode, const NString &theIndent) {
	NString							tagOpen, tagClose, theText, childIndent;
	NString							textName, textAttributes;
	bool							hasChildElements;
	NDictionary						theAttributes;
	const NXMLNodeList				*theChildren;
	NXMLNode						*theChild;
	NArray							theKeys;
	NXMLNodeListConstIterator		theIter;
	
		// Validate our parameters
	NN_ASSERT(theNode->GetType() == kNXMLNodeElement);
	
		// Get the state we need
	theChildren   = theNode->GetChildren();
	theAttributes = theNode->GetElementAttributes();
	textName      = theNode->GetTextValue();
	
	hasChildElements = ContainsElements(theChildren);
	childIndent      = theIndent + "    ";
	theKeys          = theAttributes.GetKeys(true);
	
		// Collect the attributes
	if (mAttributeOrderDictionary.HasKey(textName)) {
			// We have an attribute order
		NArray orderArray = mAttributeOrderDictionary.GetValueArray(textName);
		textAttributes = "";
		for (NIndex i = 0; i < orderArray.GetSize(); i++) {
			NString theName = orderArray.GetValueString(i);
			if (theAttributes.HasKey(theName)) {
					// We have this key
				NString theValue = theAttributes.GetValueString(theName);
				NString attributeString;
				attributeString.Format(" %@=\"%@\"", theName, theValue);
				textAttributes += attributeString;
			}
		}
	}
	else {
		theKeys.ForEach(BindSelf(UKXMLEncoder::EncodeElementAttribute, theAttributes, kNArg2, &textAttributes));
	}
	textAttributes.TrimRight();
	
		// Encode an unpaired element
	if (theNode->IsElementUnpaired())
	{
			// Encode the tag
		tagOpen.Format("<%@%@/>", textName, textAttributes);
		theText = theIndent + tagOpen;
	}
	
		// Encode a paired element
	else
	{
			// Encode the open tag
		tagOpen.Format("<%@%@>", textName, textAttributes);
		theText = theIndent + tagOpen;
		
			// Encode the children
		for (theIter = theChildren->begin(); theIter != theChildren->end(); theIter++)
		{
			theChild = *theIter;
			
			if (hasChildElements)
			{
				theText += "\n";
				
				if (!theChild->IsType(kNXMLNodeElement))
					theText += childIndent;
			}
			
			theText += EncodeNode(theChild, childIndent);
		}
		
		if (hasChildElements)
			theText += NString("\n") + theIndent;
		
			// Encode the close tag
		tagClose.Format("</%@>", textName);
		theText += tagClose;
	}
	
	return(theText);
}

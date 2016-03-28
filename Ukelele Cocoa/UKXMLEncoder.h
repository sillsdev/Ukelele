//
//  UKXMLEncoder.hpp
//  Ukelele
//
//  Created by John Brownie on 28/03/2016.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#ifndef UKXMLEncoder_hpp
#define UKXMLEncoder_hpp

#include "NXMLEncoder.h"

class UKXMLEncoder: public NXMLEncoder {
public:
	UKXMLEncoder(void);
	virtual ~UKXMLEncoder(void);
	
	NDictionary getAttributeOrderDictionary(void) { return mAttributeOrderDictionary; }
	void setAttributeOrderDictionary(NDictionary inDict) { mAttributeOrderDictionary = inDict; }
	
protected:
	NString	EncodeElement(const NXMLNode *theNode, const NString &theIndent);

private:
	NDictionary mAttributeOrderDictionary;
};

#endif /* UKXMLEncoder_hpp */

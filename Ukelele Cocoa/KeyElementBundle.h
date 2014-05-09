/*
 *  KeyElementBundle.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _KeyElementBundle_h_
#define _KeyElementBundle_h_

#include <vector>
#include "KeyElement.h"

class KeyElementBundle {
public:
	KeyElementBundle(void);
	KeyElementBundle(const KeyElementBundle& inOriginal);
	virtual ~KeyElementBundle(void);
	
	void AddKeyElement(const UInt32 inKeyMapSetIndex, const UInt32 inKeyMapIndex, const KeyElement *inKeyElement);
	KeyElement *GetKeyElement(const UInt32 inKeyMapSetIndex, const UInt32 inKeyMapIndex) const;

private:
	KeyElementListVector mBundle;
	
	// Forbid assignment
	void operator=(const KeyElementBundle& inOriginal);
};

#endif /* _KeyElementBundle_h_ */

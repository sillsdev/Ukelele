//
//  AddMissingOutputDataBlock.h
//  Ukelele 3
//
//  Created by John Brownie on 30/07/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#ifndef Ukelele_3_AddMissingOutputDataBlock_h
#define Ukelele_3_AddMissingOutputDataBlock_h

#include "KeyMapSetList.h"
#import <tr1/memory>
using std::tr1::shared_ptr;

class AddMissingOutputDataBlock {
	shared_ptr<KeyMapSetList> mKeyMapSetList;
	
public:
	AddMissingOutputDataBlock(shared_ptr<KeyMapSetList> inKeyMapSetList);
	virtual ~AddMissingOutputDataBlock();
	
	shared_ptr<KeyMapSetList> keyMapSetList(void) { return mKeyMapSetList; }
};

#endif

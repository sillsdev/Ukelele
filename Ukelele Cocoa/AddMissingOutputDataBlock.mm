//
//  AddMissingOutputDataBlock.mm
//  Ukelele 3
//
//  Created by John Brownie on 30/07/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#include "AddMissingOutputDataBlock.h"

AddMissingOutputDataBlock::AddMissingOutputDataBlock(shared_ptr<KeyMapSetList> inKeyMapSetList)
{
	mKeyMapSetList.reset(new KeyMapSetList(*inKeyMapSetList));
}

AddMissingOutputDataBlock::~AddMissingOutputDataBlock()
{
}

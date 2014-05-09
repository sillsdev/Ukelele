//
//  RemoveStateDataBlock.cpp
//  Ukelele 3
//
//  Created by John Brownie on 13/06/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#include "RemoveStateDataBlock.h"

RemoveStateDataBlock::RemoveStateDataBlock(shared_ptr<KeyMapSetList> inKeyMapSets,
										   shared_ptr<ActionElementSet> inActionElements,
										   shared_ptr<TerminatorsElement> inTerminators)
{
		// We make deep copies of each
	if (inKeyMapSets.get() != NULL) {
		mKeyMapSets.reset(new KeyMapSetList(*inKeyMapSets));
	}
	else {
		mKeyMapSets.reset();
	}
	mActionElements.reset(new ActionElementSet(*inActionElements));
	mTerminators.reset(new TerminatorsElement(*inTerminators));
}

RemoveStateDataBlock::~RemoveStateDataBlock()
{
}

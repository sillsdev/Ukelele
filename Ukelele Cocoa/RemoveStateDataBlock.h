//
//  RemoveStateDataBlock.h
//  Ukelele 3
//
//  Created by John Brownie on 13/06/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#ifndef Ukelele_3_RemoveStateDataBlock_h
#define Ukelele_3_RemoveStateDataBlock_h

#import "KeyMapSetList.h"
#import "ActionElement.h"
#import "TerminatorsElement.h"
#import <tr1/memory>
using std::tr1::shared_ptr;

class RemoveStateDataBlock {
public:
	RemoveStateDataBlock(shared_ptr<KeyMapSetList> inKeyMapSets, shared_ptr<ActionElementSet> inActionElements, shared_ptr<TerminatorsElement> inTerminators);
	virtual ~RemoveStateDataBlock(void);
	
	shared_ptr<KeyMapSetList> KeyMapSets(void) { return mKeyMapSets; }
	shared_ptr<ActionElementSet> ActionElements(void) { return mActionElements; }
	shared_ptr<TerminatorsElement> Terminators(void) { return mTerminators; }
	
private:
	shared_ptr<KeyMapSetList> mKeyMapSets;
	shared_ptr<ActionElementSet> mActionElements;
	shared_ptr<TerminatorsElement> mTerminators;
};

#endif

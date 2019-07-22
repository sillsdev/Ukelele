//
//  ActionElementSetHolder.h
//  Ukelele 3
//
//  Created by John Brownie on 14/06/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "ActionElement.h"
//using std::shared_ptr;

class ActionElementSetHolder {
	shared_ptr<ActionElementSet> mActionElementSet;
	
public:
	ActionElementSetHolder(shared_ptr<ActionElementSet> inActionElementSet);
	virtual ~ActionElementSetHolder();
	
	shared_ptr<ActionElementSet> GetActionElementSet(void) { return mActionElementSet; }
};

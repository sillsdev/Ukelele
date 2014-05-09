/*
 *  ModifiersTableInfo.cpp
 *  Ukelele 3
 *
 *  Created by John Brownie on 14/05/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "ModifiersTableInfo.h"
#include "ModifierElement.h"

ModifiersTableInfo::ModifiersTableInfo(unsigned int inIndex, unsigned int inSubIndex, unsigned int inShift,
									   unsigned int inCapsLock, unsigned int inOption, unsigned int inCommand,
									   unsigned int inControl)
	: mIndex(inIndex), mSubIndex(inSubIndex), mShift(inShift), mCapsLock(inCapsLock),
	mOption(inOption), mCommand(inCommand), mControl(inControl)
{
}

	// Default constructor
ModifiersTableInfo::ModifiersTableInfo(void)
	: mIndex(0), mSubIndex(1), mShift(kModifierNone), mCapsLock(kModifierNotPressed),
	mOption(kModifierNone), mCommand(kModifierNotPressed), mControl(kModifierNone)
{
}

ModifiersTableInfo::~ModifiersTableInfo(void)
{
}

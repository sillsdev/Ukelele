/*
 *  NString_hash.cpp
 *  Ukelele 3
 *
 *  Created by John Brownie on 10/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "NString_hash.h"

std::size_t hash_value(NString inString)
{
	return static_cast<std::size_t>(inString.GetHash());
}

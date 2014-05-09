/*
 *  DereferenceLess.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef DereferenceLess_H
#define DereferenceLess_H

struct DereferenceLess
{
	template <typename PtrType>
	bool operator()(PtrType pT1, PtrType pT2) const {
		return *pT1 < *pT2;
	}
};

#endif // DereferenceLess_H

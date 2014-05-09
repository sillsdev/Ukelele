/*
 *  RandomNumberGenerator.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 10/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _RandomNumberGenerator_h_
#define _RandomNumberGenerator_h_

#include "NSingleton.h"
#include "boost/random.hpp"

class RandomNumberGenerator : public NSingleton {
//class RandomNumberGenerator {
public:
	RandomNumberGenerator(void);
	virtual ~RandomNumberGenerator();
	
	static RandomNumberGenerator *GetInstance(void);
	
	SInt32 GetRandomSInt32(void);
	SInt32 GetRandomSInt32(const SInt32 inMinimum, const SInt32 inMaximum);

private:
	static boost::hellekalek1995 sRandomSInt32Generator;
	bool mSInt32GeneratorInitialised;
};

#endif /* _RandomNumberGenerator_h_ */

/*
 *  RandomNumberGenerator.cpp
 *  Ukelele 3
 *
 *  Created by John Brownie on 10/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "RandomNumberGenerator.h"

boost::hellekalek1995 RandomNumberGenerator::sRandomSInt32Generator;

RandomNumberGenerator::RandomNumberGenerator(void)
{
	mSInt32GeneratorInitialised = false;
}

RandomNumberGenerator::~RandomNumberGenerator(void)
{
}

RandomNumberGenerator *
RandomNumberGenerator::GetInstance(void)
{
	static RandomNumberGenerator *sRandomNumberGenerator = NULL;
	
	return CreateInstance<RandomNumberGenerator>(&sRandomNumberGenerator);
//	if (sRandomNumberGenerator == NULL) {
//		sRandomNumberGenerator = new RandomNumberGenerator;
//	}
//	return sRandomNumberGenerator;
}

// Random signed 32 bit integer

SInt32
RandomNumberGenerator::GetRandomSInt32(const SInt32 inMinimum, const SInt32 inMaximum)
{
	if (!mSInt32GeneratorInitialised) {
		time_t currentTime = time(NULL);
		sRandomSInt32Generator.seed(static_cast<int>(currentTime));
		mSInt32GeneratorInitialised = true;
	}
	SInt32 nextRandom = sRandomSInt32Generator();
	return nextRandom % (inMaximum - inMinimum + 1) + inMinimum;
}

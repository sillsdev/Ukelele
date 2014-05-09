//
//  ScriptRanges.h
//  Ukelele 3
//
//  Created by John Brownie on 1/08/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#ifndef Ukelele_3_ScriptRanges_h
#define Ukelele_3_ScriptRanges_h

	// Script ID ranges
enum {
	kIDMinimumUnicode = -32768,
	kIDMaximumUnicode = -2,
	kIDMinimumRoman = 2,
	kIDMaximumRoman = 16383,
	kIDMinimumJapanese = 16384,
	kIDMaximumJapanese = 16895,
	kIDMinimumSimplifiedChinese = 28672,
	kIDMaximumSimplifiedChinese = 29183,
	kIDMinimumTraditionalChinese = 16896,
	kIDMaximumTraditionalChinese = 17407,
	kIDMinimumKorean = 17408,
	kIDMaximumKorean = 17919,
	kIDMinimumCyrillic = 19456,
	kIDMaximumCyrillic = 19967,
	kIDMinimumCentralEuropean = 30720,
	kIDMaximumCentralEuropean = 31231
};

#endif

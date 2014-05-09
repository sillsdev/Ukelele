/*
 *  UnicodeInfo.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 15/01/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _UnicodeInfo_h_
#define _UnicodeInfo_h_

#include "Nano.h"
#include "NSingleton.h"
#include <map>
#include "NString.h"

class UnicodeInfo : public NSingleton {
public:
	UnicodeInfo(void);
	virtual ~UnicodeInfo();
	
	static UnicodeInfo *GetInstance(void);
	
	void InitializeStaticData(void);
	
	NString GetCodePointName(const UInt32 inCodePoint);
	
private:
	std::map<UInt32, NString> mInfoTable;
	bool mStaticDataInitialized;
};

#endif /* _UnicodeInfo_h_ */

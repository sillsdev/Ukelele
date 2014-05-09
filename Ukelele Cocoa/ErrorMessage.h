/*
 *  ErrorMessage.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _ERRORMESSAGE_H_
#define _ERRORMESSAGE_H_

#include "Nano.h"
#include "NString.h"

class ErrorMessage {
public:
	ErrorMessage(SInt32 inErrorCode, NString inErrorMessage);
	ErrorMessage(const ErrorMessage& inOriginal);
	virtual ~ErrorMessage();
	
	SInt32 GetErrorCode(void) const { return mErrorCode; }
	NString GetErrorMessage(void) const { return mErrorMessage; }
	
	void operator=(const ErrorMessage& inOriginal);
	bool operator==(const ErrorMessage& inCompareTo);
	bool operator==(const SInt32 inCompareTo);
	bool operator!=(const SInt32 inCompareTo);
	
private:
	SInt32 mErrorCode;
	NString mErrorMessage;
};

#endif /* _ERRORMESSAGE_H_ */

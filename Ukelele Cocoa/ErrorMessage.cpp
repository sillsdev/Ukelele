/*
 *  ErrorMessage.cpp
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "ErrorMessage.h"


	// Constructor

ErrorMessage::ErrorMessage(SInt32 inErrorCode, NString inErrorMessage)
: mErrorCode(inErrorCode), mErrorMessage(inErrorMessage)
{
}

	// Copy constructor

ErrorMessage::ErrorMessage(const ErrorMessage& inOriginal)
: mErrorCode(inOriginal.mErrorCode), mErrorMessage(inOriginal.mErrorMessage)
{
}

	// Destructor

ErrorMessage::~ErrorMessage()
{
}

	// Assignment operator

void ErrorMessage::operator=(const ErrorMessage& inOriginal)
{
	mErrorCode = inOriginal.mErrorCode;
	mErrorMessage = inOriginal.mErrorMessage;
}

	// Equality comparison

bool ErrorMessage::operator==(const ErrorMessage& inCompareTo)
{
	return (mErrorCode == inCompareTo.mErrorCode) && (mErrorMessage == inCompareTo.mErrorMessage);
}

bool ErrorMessage::operator==(const SInt32 inCompareTo)
{
	return mErrorCode == inCompareTo;
}

bool ErrorMessage::operator!=(const SInt32 inCompareTo)
{
	return mErrorCode != inCompareTo;
}

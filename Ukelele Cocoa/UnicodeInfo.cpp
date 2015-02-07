/*
 *  UnicodeInfo.cpp
 *  Ukelele 3
 *
 *  Created by John Brownie on 15/01/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "UnicodeInfo.h"
#include "NBundle.h"
#include "NFileUtilities.h"
#include "NTextUtilities.h"

const NString kUnicodeInfoFileName = "UCDNamesList";

UnicodeInfo::UnicodeInfo(void)
: mStaticDataInitialized(false)
{
}

UnicodeInfo::~UnicodeInfo(void)
{
}

UnicodeInfo *UnicodeInfo::GetInstance(void)
{
	static UnicodeInfo *sUnicodeInfo = NULL;
	return CreateInstance<UnicodeInfo>(&sUnicodeInfo);
}

void UnicodeInfo::InitializeStaticData(void)
{
	NFile dataFile = NBundleResource(kUnicodeInfoFileName, "txt");
	NN_ASSERT(dataFile.Exists());
	NString fileData = NFileUtilities::GetFileText(dataFile);
	NStringList fileLines = fileData.Split("\n");
	for (NStringListIterator line = fileLines.begin(); line != fileLines.end(); ++line) {
		NStringList currLinePieces = (*line).Split("\t");
		NN_ASSERT(currLinePieces.size() == 2);
		unsigned int codePoint;
		sscanf(currLinePieces[0].GetUTF8(), "%x", &codePoint);
		mInfoTable.insert(std::make_pair<UInt32, NString>(static_cast<UInt32>(codePoint), currLinePieces[1]));
	}
	mStaticDataInitialized = true;
}

NString UnicodeInfo::GetCodePointName(const UInt32 inCodePoint)
{
	NString theName = "";
	std::map<UInt32, NString>::iterator pos = mInfoTable.find(inCodePoint);
	if (pos != mInfoTable.end()) {
		theName = pos->second;
	}
	return theName;
}


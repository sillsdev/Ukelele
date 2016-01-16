/*
 *  XMLUtilities.cpp
 *  Ukelele 3
 *
 *  Created by John Brownie on 15/01/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "XMLUtilities.h"
#include "NTextUtilities.h"
#include "NBundle.h"
#include "boost/scoped_array.hpp"
#include "NCFString.h"
#import "NCocoa.h"
#import "UnicodeTable.h"

	
// Strings
const NString kCodePointBeyondUnicode = "CodePointBeyondUnicode";
const NString kCodePointInSurrogateRange = "CodePointInSurrogateRange";
const NString kCodePointNotUnicodeCharacter = "CodePointNotUnicodeCharacter";
const NString kErrorTableName = "errors";

	// Search patterns
static NString kFindNumericPattern("&#[0-9]+;");
static NString kFindNumericHexPattern("&#x[0-9a-fA-F]+;");

	// Important code points
static UInt32 kC0UpperLimit = 31;
static UInt32 kForwardDelete = 0x7f;
static UInt32 kASCIILast = 0x7f;
static UInt32 kC1LowerLimit = 0x80;
static UInt32 kC1UpperLimit = 0x9f;
static UInt32 kArabicPresentationNonCharFirst = 0xfdd0;
static UInt32 kArabicPresentationNonCharLast = 0xfdef;
static UInt32 kCombiningDiacriticFirst = 0x300;
static UInt32 kCombiningDiacriticLast = 0x36f;
static UInt32 kCombiningDiacriticSupplementFirst = 0x1dc0;
static UInt32 kCombiningDiacriticSupplementLast = 0x1dff;
static UInt32 kCombiningDiacriticSymbolsFirst = 0x20d0;
static UInt32 kCombiningDiacriticSymbolsLast = 0x20ff;
static UInt32 kCombiningCyrillicFirst = 0x0483;
static UInt32 kCombiningCyrillicLast = 0x0489;
static UInt32 kCombiningCyrillicExtendedLowRangeFirst = 0xa66f;
static UInt32 kCombiningCyrillicExtendedLowRangeLast = 0xa672;
static UInt32 kCombiningCyrillicExtendedHighRangeFirst = 0xac7c;
static UInt32 kCombiningCyrillicExtendedHighRangeLast = 0xac7d;
static UInt32 kCombiningNkoFirst = 0x07eb;
static UInt32 kCombiningNkoLast = 0x07f3;
static UInt32 kCombiningEthiopic = 0x135f;
static UInt32 kCombiningTaiTham = 0x1a7f;
static UInt32 kCombiningBalineseMusicalSymbolFirst = 0x1b6b;
static UInt32 kCombiningBalineseMusicalSymbolLast = 0x1b73;
static UInt32 kCombiningCopticFirst = 0x2cef;
static UInt32 kCombiningCopticLast = 0x2cf1;
static UInt32 kCombiningSalvonicFirst = 0x2de0;
static UInt32 kCombiningSalvonicLast = 0x2dff;
static UInt32 kCombiningKatakanaHiraganaFirst = 0x3099;
static UInt32 kCombiningKatakanaHiraganaLast = 0x309a;
static UInt32 kCombiningBamumFirst = 0xa6f0;
static UInt32 kCombiningBamumLast = 0xa6f1;
static UInt32 kCombiningDevanagariSamavedaFirst = 0xa8e0;
static UInt32 kCombiningDevanagariSamavedaLast = 0xa8f1;
static UInt32 kCombiningHalfMarksFirst = 0xfe20;
static UInt32 kCombiningHalfMarksLast = 0xfe2f;
static UInt32 kCombiningPhaistos = 0x101fd;
static UInt32 kCombiningMusicalSymbolGroup1First = 0x1d165;
static UInt32 kCombiningMusicalSymbolGroup1Last = 0x1d169;
static UInt32 kCombiningMusicalSymbolGroup2First = 0x1d16d;
static UInt32 kCombiningMusicalSymbolGroup2Last = 0x1d172;
static UInt32 kCombiningMusicalSymbolGroup3First = 0x1d17b;
static UInt32 kCombiningMusicalSymbolGroup3Last = 0x1d18b;
static UInt32 kCombiningMusicalSymbolGroup4First = 0x1d1aa;
static UInt32 kCombiningMusicalSymbolGroup4Last = 0x1d1ad;
static UInt32 kCombiningGreekMusicalFirst = 0x1d242;
static UInt32 kCombiningGreekMusicalLast = 0x1d244;

	// IsValidUnicode
	//	Return true if the given 32-bit value is a valid Unicode
	//	code point for a stand-alone character, i.e. within the Unicode
	//	range, not a non-character, and not in the surrogate pair range.
	//	If it is not valid, a string explaining the error is passed back.

bool
XMLUtilities::IsValidUnicode(const UInt32 inCodePoint, NString& outErrorString)
{
	bool isValid = true;
	NString errorString("");
	NString formatString;
	if (inCodePoint > 0x10ffff) {
			// Value is greater than the Unicode range
		isValid = false;
		formatString = NBundleString(kCodePointBeyondUnicode, "", kErrorTableName);
		errorString.Format(formatString, inCodePoint);
	}
	else if (UCIsSurrogateHighCharacter((UniChar)inCodePoint)) {
			// High surrogate
		isValid = false;
		formatString = NBundleString(kCodePointInSurrogateRange, "", kErrorTableName);
		errorString.Format(formatString, inCodePoint);
	}
	else if (UCIsSurrogateLowCharacter((UniChar)inCodePoint)) {
			// Low surrogate
		isValid = false;
		formatString = NBundleString(kCodePointInSurrogateRange, "", kErrorTableName);
		errorString.Format(formatString, inCodePoint);
	}
	else if ((inCodePoint & 0xffff) == kUnicodeSwappedByteOrderMark ||
			 (inCodePoint & 0xffff) == kUnicodeNotAChar) {
			// Non-character
		isValid = false;
		formatString = NBundleString(kCodePointNotUnicodeCharacter, "", kErrorTableName);
		errorString.Format(formatString, inCodePoint);
	}
	else if (inCodePoint >= kArabicPresentationNonCharFirst	&&
			 inCodePoint <= kArabicPresentationNonCharLast) {
			// Non-characters in the Arabic presentation range
		isValid = false;
		formatString = NBundleString(kCodePointNotUnicodeCharacter, "", kErrorTableName);
		errorString.Format(formatString, inCodePoint);
	}
	if (!isValid) {
		outErrorString = errorString;
	}
	return isValid;
}

	// Test whether a code point is a combining diacritic

bool XMLUtilities::IsCombiningDiacritic(const UInt32 inCodePoint)
{
	bool result = false;
	if (inCodePoint >= kCombiningDiacriticFirst && inCodePoint <= kCombiningDiacriticLast) {
		result = true;
	}
	else if (inCodePoint >= kCombiningDiacriticSupplementFirst && inCodePoint <= kCombiningDiacriticSupplementLast) {
		result = true;
	}
	else if (inCodePoint >= kCombiningDiacriticSymbolsFirst && inCodePoint <= kCombiningDiacriticSymbolsLast) {
		result = true;
	}
	else if (inCodePoint >= kCombiningCyrillicFirst && inCodePoint <= kCombiningCyrillicLast) {
		result = true;
	}
	else if (inCodePoint >= kCombiningCyrillicExtendedLowRangeFirst && inCodePoint <= kCombiningCyrillicExtendedLowRangeLast) {
		result = true;
	}
	else if (inCodePoint >= kCombiningCyrillicExtendedHighRangeFirst && inCodePoint <= kCombiningCyrillicExtendedHighRangeLast) {
		result = true;
	}
	else if (inCodePoint >= kCombiningNkoFirst && inCodePoint <= kCombiningNkoLast) {
		result = true;
	}
	else if (inCodePoint == kCombiningEthiopic) {
		result = true;
	}
	else if (inCodePoint == kCombiningTaiTham) {
		result = true;
	}
	else if (inCodePoint >= kCombiningBalineseMusicalSymbolFirst &&
			 inCodePoint <= kCombiningBalineseMusicalSymbolLast) {
		result = true;
	}
	else if (inCodePoint >= kCombiningCopticFirst && inCodePoint <= kCombiningCopticLast) {
		result = true;
	}
	else if (inCodePoint >= kCombiningSalvonicFirst && inCodePoint <= kCombiningSalvonicLast) {
		result = true;
	}
	else if (inCodePoint >= kCombiningKatakanaHiraganaFirst &&
			 inCodePoint <= kCombiningKatakanaHiraganaLast) {
		result = true;
	}
	else if (inCodePoint >= kCombiningBamumFirst && inCodePoint <= kCombiningBamumLast) {
		result = true;
	}
	else if (inCodePoint >= kCombiningDevanagariSamavedaFirst &&
			 inCodePoint <= kCombiningDevanagariSamavedaLast) {
		result = true;
	}
	else if (inCodePoint >= kCombiningHalfMarksFirst && inCodePoint <= kCombiningHalfMarksLast) {
		result = true;
	}
	else if (inCodePoint == kCombiningPhaistos) {
		result = true;
	}
	else if (inCodePoint >= kCombiningMusicalSymbolGroup1First &&
			 inCodePoint <= kCombiningMusicalSymbolGroup1Last) {
		result = true;
	}
	else if (inCodePoint >= kCombiningMusicalSymbolGroup2First &&
			 inCodePoint <= kCombiningMusicalSymbolGroup2Last) {
		result = true;
	}
	else if (inCodePoint >= kCombiningMusicalSymbolGroup3First &&
			 inCodePoint <= kCombiningMusicalSymbolGroup3Last) {
		result = true;
	}
	else if (inCodePoint >= kCombiningMusicalSymbolGroup4First &&
			 inCodePoint <= kCombiningMusicalSymbolGroup4Last) {
		result = true;
	}
	else if (inCodePoint >= kCombiningGreekMusicalFirst &&
			 inCodePoint <= kCombiningGreekMusicalLast) {
		result = true;
	}
	return result;
}

	// Return a string in U+xxxx form representing the input string

NString
XMLUtilities::CreateCanonicalForm(const UniChar *inBuffer, const UInt32 inBufferLength)
{
	NString canonicalForm("");
	UnicodeTable *unicodeInfo = [UnicodeTable getInstance];
	for (UInt32 i = 0; i < inBufferLength; i++) {
		NString codePoint;
		UInt32 codePointValue;
		if (UCIsSurrogateHighCharacter(inBuffer[i])) {
				// Start of a surrogate pair
			NN_ASSERT(i + 1 < inBufferLength);
			codePointValue = UCGetUnicodeScalarValueForSurrogatePair(inBuffer[i], inBuffer[i + 1]);
			i++;
			codePoint.Format(" U+%05X", codePointValue);
		}
		else {
				// Character in BMP
			codePoint.Format(" U+%04X", inBuffer[i]);
			codePointValue = inBuffer[i];
		}
		canonicalForm += codePoint;
		NString codePointName = ToNN([unicodeInfo descriptionForCodePoint:codePointValue]);
		if (codePointName != "") {
			canonicalForm += " ";
			canonicalForm += codePointName;
		}
	}
	canonicalForm.TrimLeft(" ");
	return canonicalForm;
}

NString
XMLUtilities::CreateCanonicalForm(const NString inString)
{
		// Get the string as a UTF-16 buffer
	const UniChar *stringBuffer = inString.GetUTF16();
		// Calculate its length, using the fact that it's NULL-terminated
	UInt32 bufferLength;
	for (bufferLength = 0; stringBuffer[bufferLength] != 0; bufferLength++) {
			// Do nothing
	}
		// Create the XML string using the other version of the routine
	NString canonicalForm = CreateCanonicalForm(stringBuffer, bufferLength);
	return canonicalForm;
}

	// Encode whatever needs to be to make a valid XML string representing the input string

NString
XMLUtilities::MakeXMLString(const NString inString, const bool inCodeNonAscii)
{
		// Get the string as a UTF-16 buffer
	const UniChar *stringBuffer = inString.GetUTF16();
		// Calculate its length, using the fact that it's NULL-terminated
	UInt32 bufferLength;
	for (bufferLength = 0; stringBuffer[bufferLength] != 0; bufferLength++) {
			// Do nothing
	}
		// Create the XML string using the other version of the routine
	NString xmlString = MakeXMLString(stringBuffer, bufferLength, inCodeNonAscii);
	return xmlString;
}

NString
XMLUtilities::MakeXMLString(const UniChar *inString, const UInt32 inStringLength, const bool inCodeNonAscii)
{
	NString xmlString("");
	for (UInt32 i = 0; i < inStringLength; i++) {
			// See if we have one of the characters that needs to be encoded
			// for valid XML
		if (NeedsEncoding(inString[i], inCodeNonAscii)) {
			NString codeString;
			codeString.Format("&#x%04X;", inString[i]);
			xmlString += codeString;
		}
		else if (UCIsSurrogateHighCharacter(inString[i])) {
				// We have a surrogate pair
			assert(i < inStringLength - 1);
			assert(UCIsSurrogateLowCharacter(inString[i + 1]));
			xmlString += NString(&inString[i], 2 * sizeof(UniChar), kNStringEncodingUTF16);
			i++;
		}
		else {
			xmlString += NString(&inString[i], sizeof(UniChar), kNStringEncodingUTF16);
		}
	}
	return xmlString;
}

bool XMLUtilities::NeedsEncoding(const UniChar inChar, const bool inCodeNonAscii) {
	bool result = false;
	if (inChar <= kC0UpperLimit ||	// C0 control character
		inChar == kForwardDelete ||	// Forward delete
		(inChar >= kC1LowerLimit && inChar <= kC1UpperLimit) ||	// C1 control character
		inChar == '"' ||	// Double quote
		inChar == '&' ||	// Ampersand
		inChar == '<' ||	// Less than/left angle bracket
		inChar == '>' ||	// Greater than/right angle bracket
		inChar == '\'') {	// Single quote
		result = true;
	}
	if (inCodeNonAscii && inChar >= kASCIILast) {
		result = true;
	}
	return result;
}

	// Decode an XML string into the equivalent UTF-16

void
XMLUtilities::ConvertEncodedString(const NString inString, UniChar *ioBuffer, UInt32& ioLength)
{
		// Get the string as a UTF-16 buffer
	const UniChar *stringChars = inString.GetUTF16();
		// Calculate its length, using the fact that it's NULL-terminated
	UInt32 bufferLength;
	for (bufferLength = 0; stringChars[bufferLength] != 0; bufferLength++) {
			// Do nothing
	}
	if (ioLength < bufferLength) {
			// Buffer isn't big enough
		ioLength = 0;
		return;
	}
	boost::scoped_array<UniChar> stringBuffer(new UniChar[bufferLength]);
	for (UInt32 p = 0; p < bufferLength; p++) {
		stringBuffer[p] = stringChars[p];
	}
	UInt32 outputPtr = 0;
	for (UInt32 i = 0; i < bufferLength; i++) {
		UInt32 result = stringBuffer[i];
		if (result == '&') {
				// May have an encoded character
			NRange searchRange(i, bufferLength - i);
			NRange findRange = inString.Find(kFindNumericPattern, kNStringPattern, searchRange);
			if (findRange != kNRangeNone) {
					// We have a decimal numeric entry
				NRange numberRange(i + 2, findRange.GetSize() - 3);
				NNumber decNumber(inString.GetString(numberRange));
				int32_t decValue = decNumber.GetInt32();
				NString decError;
				if (IsValidUnicode(decValue, decError)) {
					result = decValue;
				}
				else {
					result = kUnicodeNotAChar;
				}
				i += findRange.GetSize() - 1;
			}
			else {
				findRange = inString.Find(kFindNumericHexPattern, kNStringPattern, searchRange);
				if (findRange != kNRangeNone) {
						// We have a hexadecimal numeric entry
					NString hexNumber = inString.GetString(NRange(i + 3, findRange.GetSize() - 4));
					unsigned int hexValue;
					int scanValue = sscanf(hexNumber.GetUTF8(), "%x", &hexValue);
#pragma unused(scanValue)
					NN_ASSERT(scanValue == 1);
					NString hexError;
					if (IsValidUnicode(hexValue, hexError)) {
						result = hexValue;
					}
					else {
						result = kUnicodeNotAChar;
					}
					i += findRange.GetSize() - 1;
				}
					// If we get here, it's not a valid numeric sequence, so leave it as is
			}
		}
		if (result != kUnicodeNotAChar) {
			if (result > 0xffff) {
					// Convert to surrogate pair
				result -= 0x10000;
				UInt32 part1 = (result >> 10) & 0x3ff;
				part1 += kUCHighSurrogateRangeStart;
				UInt32 part2 = result & 0x3ff;
				part2 += kUCLowSurrogateRangeStart;
				ioBuffer[outputPtr++] = (UniChar)part1;
				ioBuffer[outputPtr++] = (UniChar)part2;
			}
			else {
				ioBuffer[outputPtr++] = (UniChar)result;
			}
		}
	}
	ioLength = outputPtr;
}

NString XMLUtilities::ConvertEncodedString(const NString inString)
{
	UInt32 bufferLength = 2 * inString.GetSize();
	boost::scoped_array<UniChar> stringBuffer(new UniChar[bufferLength]);
	ConvertEncodedString(inString, stringBuffer.get(), bufferLength);
	return NString(stringBuffer.get(), bufferLength * sizeof(UniChar), kNStringEncodingUTF16);
}

	// Create a valid XML string from the given string, which may contain encoded characters

NString XMLUtilities::ConvertToXMLString(const NString inString)
{
	UInt32 bufferLength = 2 * inString.GetSize();
	boost::scoped_array<UniChar> buffer(new UniChar[bufferLength]);
	ConvertEncodedString(inString, buffer.get(), bufferLength);
	NString convertedString = MakeXMLString(buffer.get(), bufferLength, false);
	return convertedString;
}

	// Create a valid XML name to represent a string

NString
XMLUtilities::MakeXMLName(const NString inString)
{
	NString result;
	if (inString.IsEmpty()) {
		result = "NULL";
	}
	else if (inString.GetSize() == 1) {
		UniChar theChar = CFStringGetCharacterAtIndex(NCFString(inString).GetObject(), 0);
		switch (theChar) {
			case ';':
				result = "semicolon";
				break;
				
			case ':':
				result = "colon";
				break;
				
			case '"':
				result = "double quote";
				break;
				
			case '\'':
				result = "quote";
				break;
				
			case '.':
				result = "dot";
				break;
				
			case ',':
				result = "comma";
				break;
				
			case '/':
				result = "slash";
				break;
				
			case '>':
				result = "greater than";
				break;
				
			case '<':
				result = "less than";
				break;
				
			case '&':
				result = "ampersand";
				break;
				
			default:
				result = inString;
				break;
		}
	}
	else {
		result = inString;
	}
	return result;
}


/*
 *  XMLUtilities.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 15/01/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _XMLUTILITIES_H_
#define _XMLUTILITIES_H_

#include "Nano.h"
#include "NString.h"

class XMLUtilities {
public:
		// Test whether a code point is a valid Unicode code point
	static bool IsValidUnicode(const UInt32 inCodePoint, NString& outErrorString);
		// Test whether a code point is a combining diacritic
	static bool IsCombiningDiacritic(const UInt32 inCodePoint);
		// Return a string in U+xxxx form representing the string
	static NString CreateCanonicalForm(const UniChar *inBuffer, const UInt32 inBufferLength);
	static NString CreateCanonicalForm(const NString inString);
		// Encode whatever needs to be for a valid XML string
	static NString MakeXMLString(const NString inString, const bool inCodeNonAscii);
	static NString MakeXMLString(const UniChar *inString, const UInt32 inStringLength, const bool inCodeNonAscii);
	static bool NeedsEncoding(const UniChar inChar, const bool inCodeNonAscii);
		// Decode an XML string into the equivalent Unicode
	static void ConvertEncodedString(const NString inString, UniChar *ioBuffer, UInt32& ioLength);
	static NString ConvertEncodedString(const NString inString);
		// Convert a possibly encoded string into the equivalent XML string
	static NString ConvertToXMLString(const NString inString, const bool inCodeNonAscii);
		// Create a name to represent a string
	static NString MakeXMLName(const NString inString);
};

#endif /* _XMLUTILITIES_H_ */

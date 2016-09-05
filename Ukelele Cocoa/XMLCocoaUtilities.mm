//
//  XMLCocoaUtilities.mm
//  Ukelele 3
//
//  Created by John Brownie on 4/02/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "XMLCocoaUtilities.h"
#import "XMLUtilities.h"
#import "NCocoa.h"

@implementation XMLCocoaUtilities

+ (BOOL)isValidUnicode:(unsigned int)codePoint withError:(NSString **)errorMessage
{
	NString theError;
	bool isValid = XMLUtilities::IsValidUnicode(codePoint, theError);
	if (!isValid) {
		*errorMessage = ToNS(theError);
	}
	return isValid;
}

+ (BOOL)isCombiningDiacritic:(unsigned int)codePoint
{
	return XMLUtilities::IsCombiningDiacritic(codePoint);
}

+ (NSString *)createCanonicalForm:(NSString *)inputString
{
	NString originalString = ToNN(inputString);
	NString canonicalForm = XMLUtilities::CreateCanonicalForm(originalString);
	return ToNS(canonicalForm);
}

+ (NSString *)makeXMLString:(NSString *)inputString codingNonAscii:(BOOL)codeNonAscii
{
	NString originalString = ToNN(inputString);
	NString xmlString = XMLUtilities::MakeXMLString(originalString, codeNonAscii);
	return ToNS(xmlString);
}

+ (NSString *)convertEncodedString:(NSString *)inputString
{
	NString originalString = ToNN(inputString);
	NString convertedString = XMLUtilities::ConvertEncodedString(originalString);
	return ToNS(convertedString);
}

+ (NSString *)convertToXMLString:(NSString *)inputString codingNonAscii:(BOOL)encodingNonAscii
{
	NString originalString = ToNN(inputString);
	NString convertedString = XMLUtilities::ConvertToXMLString(originalString, encodingNonAscii);
	return ToNS(convertedString);
}

+ (NSString *)makeXMLName:(NSString *)inputString
{
	NString originalString = ToNN(inputString);
	NString xmlName = XMLUtilities::MakeXMLName(originalString);
	return ToNS(xmlName);
}

@end

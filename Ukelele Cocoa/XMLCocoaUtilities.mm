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

@end

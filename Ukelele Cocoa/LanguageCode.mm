//
//  LanguageCode.mm
//  Ukelele 3
//
//  Created by John Brownie on 25/10/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "LanguageCode.h"
#import "NString.h"
#import "NCocoa.h"

@implementation LanguageCode

- (id)init {
	self = [super init];
	if (self) {
		_languageCode = @"";
		_scriptCode = @"";
		_regionCode = @"";
		_variantCode = @"";
	}
	return self;
}

+ (LanguageCode *)languageCodeFromString:(NSString *)languageString {
	static NString stringRegex = "([a-zA-Z]{2,3})[-_]?([a-zA-Z]{4})?[-_]?([a-zA-Z]{2}|[0-9]{3})?[-_]?([a-zA-Z]{5-8}|[0-9a-zA-Z]{4})?";
	if (languageString == nil) {
			// Null string
		return nil;
	}
	NString searchString = ToNN(languageString);
	NRangeList rangeList = searchString.FindAll(stringRegex, kNStringPattern);
	NString languageCode = "";
	NString scriptCode = "";
	NString regionCode = "";
	NString variantCode = "";
	if (rangeList.size() >= 5) {
		languageCode = searchString.GetString(rangeList[1]);
		scriptCode = searchString.GetString(rangeList[2]);
		regionCode = searchString.GetString(rangeList[3]);
		variantCode = searchString.GetString(rangeList[4]);
	}
	LanguageCode *result = [[LanguageCode alloc] init];
	[result setLanguageCode:ToNS(languageCode)];
	[result setScriptCode:ToNS(scriptCode)];
	[result setRegionCode:ToNS(regionCode)];
	[result setVariantCode:ToNS(variantCode)];
	return [result autorelease];
}

- (NSString *)stringRepresentation {
	NSMutableString *result = [self.languageCode mutableCopy];
	if (![self.scriptCode isEqualToString:@""]) {
		[result appendFormat:@"-%@", self.scriptCode];
	}
	if (![self.regionCode isEqualToString:@""]) {
		[result appendFormat:@"-%@", self.regionCode];
	}
	if (![self.variantCode isEqualToString:@""]) {
		[result appendFormat:@"-%@", self.variantCode];
	}
	return [result autorelease];
}

@end

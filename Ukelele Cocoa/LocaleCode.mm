//
//  LocaleCode.mm
//  Ukelele
//
//  Created by John Brownie on 14/10/16.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#import "LocaleCode.h"
#import "NString.h"
#import "NCocoa.h"

@implementation LocaleCode

- (instancetype)init {
    self = [super init];
    if (self) {
        _languageCode = @"";
        _scriptCode = @"";
        _regionCode = @"";
    }
    return self;
}

+ (LocaleCode *)localeCodeFromString:(NSString *)languageString {
    static NString stringRegex = "([a-zA-Z]{2,3})[-_]?([a-zA-Z]{4})?[-_]?([a-zA-Z]{2}|[0-9]{3})?";
    if (languageString == nil) {
        // Null string
        return nil;
    }
    NString searchString = ToNN(languageString);
    NRangeList rangeList = searchString.FindAll(stringRegex, kNStringPattern);
    NString languageCode = "";
    NString scriptCode = "";
    NString regionCode = "";
    if (rangeList.size() >= 4) {
        languageCode = searchString.GetString(rangeList[1]);
        scriptCode = searchString.GetString(rangeList[2]);
        regionCode = searchString.GetString(rangeList[3]);
    }
    LocaleCode *result = [[LocaleCode alloc] init];
    [result setLanguageCode:ToNS(languageCode)];
    [result setScriptCode:ToNS(scriptCode)];
    [result setRegionCode:ToNS(regionCode)];
    return result;
}

- (BOOL)isEqualTo:(id)object {
	LocaleCode *theCode = (LocaleCode *)object;
	return [self.languageCode isEqualToString:theCode.languageCode] &&
		[self.scriptCode isEqualToString:theCode.scriptCode] &&
		[self.regionCode isEqualToString:theCode.regionCode];
}

- (NSString *)stringRepresentation {
    NSMutableString *result = [self.languageCode mutableCopy];
    if (![self.scriptCode isEqualToString:@""]) {
        [result appendFormat:@"-%@", self.scriptCode];
    }
    if (![self.regionCode isEqualToString:@""]) {
        [result appendFormat:@"_%@", self.regionCode];
    }
    return result;
}

@end

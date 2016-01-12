//
//  ScriptInfo.m
//  Ukelele 3
//
//  Created by John Brownie on 1/08/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "ScriptInfo.h"
#import "ScriptRanges.h"
#import "RandomNumberGenerator.h"

@implementation ScriptInfo

- (instancetype) init NS_UNAVAILABLE {
	abort();
}

- (instancetype)initWithName:(NSString *)theName scriptID:(NSInteger)ID minID:(NSInteger)minimumID maxID:(NSInteger)maximumID description:(NSString *)description
{
	self = [super init];
	if (self) {
		_scriptName = theName;
		_scriptID = ID;
		_minID = minimumID;
		_maxID = maximumID;
		_scriptDescription = description;
	}
	return self;
}

+ (ScriptInfo *)scriptWithName:(NSString *)theName script:(NSInteger)ID minID:(NSInteger)minimumID maxID:(NSInteger)maximumID description:(NSString *)description {
	return [[ScriptInfo alloc] initWithName:theName scriptID:ID minID:minimumID maxID:maximumID description:description];
}

+ (NSArray *)standardScripts
{
	static NSArray *scriptArray = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSString *unicodeDescription = [[NSBundle mainBundle] localizedStringForKey:@"UnicodeDescription" value:@"Unicode" table:@"scripts"];
		NSString *romanDescription = [[NSBundle mainBundle] localizedStringForKey:@"RomanDescription" value:@"Roman" table:@"scripts"];
		NSString *japaneseDescription = [[NSBundle mainBundle] localizedStringForKey:@"JapaneseDescription" value:@"Japanese" table:@"scripts"];
		NSString *simplifiedChineseDescription = [[NSBundle mainBundle] localizedStringForKey:@"SimplifiedChineseDescription" value:@"Simplified Chinese" table:@"scripts"];
		NSString *traditionalChineseDescription = [[NSBundle mainBundle] localizedStringForKey:@"TraditionalChineseDescription" value:@"Traditional Chinese" table:@"scripts"];
		NSString *koreanDescription = [[NSBundle mainBundle] localizedStringForKey:@"KoreanDescription" value:@"Korean" table:@"scripts"];
		NSString *cyrillicDescription = [[NSBundle mainBundle] localizedStringForKey:@"CyrillicDescription" value:@"Cyrillic" table:@"scripts"];
		NSString *centralEuropeanDescription = [[NSBundle mainBundle] localizedStringForKey:@"CentralEuropeanDescription" value:@"Central European" table:@"scripts"];
		scriptArray = @[[ScriptInfo scriptWithName:@"Unicode" script:kTextEncodingMacUnicode minID:kIDMinimumUnicode maxID:kIDMaximumUnicode description: unicodeDescription],
						[ScriptInfo scriptWithName:@"Roman" script:kTextEncodingMacRoman minID:kIDMinimumRoman maxID:kIDMaximumRoman description:romanDescription],
						[ScriptInfo scriptWithName:@"Japanese" script:kTextEncodingMacJapanese minID:kIDMinimumJapanese maxID:kIDMaximumJapanese description:japaneseDescription],
						[ScriptInfo scriptWithName:@"Simplified Chinese" script:kTextEncodingMacChineseSimp minID:kIDMinimumSimplifiedChinese maxID:kIDMaximumSimplifiedChinese description:simplifiedChineseDescription],
						[ScriptInfo scriptWithName:@"Traditional Chinese" script:kTextEncodingMacChineseTrad minID:kIDMinimumTraditionalChinese maxID:kIDMaximumTraditionalChinese description:traditionalChineseDescription],
						[ScriptInfo scriptWithName:@"Korean" script:kTextEncodingMacKorean minID:kIDMinimumKorean maxID:kIDMaximumKorean description:koreanDescription],
						[ScriptInfo scriptWithName:@"Cyrillic" script:kTextEncodingMacCyrillic minID:kIDMinimumCyrillic maxID:kIDMaximumCyrillic description:cyrillicDescription],
						[ScriptInfo scriptWithName:@"Central European" script:kTextEncodingMacCentralEurRoman minID:kIDMinimumCentralEuropean maxID:kIDMaximumCentralEuropean description:centralEuropeanDescription]];
	});
	return scriptArray ;
}

- (NSInteger)randomID {
	RandomNumberGenerator *generator = RandomNumberGenerator::GetInstance();
	NSInteger generatedID = generator->GetRandomSInt32((SInt32)_minID, (SInt32)_maxID);
	return generatedID;
}

+ (NSInteger)randomIDforScript:(NSInteger)scriptID {
	for (ScriptInfo *scriptInfo in [ScriptInfo standardScripts]) {
		if ([scriptInfo scriptID] == scriptID) {
			return [scriptInfo randomID];
		}
	}
	return 0;
}

+ (NSInteger)indexForScript:(NSInteger)scriptID {
	NSInteger theIndex = -1;
	NSArray *theScripts = [ScriptInfo standardScripts];
	for (NSInteger index = 0; index < (NSInteger)[theScripts count]; index++) {
		ScriptInfo *theInfo = theScripts[index];
		if ([theInfo scriptID] == scriptID) {
			theIndex = index;
			break;
		}
	}
	return theIndex;
}

@end

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

- (instancetype)initWithName:(NSString *)theName scriptID:(NSInteger)ID minID:(NSInteger)minimumID maxID:(NSInteger)maximumID
{
	self = [super init];
	if (self) {
		_scriptName = theName;
		_scriptID = ID;
		_minID = minimumID;
		_maxID = maximumID;
	}
	return self;
}

+ (ScriptInfo *)scriptWithName:(NSString *)theName script:(NSInteger)ID minID:(NSInteger)minimumID maxID:(NSInteger)maximumID {
	return [[ScriptInfo alloc] initWithName:theName scriptID:ID minID:minimumID maxID:maximumID];
}

+ (NSArray *)standardScripts
{
	static NSArray *scriptArray = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		scriptArray = @[[ScriptInfo scriptWithName:@"Unicode" script:kTextEncodingMacUnicode minID:kIDMinimumUnicode maxID:kIDMaximumUnicode],
						[ScriptInfo scriptWithName:@"Roman" script:kTextEncodingMacRoman minID:kIDMinimumRoman maxID:kIDMaximumRoman],
						[ScriptInfo scriptWithName:@"Japanese" script:kTextEncodingMacJapanese minID:kIDMinimumJapanese maxID:kIDMaximumJapanese],
						[ScriptInfo scriptWithName:@"Simplified Chinese" script:kTextEncodingMacChineseSimp minID:kIDMinimumSimplifiedChinese maxID:kIDMaximumSimplifiedChinese],
						[ScriptInfo scriptWithName:@"Traditional Chinese" script:kTextEncodingMacChineseTrad minID:kIDMinimumTraditionalChinese maxID:kIDMaximumTraditionalChinese],
						[ScriptInfo scriptWithName:@"Korean" script:kTextEncodingMacKorean minID:kIDMinimumKorean maxID:kIDMaximumKorean],
						[ScriptInfo scriptWithName:@"Cyrillic" script:kTextEncodingMacCyrillic minID:kIDMinimumCyrillic maxID:kIDMaximumCyrillic],
						[ScriptInfo scriptWithName:@"Central European" script:kTextEncodingMacCentralEurRoman minID:kIDMinimumCentralEuropean maxID:kIDMaximumCentralEuropean]];
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

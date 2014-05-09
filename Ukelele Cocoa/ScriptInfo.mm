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

- (id)initWithName:(NSString *)theName scriptID:(NSInteger)ID minID:(NSInteger)minimumID maxID:(NSInteger)maximumID
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

+ (NSArray *)standardScripts
{
	static NSArray *scriptArray = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		scriptArray = @[[[ScriptInfo alloc] initWithName:@"Unicode"
												scriptID:kTextEncodingMacUnicode
												   minID:kIDMinimumUnicode
												   maxID:kIDMaximumUnicode],
		[[ScriptInfo alloc] initWithName:@"Roman"
								scriptID:kTextEncodingMacRoman
								   minID:kIDMinimumRoman
								   maxID:kIDMaximumRoman],
		[[ScriptInfo alloc] initWithName:@"Japanese"
								scriptID:kTextEncodingMacJapanese
								   minID:kIDMinimumJapanese
								   maxID:kIDMaximumJapanese],
		[[ScriptInfo alloc] initWithName:@"Simplified Chinese"
								scriptID:kTextEncodingMacChineseSimp
								   minID:kIDMinimumSimplifiedChinese
								   maxID:kIDMaximumSimplifiedChinese],
		[[ScriptInfo alloc] initWithName:@"Traditional Chinese"
								scriptID:kTextEncodingMacChineseTrad
								   minID:kIDMinimumTraditionalChinese
								   maxID:kIDMaximumTraditionalChinese],
		[[ScriptInfo alloc] initWithName:@"Korean"
								scriptID:kTextEncodingMacKorean
								   minID:kIDMinimumKorean
								   maxID:kIDMaximumKorean],
		[[ScriptInfo alloc] initWithName:@"Cyrillic"
								scriptID:kTextEncodingMacCyrillic
								   minID:kIDMinimumCyrillic
								   maxID:kIDMaximumCyrillic],
		[[ScriptInfo alloc] initWithName:@"Central European"
								scriptID:kTextEncodingMacCentralEurRoman
								   minID:kIDMinimumCentralEuropean
								   maxID:kIDMaximumCentralEuropean]];
	});
	return scriptArray;
}

- (NSInteger)randomID {
	RandomNumberGenerator *generator = RandomNumberGenerator::GetInstance();
	NSInteger generatedID = generator->GetRandomSInt32(_minID, _maxID);
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
	for (NSInteger index = 0; index < [theScripts count]; index++) {
		ScriptInfo *theInfo = theScripts[index];
		if ([theInfo scriptID] == scriptID) {
			theIndex = index;
			break;
		}
	}
	return theIndex;
}

@end

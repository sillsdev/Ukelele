//
//  KeyCodeMap.mm
//  Ukelele 3
//
//  Created by John Brownie on 30/01/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "KeyCodeMap.h"
#include <map>

@implementation KeyCodeMap {
	std::multimap<int, KeyCapView *> codeMap;
}

- (id)init
{
	self = [super init];
	if (self) {
		codeMap.clear();
	}
	return self;
}

- (void)addKeyCode:(int)keyCode withKeyKapView:(KeyCapView *)keyCap
{
	codeMap.insert(std::make_pair(keyCode, keyCap));
}

- (int)countKeysWithCode:(int)keyCode
{
	return (int)codeMap.count(keyCode);
}

- (NSArray *)getKeysWithCode:(int)keyCode
{
	int keyCount = [self countKeysWithCode:keyCode];
	NSMutableArray *keyArray = [NSMutableArray arrayWithCapacity:keyCount];
	std::multimap<int, KeyCapView *>::iterator pos = codeMap.lower_bound(keyCode);
	for (int i = 0; i < keyCount; i++, ++pos) {
		[keyArray addObject:pos->second];
	}
	return keyArray;
}

- (void)clearMap
{
	codeMap.clear();
}

@end

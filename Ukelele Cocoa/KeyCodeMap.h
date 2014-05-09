//
//  KeyCodeMap.h
//  Ukelele 3
//
//  Created by John Brownie on 30/01/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class KeyCapView;

@interface KeyCodeMap : NSObject

- (void)addKeyCode:(int)keyCode withKeyKapView:(KeyCapView *)keyCap;
- (int)countKeysWithCode:(int)keyCode;
- (NSArray *)getKeysWithCode:(int)keyCode;
- (void)clearMap;

@end

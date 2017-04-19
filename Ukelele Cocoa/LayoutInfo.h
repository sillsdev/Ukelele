//
//  LayoutInfo.h
//  Ukelele 3
//
//  Created by John Brownie on 13/01/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KeyboardDefinitions.h"

@interface LayoutInfo : NSObject

@property int layoutID;
@property unsigned int flags;
@property (NS_NONATOMIC_IOSONLY, readonly) BOOL hasSeparateRightKeys;

+ (unsigned int)getKeyType:(unsigned int)keyCode;
+ (NSString *)getSpecialKeyOutput:(unsigned int)keyCode;
+ (NSString *)getKeySymbol:(unsigned int)keyCode withString:(NSString *)string;
+ (NSMutableAttributedString *)getKeySymbolString:(unsigned int)keyCode withString:(NSString *)string;
+ (unsigned int)getKeyboardLayoutType:(int)keyboardID;
+ (unsigned int)getKeyboardType:(int)keyboardID;
+ (int)getKeyboardNameIndex:(int)keyboardID;
+ (unsigned int)getKeyboardID:(unsigned int)keyboardName;
+ (NSDictionary *)getKeyboardList:(unsigned int)keyboardID;
+ (NSString *)getStandardKeyOutputForKeyboard:(int)keyboardID forKeyCode:(unsigned int)keyCode;
+ (NSUInteger)getStandardKeyMapForKeyboard:(NSUInteger)keyboardType withModifiers:(NSUInteger)modifiers;
+ (NSString *)getKeyboardName:(int)keyboardID;
+ (NSString *)getKeyboardDescription:(int)keyboardID;
+ (NSUInteger)getModifierFromKeyCode:(NSUInteger)keyCode;

- (instancetype)initWithLayoutID:(int)layout NS_DESIGNATED_INITIALIZER;
- (unsigned int)getFnKeyCodeForKey:(unsigned int)keyCode;

@end

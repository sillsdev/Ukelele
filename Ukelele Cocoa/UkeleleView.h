//
//  UkeleleView.h
//  Ukelele 3
//
//  Created by John Brownie on 11/01/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KeyCodeMap.h"
#import "KeyCapView.h"
#import "ColourTheme.h"
#import "ModifiersController.h"
#import "UKStyleInfo.h"
#import "UKMenuDelegate.h"

@interface UkeleleView : NSView

@property (nonatomic) CGFloat scaleFactor;
@property (nonatomic) NSRect baseFrame;
@property (strong, nonatomic) ColourTheme *colourTheme;
@property (strong, nonatomic) UKStyleInfo *styleInfo;
@property (NS_NONATOMIC_IOSONLY, readonly, copy) NSArray *keyCapViews;

- (int)createViewWithKeyboardID:(int)keyboardID withScale:(float)scaleValue;
- (void)createViewWithStream:(char *)theStream forID:(int)keyboardID withScale:(float)scaleValue;
- (KeyCapView *)getKeyWithIndex:(int)keyIndex;
- (void)setKeyText:(int)keyCode withModifiers:(unsigned int)modifiers withString:(NSString *)text;
- (KeyCapView *)findKeyWithCode:(int)keyCode;
- (void)updateModifiers:(unsigned int)modifierCombination;
- (void)scaleViewToScale:(CGFloat)scaleValue limited:(BOOL)limited;
- (void)scaleViewBy:(CGFloat)scaleValue limited:(BOOL)limited;
- (void)setMenuDelegate:(id<UKMenuDelegate>)theDelegate;
- (void)changeLargeFont:(NSFont *)newLargeFont;

@end

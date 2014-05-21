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
#import "UKMenuDelegate.h"

@interface UkeleleView : NSView {
	KeyCodeMap *keyCapMap;
	NSMutableArray *keyCapList;
	CGFloat baseFontSize;
	ModifiersController *modifiersController;
}

@property (nonatomic) CGFloat scaleFactor;
@property (nonatomic) NSRect baseFrame;
@property (strong, nonatomic) ColourTheme *colourTheme;
@property (assign, nonatomic) CTFontDescriptorRef fontDescriptor;
@property (assign, nonatomic) CTParagraphStyleRef largeParagraphStyle;
@property (assign, nonatomic) CTParagraphStyleRef smallParagraphStyle;
@property (strong, nonatomic) NSDictionary *largeAttributes;
@property (strong, nonatomic) NSDictionary *smallAttributes;

- (void)createViewWithKeyboardID:(int)keyboardID withScale:(float)scaleValue;
- (KeyCapView *)getKeyWithIndex:(int)keyIndex;
- (void)setKeyText:(int)keyCode withModifiers:(unsigned int)modifiers withString:(NSString *)text;
- (KeyCapView *)findKeyWithCode:(int)keyCode;
- (NSArray *)keyCapViews;
- (void)updateModifiers:(unsigned int)modifierCombination;
- (void)scaleViewToScale:(CGFloat)scaleValue limited:(BOOL)limited;
- (void)scaleViewBy:(CGFloat)scaleValue limited:(BOOL)limited;
- (void)setMenuDelegate:(id<UKMenuDelegate>)theDelegate;

@end
//
//  KeyCapView.h
//  Ukelele 3
//
//  Created by John Brownie on 12/01/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ColourTheme.h"
#import "UKMenuDelegate.h"
#import "UKKeyCapClick.h"

#define fallbackAlpha	0.5

@interface KeyCapView : NSView {
	NSRect keyRect;
	NSMutableAttributedString *displayText;
	CTFrameRef textFrame;
    NSTextStorage *textStorage;
	BOOL mouseIsInside;
}

@property (nonatomic) NSInteger keyCode;
@property (nonatomic) NSInteger fnKeyCode;
@property (nonatomic) NSInteger keyType;
@property (nonatomic, copy) NSString *outputString;
@property (nonatomic, strong) ColourTheme *colourTheme;
@property (nonatomic) BOOL down;
@property (nonatomic) BOOL deadKey;
@property (nonatomic) BOOL selected;
@property (nonatomic) BOOL fallback;
@property (nonatomic) BOOL small;
@property (nonatomic) BOOL dragHighlight;
@property (nonatomic, weak) NSColor *currentTextColour;
@property (nonatomic, assign) CTParagraphStyleRef largeCTStyle;
@property (nonatomic, assign) CTParagraphStyleRef smallCTStyle;
@property (nonatomic) CTFontRef largeCTFont;
@property (nonatomic) CTFontRef smallCTFont;
@property (nonatomic, strong) NSDictionary *largeAttributes;
@property (nonatomic, strong) NSDictionary *smallAttributes;
@property (nonatomic, weak) id<UKMenuDelegate> menuDelegate;
@property (nonatomic, weak) IBOutlet id<UKKeyCapClick> clickDelegate;
@property (NS_NONATOMIC_IOSONLY, readonly) NSRect boundingRect;
@property (NS_NONATOMIC_IOSONLY, readonly) NSRect insideRect;

- (void)flipInRect:(NSRect)boundingRect;
- (void)getInnerColour:(NSColor **)innerColour
		   outerColour:(NSColor **)outerColour
			textColour:(NSColor **)textColour
		  gradientType:(NSUInteger *)gradientType;
- (void)drawText:(NSRect)dirtyRect;
- (void)setScale:(CGFloat)scaleValue;
- (void)changeScaleBy:(CGFloat)scaleMultiplier;
- (void)offsetFrameX:(CGFloat)xOffset Y:(CGFloat)yOffset;
- (void)finishInit;

@end

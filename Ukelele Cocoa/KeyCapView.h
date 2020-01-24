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
#import "UKStyleInfo.h"

#define fallbackAlpha	0.5
#define kKeyInset 2.0f
#define kSmallKeyInset 1.0f

@interface KeyCapView : NSView<NSDraggingSource, NSPasteboardWriting, NSAccessibilityStaticText> {
	NSRect keyRect;
	NSMutableAttributedString *displayText;
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
@property (nonatomic, strong) UKStyleInfo *styleInfo;
@property (nonatomic, weak) id<UKMenuDelegate> menuDelegate;
@property (nonatomic, weak) IBOutlet id<UKKeyCapClick> clickDelegate;
@property (NS_NONATOMIC_IOSONLY, readonly) NSRect boundingRect;
@property (NS_NONATOMIC_IOSONLY, readonly) NSRect insideRect;
@property (readwrite) NSInteger tag;
@property (strong) NSTextView *textView;
@property (nonatomic) BOOL showCodePoints;

- (void)flipInRect:(NSRect)boundingRect;
- (void)getInnerColour:(NSColor **)innerColour
		   outerColour:(NSColor **)outerColour
			textColour:(NSColor **)textColour
		  gradientType:(NSUInteger *)gradientType;
- (void)setScale:(CGFloat)scaleValue;
- (void)offsetFrameX:(CGFloat)xOffset Y:(CGFloat)yOffset;
- (void)finishInit;
- (void)styleDidUpdate;
- (void)setupTextView:(NSRect)textRect;
- (void)assignStyle;

@end

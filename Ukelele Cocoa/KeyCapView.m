//
//  KeyCapView.m
//  Ukelele 3
//
//  Created by John Brownie on 12/01/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "KeyCapView.h"
#import "UKKeyboardController.h"
#import "UkeleleConstants.h"
#import "XMLCocoaUtilities.h"
#import "LayoutInfo.h"
#import "UkeleleConstantStrings.h"

const CGFloat kKeyInset = 2.0f;
const CGFloat kSmallKeyInset = 1.0f;
const unichar kFirstASCIIPrintingChar = 0x20;
const unichar kLastASCIIPrintingChar = 0x7e;
const unichar kLastControlChar = 0x9f;
static CGAffineTransform kTextTransform = {
	1.0, 0.0, 0.0, 1.0, 0.0, 0.0
};

@implementation KeyCapView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        keyRect = frame;
		_outputString = @"";
		_colourTheme = [[ColourTheme defaultColourTheme] copy];
		_largeCTStyle = nil;
		_smallCTStyle = nil;
		_largeCTFont = nil;
		_smallCTFont = nil;
		textFrame = nil;
		displayText = [[NSMutableAttributedString alloc] initWithString:@""];
		NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds]
																	options:NSTrackingMouseEnteredAndExited |
										NSTrackingActiveInActiveApp | NSTrackingInVisibleRect
																	  owner:self
																   userInfo:nil];
		[self addTrackingArea:trackingArea];
        _largeAttributes = nil;
        _smallAttributes = nil;
        textStorage = nil;
		_currentTextColour = [NSColor whiteColor];
    }
    return self;
}

- (void)clearFrame
{
	if (textFrame) {
		CFRelease(textFrame);
		textFrame = nil;
	}
    if (textStorage) {
        textStorage = nil;
    }
}

- (void) dealloc
{
	if (_smallCTFont) {
		CFRelease(_smallCTFont);
	}
	if (_largeCTFont) {
		CFRelease(_largeCTFont);
	}
	[self clearFrame];
}

- (BOOL)isFlipped
{
	return NO;
}

- (void)getInnerColour:(NSColor **)innerColour
		   outerColour:(NSColor **)outerColour
			textColour:(NSColor **)textColour
		  gradientType:(NSUInteger *)gradientType {
	if (self.deadKey) {
		if (self.selected) {
			if (self.down) {
				*innerColour = [self.colourTheme selectedDeadDownInnerColour];
				*outerColour = [self.colourTheme selectedDeadDownOuterColour];
				*textColour = [self.colourTheme selectedDeadDownTextColour];
			}
			else {
				*innerColour = [self.colourTheme selectedDeadUpInnerColour];
				*outerColour = [self.colourTheme selectedDeadUpOuterColour];
				*textColour = [self.colourTheme selectedDeadUpTextColour];
			}
			*gradientType = [self.colourTheme selectedDeadGradientType];
		}
		else {
			if (self.down) {
				*innerColour = [self.colourTheme deadKeyDownInnerColour];
				*outerColour = [self.colourTheme deadKeyDownOuterColour];
				*textColour = [self.colourTheme deadKeyDownTextColour];
			}
			else {
				*innerColour = [self.colourTheme deadKeyUpInnerColour];
				*outerColour = [self.colourTheme deadKeyUpOuterColour];
				*textColour = [self.colourTheme deadKeyUpTextColour];
			}
			*gradientType = [self.colourTheme deadKeyGradientType];
		}
	}
	else {
		if (self.selected) {
			if (self.down) {
				*innerColour = [self.colourTheme selectedDownInnerColour];
				*outerColour = [self.colourTheme selectedDownOuterColour];
				*textColour = [self.colourTheme selectedDownTextColour];
			}
			else {
				*innerColour = [self.colourTheme selectedUpInnerColour];
				*outerColour = [self.colourTheme selectedUpOuterColour];
				*textColour = [self.colourTheme selectedUpTextColour];
			}
			*gradientType = [self.colourTheme selectedGradientType];
		}
		else {
			if (self.down) {
				*innerColour = [self.colourTheme normalDownInnerColour];
				*outerColour = [self.colourTheme normalDownOuterColour];
				*textColour = [self.colourTheme normalDownTextColour];
			}
			else {
				*innerColour = [self.colourTheme normalUpInnerColour];
				*outerColour = [self.colourTheme normalUpOuterColour];
				*textColour = [self.colourTheme normalUpTextColour];
			}
			*gradientType = [self.colourTheme normalGradientType];
		}
	}
}

- (void)setUpFrame
{
	[self clearFrame];
    if (!_largeAttributes) {
        // Do it with Core Text
        CFMutableDictionaryRef textAttributes = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                                          &kCFTypeDictionaryKeyCallBacks,
                                                                          &kCFTypeDictionaryValueCallBacks);
        CFDictionaryAddValue(textAttributes, kCTForegroundColorAttributeName, (__bridge const void *)(_currentTextColour));
        CFDictionaryAddValue(textAttributes, kCTFontAttributeName, _small ? _smallCTFont : _largeCTFont);
        if (_largeCTStyle && _smallCTStyle) {
            CFDictionaryAddValue(textAttributes, kCTParagraphStyleAttributeName, _small ? _smallCTStyle : _largeCTStyle);
        }
        NSMutableAttributedString *displayTextString = [displayText mutableCopy];
        [displayTextString setAttributes:(__bridge NSMutableDictionary *)textAttributes
                                   range:NSMakeRange(0, [displayTextString length])];
        CTFramesetterRef theFramesetter =
		CTFramesetterCreateWithAttributedString((__bridge CFMutableAttributedStringRef)displayTextString);
        NSRect textRect = NSInsetRect([self insideRect], kKeyInset, _small ? kSmallKeyInset : kKeyInset);
        textRect.size.height -= CTFontGetLeading(_small ? _smallCTFont : _largeCTFont);
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, NSRectToCGRect(textRect));
        textFrame = CTFramesetterCreateFrame(theFramesetter, CFRangeMake(0, 0), path, NULL);
        CFRelease(theFramesetter);
        if (!_small) {
			// See if the text fits
            CFRange stringRange = CTFrameGetStringRange(textFrame);
            CFRange visibleRange = CTFrameGetVisibleStringRange(textFrame);
            if (visibleRange.length < stringRange.length) {
				// Did not fit, so we make it small
                CFDictionaryAddValue(textAttributes, kCTFontAttributeName, _smallCTFont);
                CFDictionaryAddValue(textAttributes, kCTParagraphStyleAttributeName, _smallCTStyle);
                displayTextString = [displayText mutableCopy];
                [displayTextString setAttributes:(__bridge NSMutableDictionary *)textAttributes
                                           range:NSMakeRange(0, [displayTextString length])];
                theFramesetter = CTFramesetterCreateWithAttributedString((__bridge CFMutableAttributedStringRef)displayTextString);
                CFRelease(textFrame);
                textFrame = CTFramesetterCreateFrame(theFramesetter, CFRangeMake(0, 0), path, NULL);
                CFRelease(theFramesetter);
            }
        }
        CFRelease(textAttributes);
        CGPathRelease(path);
    }
    else {
        // Do it with Cocoa Text
        NSRect textRect = NSInsetRect([self insideRect], kKeyInset, _small ? kSmallKeyInset : kKeyInset);
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:textRect.size];
        [_smallAttributes setValue:_currentTextColour forKey:NSForegroundColorAttributeName];
        [_largeAttributes setValue:_currentTextColour forKey:NSForegroundColorAttributeName];
        textStorage = [[NSTextStorage alloc] initWithAttributedString:displayText];
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        [layoutManager addTextContainer: textContainer];
        [textStorage addLayoutManager: layoutManager];
        if (_small) {
            [textStorage setAttributes:_smallAttributes range:NSMakeRange(0, [textStorage length])];
        }
        else {
            [textStorage setAttributes:_largeAttributes range:NSMakeRange(0, [textStorage length])];
            NSRect neededBox = NSZeroRect;
            @try {
                NSArray *layoutManagerList = [textStorage layoutManagers];
                NSLayoutManager *layoutManager = layoutManagerList[0];
                NSArray *textContainerList = [layoutManager textContainers];
                NSTextContainer *textContainer = textContainerList[0];
                NSSize textContainerSize = [textContainer containerSize];
                [textContainer setContainerSize:NSMakeSize(FLT_MAX, textContainerSize.height)];
                [layoutManager glyphRangeForTextContainer:textContainer];
                neededBox = [layoutManager usedRectForTextContainer:textContainer];
            }
            @catch (NSException *e) {
                // Do nothing?
            }
            if (neededBox.size.width > textRect.size.width) {
                [textStorage setAttributes:_smallAttributes range:NSMakeRange(0, [textStorage length])];
            }
        }
   }
}

- (void)createDisplayText
{
	if ([_outputString length] == 0) {
		displayText = [[NSMutableAttributedString alloc] initWithString:@""];
	}
	else {
		unichar firstChar = [_outputString characterAtIndex:0];
		BOOL isLowASCII = firstChar >= kFirstASCIIPrintingChar && firstChar <= kLastASCIIPrintingChar;
		BOOL isAboveControlRange = firstChar > kLastControlChar;
		BOOL isControlCharacter = [_outputString length] == 1 && !isLowASCII && !isAboveControlRange;
		if (isControlCharacter) {
				// A control character - see if we have a symbol for it
			displayText = [LayoutInfo getKeySymbolString:(unsigned int)_keyCode withString:_outputString];
			if ([displayText length] == 0) {
				displayText = [[NSMutableAttributedString alloc] initWithString:_outputString];
			}
		}
		else if ([_outputString length] == 1 && [XMLCocoaUtilities isCombiningDiacritic:firstChar]) {
				// Combining diacritic by itself
			unichar combinedString[2];
			NSInteger diacriticIndex = [[NSUserDefaults standardUserDefaults] integerForKey:UKDiacriticDisplayCharacter];
			unichar diacriticChar = kSpaceUnicode;
			switch (diacriticIndex) {
				case UKDiacriticSquare:
					diacriticChar = kWhiteSquareUnicode;
					break;
					
				case UKDiacriticDottedSquare:
					diacriticChar = kDottedSquareUnicode;
					break;
					
				case UKDiacriticCircle:
					diacriticChar = kWhiteCircleUnicode;
					break;
					
				case UKDiacriticDottedCircle:
					diacriticChar = kDottedCircleUnicode;
			}
			combinedString[0] = diacriticChar;
			combinedString[1] = firstChar;
			displayText = [[NSMutableAttributedString alloc]
							initWithString:[NSString stringWithCharacters:combinedString length:2]];
		}
		else {
			displayText = [[NSMutableAttributedString alloc] initWithString:_outputString];
		}
	}
	[self clearFrame];
}

- (void)flipInRect:(NSRect)boundingRect
{
	NSRect frameRect = [self frame];
	frameRect.origin.y = boundingRect.size.height - frameRect.origin.y - frameRect.size.height;
	[self setFrame:frameRect];
}

- (void)setScale:(CGFloat)scaleValue
{
	NSRect newFrame = NSRectFromCGRect(CGRectMake(keyRect.origin.x * scaleValue, keyRect.origin.y * scaleValue,
												  keyRect.size.width * scaleValue, keyRect.size.height * scaleValue));
	[self setFrame:newFrame];
}

- (void)changeScaleBy:(CGFloat)scaleMultiplier
{
	NSRect oldFrame = [self frame];
	NSRect newFrame = NSRectFromCGRect(CGRectMake(oldFrame.origin.x * scaleMultiplier, oldFrame.origin.y * scaleMultiplier,
												  oldFrame.size.width * scaleMultiplier, oldFrame.size.height * scaleMultiplier));
	[self setFrame:newFrame];
}

- (void)offsetFrameX:(CGFloat)xOffset Y:(CGFloat)yOffset
{
	[self setFrame:NSOffsetRect([self frame], xOffset, yOffset)];
}

- (void)finishInit
{
	keyRect = [self frame];
}

#pragma mark Drawing

- (void)drawText:(NSRect)dirtyRect
{
	if ([displayText length] == 0) {
		return;
	}
    if (!_largeAttributes) {
			// Use CoreText
        if (!textFrame) {
            [self setUpFrame];
        }
        CGContextRef myContext = [[NSGraphicsContext currentContext] graphicsPort];
        CTFrameDraw(textFrame, myContext);
    }
    else {
			// Use Cocoa text
        if (!textStorage) {
            [self setUpFrame];
        }
        NSRect textRect = NSInsetRect([self insideRect], kKeyInset, _small ? kSmallKeyInset : kKeyInset);
        NSPoint drawPoint = textRect.origin;
		NSArray *layoutManagerList = [textStorage layoutManagers];
		NSLayoutManager *layoutManager = layoutManagerList[0];
		NSArray *textContainerList = [layoutManager textContainers];
		NSTextContainer *textContainer = textContainerList[0];
        NSSize textContainerSize = [textContainer containerSize];
        [textContainer setContainerSize:NSMakeSize(FLT_MAX, textContainerSize.height)];
        [layoutManager glyphRangeForTextContainer:textContainer];
        NSRect neededBox = [layoutManager usedRectForTextContainer:textContainer];
        drawPoint.x += textRect.size.width / 2.0 - neededBox.size.width / 2.0;
		drawPoint.y -= 7;	// Just a value that seems to work!
		NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
		[layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:drawPoint];
    }
}

- (void)drawRect:(NSRect)dirtyRect {
	[NSGraphicsContext saveGraphicsState];
		// Get drawing parameters
	NSRect boundingRect = [self bounds];
	NSColor *innerColour;
	NSColor *outerColour;
	NSColor *textColour;
	NSUInteger gradientType;
	[self getInnerColour:&innerColour outerColour:&outerColour textColour:&textColour gradientType:&gradientType];
	[self setCurrentTextColour:textColour];
		// Draw the background with the appropriate gradient type
	NSGradient *colourGradient = nil;
	switch (gradientType) {
		case gradientTypeNone: {
			[innerColour setFill];
			[NSBezierPath fillRect:boundingRect];
			[NSBezierPath setDefaultLineWidth:2.0];
			[outerColour setStroke];
			[NSBezierPath strokeRect:NSInsetRect(boundingRect, 1.0, 1.0)];
			break;
		}
			
		case gradientTypeLinear:
			colourGradient = [[NSGradient alloc] initWithStartingColor:innerColour endingColor:outerColour];
			[colourGradient drawInRect:boundingRect angle:90];
			break;
			
		case gradientTypeRadial:
			colourGradient = [[NSGradient alloc] initWithStartingColor:innerColour endingColor:outerColour];
			[colourGradient drawInRect:boundingRect relativeCenterPosition:NSZeroPoint];
			break;
			
		default:
			break;
	}
		// Draw drag highlight if necessary
	if (_dragHighlight) {
		NSColor *dragColour = [NSColor colorWithCalibratedWhite:1.0 alpha:0.375];
		[dragColour setFill];
		[NSBezierPath fillRect:boundingRect];
	}
		// Ensure that the text matrix is correct
	CGContextRef myContext = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSetTextMatrix(myContext, kTextTransform);
	[self drawText:dirtyRect];
	[NSGraphicsContext restoreGraphicsState];
}

#pragma mark Accessors

- (void)setDown:(BOOL)value
{
	_down = value;
	[self setNeedsDisplay:YES];
}

- (NSRect)boundingRect
{
	return [self frame];
}

- (NSRect)insideRect
{
	return [self bounds];
}

- (void)setOutputString:(NSString *)newString
{
	NSString *convertedString = [XMLCocoaUtilities convertEncodedString:newString];
	_outputString = convertedString;
	[self createDisplayText];
	[self setNeedsDisplay:YES];
}

- (void)setColourTheme:(ColourTheme *)newColourTheme {
	if (_colourTheme != newColourTheme) {
		_colourTheme = newColourTheme;
		[self clearFrame];
		[self setNeedsDisplay:YES];
	}
}

- (void)setLargeAttributes:(NSDictionary *)newAttributes
{
    _largeAttributes = newAttributes;
    [self clearFrame];
    [self setNeedsDisplay:YES];
}

- (void)setSmallAttributes:(NSDictionary *)newAttributes
{
    _smallAttributes = newAttributes;
    [self clearFrame];
    [self setNeedsDisplay:YES];
}

- (void)setLargeCTStyle:(CTParagraphStyleRef)newStyle
{
    _largeCTStyle = newStyle;
    [self clearFrame];
    [self setNeedsDisplay:YES];
}

- (void)setSmallCTStyle:(CTParagraphStyleRef)newStyle
{
    _smallCTStyle = newStyle;
    [self clearFrame];
    [self setNeedsDisplay:YES];
}

- (void)setLargeCTFont:(CTFontRef)newFont
{
	if (_largeCTFont != newFont) {
		CFRetain(newFont);
		if (_largeCTFont) {
			CFRelease(_largeCTFont);
		}
		_largeCTFont = newFont;
		[self clearFrame];
		[self setNeedsDisplay:YES];
	}
}

- (void)setSmallCTFont:(CTFontRef)newFont
{
	if (_smallCTFont != newFont) {
		CFRetain(newFont);
		if (_smallCTFont) {
			CFRelease(_smallCTFont);
		}
		_smallCTFont = newFont;
		[self clearFrame];
		[self setNeedsDisplay:YES];
	}
}

- (void)setCurrentTextColour:(NSColor *)newTextColour {
	if (_currentTextColour != newTextColour) {
		_currentTextColour = newTextColour;
		[self clearFrame];
		[self setNeedsDisplay:YES];
	}
}

#pragma mark Events

- (void)mouseEntered:(NSEvent *)theEvent
{
	UKKeyboardController *theDocumentWindow = [[self window] windowController];
	[theDocumentWindow messageMouseEntered:(int)_keyCode];
}

- (void)mouseExited:(NSEvent *)theEvent
{
	UKKeyboardController *theDocumentWindow = [[self window] windowController];
	[theDocumentWindow messageMouseExited:(int)_keyCode];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if (self.clickDelegate) {
		[self.clickDelegate handleKeyCapClick:self clickCount:[theEvent clickCount]];
	}
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
	_dragHighlight = YES;
	[self setNeedsDisplay:YES];
	return NSDragOperationGeneric;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
	_dragHighlight = NO;
	[self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
	_dragHighlight = NO;
	[self setNeedsDisplay:YES];
	NSPasteboard *pboard = [sender draggingPasteboard];
	NSArray *classArray = @[[NSString class]];
	NSDictionary *dictionary = @{};
	NSArray *draggedItems = [pboard readObjectsForClasses:classArray options:dictionary];
	if (draggedItems != nil && [draggedItems count] > 0) {
			// Got the text
		UKKeyboardController *theDocumentWindow = [[self window] windowController];
		[theDocumentWindow messageDragText:draggedItems[0] toKey:(int)_keyCode];
		return YES;
	}
	return NO;
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
	NSDictionary *dataDictionary = @{kKeyKeyCode: @(self.keyCode)};
	return [self.menuDelegate contextualMenuForData:dataDictionary];
}

#pragma mark Contextual menus

- (IBAction)cutKey:(id)sender {
	[[self nextResponder] tryToPerform:@selector(cutKey:) with:self];
}

- (IBAction)copyKey:(id)sender {
	[[self nextResponder] tryToPerform:@selector(copyKey:) with:self];
}

- (IBAction)pasteKey:(id)sender {
	[[self nextResponder] tryToPerform:@selector(pasteKey:) with:self];
}

- (IBAction)unlinkKey:(id)sender {
	[[self nextResponder] tryToPerform:@selector(unlinkKey:) with:self];
}

- (IBAction)makeOutput:(id)sender {
	[[self nextResponder] tryToPerform:@selector(makeOutput:) with:self];
}

- (IBAction)makeDeadKey:(id)sender {
	[[self nextResponder] tryToPerform:@selector(makeDeadKey:) with:self];
}

- (IBAction)changeNextState:(id)sender {
	[[self nextResponder] tryToPerform:@selector(changeNextState:) with:self];
}

- (IBAction)changeTerminator:(id)sender {
	[[self nextResponder] tryToPerform:@selector(changeTerminator:) with:self];
}

- (IBAction)changeOutput:(id)sender {
	[[self nextResponder] tryToPerform:@selector(changeOutput:) with:self];
}

- (IBAction)attachComment:(id)sender {
	[[self nextResponder] tryToPerform:@selector(attachComment:) with:self];
}

@end

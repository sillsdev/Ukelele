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
const unichar kDiscretionaryHyphen = 0xad;
const unichar kFirstSpaceChar = 0x2000;
const unichar kLastSpaceChar = 0x200f;
const unichar kFirstSeparatorChar = 0x2028;
const unichar kLastSeparatorChar = 0x202f;
const unichar kZeroWidthNonBreakSpace = 0xfeff;
static CGAffineTransform kTextTransform = {
	1.0, 0.0, 0.0, 1.0, 0.0, 0.0
};

@implementation KeyCapView

@synthesize tag;

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        keyRect = frame;
		_outputString = @"";
		_colourTheme = [[ColourTheme defaultColourTheme] copy];
		_styleInfo = nil;
		textFrame = nil;
		displayText = [[NSMutableAttributedString alloc] initWithString:@""];
		NSTrackingArea *trackingArea =
			[[NSTrackingArea alloc] initWithRect:[self bounds]
										 options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect
										   owner:self
										userInfo:nil];
		[self addTrackingArea:trackingArea];
        textStorage = nil;
		_textView = nil;
		_currentTextColour = [NSColor whiteColor];
		mouseIsInside = NO;
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
	[self clearFrame];
}

- (BOOL)isFlipped {
	return NO;
}

- (BOOL)isOpaque {
	return YES;
}

- (NSView *)hitTest:(NSPoint)aPoint {
	if (NSPointInRect(aPoint, [self frame])) {
		return self;
	}
	return [super hitTest:aPoint];
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
				*gradientType = [self.colourTheme selectedDeadDownGradientType];
			}
			else {
				*innerColour = [self.colourTheme selectedDeadUpInnerColour];
				*outerColour = [self.colourTheme selectedDeadUpOuterColour];
				*textColour = [self.colourTheme selectedDeadUpTextColour];
				*gradientType = [self.colourTheme selectedDeadGradientType];
			}
		}
		else {
			if (self.down) {
				*innerColour = [self.colourTheme deadKeyDownInnerColour];
				*outerColour = [self.colourTheme deadKeyDownOuterColour];
				*textColour = [self.colourTheme deadKeyDownTextColour];
				*gradientType = [self.colourTheme deadKeyDownGradientType];
			}
			else {
				*innerColour = [self.colourTheme deadKeyUpInnerColour];
				*outerColour = [self.colourTheme deadKeyUpOuterColour];
				*textColour = [self.colourTheme deadKeyUpTextColour];
				*gradientType = [self.colourTheme deadKeyGradientType];
			}
		}
	}
	else {
		if (self.selected) {
			if (self.down) {
				*innerColour = [self.colourTheme selectedDownInnerColour];
				*outerColour = [self.colourTheme selectedDownOuterColour];
				*textColour = [self.colourTheme selectedDownTextColour];
				*gradientType = [self.colourTheme selectedDownGradientType];
			}
			else {
				*innerColour = [self.colourTheme selectedUpInnerColour];
				*outerColour = [self.colourTheme selectedUpOuterColour];
				*textColour = [self.colourTheme selectedUpTextColour];
				*gradientType = [self.colourTheme selectedGradientType];
			}
		}
		else {
			if (self.down) {
				*innerColour = [self.colourTheme normalDownInnerColour];
				*outerColour = [self.colourTheme normalDownOuterColour];
				*textColour = [self.colourTheme normalDownTextColour];
				*gradientType = [self.colourTheme normalDownGradientType];
			}
			else {
				*innerColour = [self.colourTheme normalUpInnerColour];
				*outerColour = [self.colourTheme normalUpOuterColour];
				*textColour = [self.colourTheme normalUpTextColour];
				*gradientType = [self.colourTheme normalGradientType];
			}
		}
	}
}

- (void)setUpFrame
{
	[self clearFrame];
    if (self.styleInfo.largeAttributes) {
        // Do it with Cocoa Text
        NSRect textRect = NSInsetRect([self insideRect], kKeyInset, self.small ? kSmallKeyInset : kKeyInset);
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:textRect.size];
        [self.styleInfo.smallAttributes setValue:self.currentTextColour forKey:NSForegroundColorAttributeName];
        [self.styleInfo.largeAttributes setValue:self.currentTextColour forKey:NSForegroundColorAttributeName];
        textStorage = [[NSTextStorage alloc] initWithAttributedString:displayText];
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        [layoutManager addTextContainer: textContainer];
        [textStorage addLayoutManager: layoutManager];
        if (self.small) {
            [textStorage setAttributes:self.styleInfo.smallAttributes range:NSMakeRange(0, [textStorage length])];
        }
        else {
            [textStorage setAttributes:self.styleInfo.largeAttributes range:NSMakeRange(0, [textStorage length])];
            NSRect neededBox = NSZeroRect;
            @try {
                NSArray *layoutManagerList = [textStorage layoutManagers];
                layoutManager = layoutManagerList[0];
                NSArray *textContainerList = [layoutManager textContainers];
                textContainer = textContainerList[0];
                NSSize textContainerSize = [textContainer containerSize];
                [textContainer setContainerSize:NSMakeSize(FLT_MAX, textContainerSize.height)];
                [layoutManager glyphRangeForTextContainer:textContainer];
                neededBox = [layoutManager usedRectForTextContainer:textContainer];
            }
            @catch (NSException *e) {
                // Do nothing?
            }
            if (neededBox.size.width > textRect.size.width) {
                [textStorage setAttributes:self.styleInfo.smallAttributes
									 range:NSMakeRange(0, [textStorage length])];
            }
        }
    }
    else {
        // Do it with Core Text
        CFMutableDictionaryRef textAttributes =
			CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
									  &kCFTypeDictionaryKeyCallBacks,
									  &kCFTypeDictionaryValueCallBacks);
        CFDictionaryAddValue(textAttributes, kCTForegroundColorAttributeName,
							 (__bridge const void *)(self.currentTextColour));
        CFDictionaryAddValue(textAttributes, kCTFontAttributeName, self.small ? self.styleInfo.smallFont : self.styleInfo.largeFont);
        if (self.styleInfo.largeParagraphStyle && self.styleInfo.smallParagraphStyle) {
            CFDictionaryAddValue(textAttributes, kCTParagraphStyleAttributeName, self.small ? self.styleInfo.smallParagraphStyle : self.styleInfo.largeParagraphStyle);
        }
        NSMutableAttributedString *displayTextString = [displayText mutableCopy];
        [displayTextString setAttributes:(__bridge NSMutableDictionary *)textAttributes
                                   range:NSMakeRange(0, [displayTextString length])];
        CTFramesetterRef theFramesetter =
		CTFramesetterCreateWithAttributedString((__bridge CFMutableAttributedStringRef)displayTextString);
        NSRect textRect = NSInsetRect([self insideRect], kKeyInset, self.small ? kSmallKeyInset : kKeyInset);
        textRect.size.height -= CTFontGetLeading(self.small ? self.styleInfo.smallFont : self.styleInfo.largeFont);
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, NSRectToCGRect(textRect));
        textFrame = CTFramesetterCreateFrame(theFramesetter, CFRangeMake(0, 0), path, NULL);
        CFRelease(theFramesetter);
        if (!self.small) {
			// See if the text fits
            CFRange stringRange = CTFrameGetStringRange(textFrame);
            CFRange visibleRange = CTFrameGetVisibleStringRange(textFrame);
            if (visibleRange.length < stringRange.length) {
				// Did not fit, so we make it small
                CFDictionaryAddValue(textAttributes, kCTFontAttributeName, self.styleInfo.smallFont);
                CFDictionaryAddValue(textAttributes, kCTParagraphStyleAttributeName, self.styleInfo.smallParagraphStyle);
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
}

- (void)createDisplayText
{
	NSUInteger stringLength = [self.outputString length];
	if (stringLength == 0) {
		displayText = [[NSMutableAttributedString alloc] initWithString:@""];
	}
	else if (stringLength == 1) {
		unichar firstChar = [self.outputString characterAtIndex:0];
		BOOL isLowASCII = firstChar >= kFirstASCIIPrintingChar &&
						  firstChar <= kLastASCIIPrintingChar;
		BOOL isAboveControlRange = firstChar > kLastControlChar;
		BOOL isInvisibleCharacter = firstChar == kDiscretionaryHyphen ||
						firstChar == kZeroWidthNonBreakSpace ||
						(firstChar >= kFirstSpaceChar && firstChar <= kLastSpaceChar) ||
						(firstChar >= kFirstSeparatorChar && firstChar <= kLastSeparatorChar);
		BOOL isControlCharacter = [self.outputString length] == 1 &&
								  ((!isLowASCII && !isAboveControlRange) || isInvisibleCharacter);
		if (isControlCharacter) {
				// A control character - see if we have a symbol for it
			displayText = [LayoutInfo getKeySymbolString:(unsigned int)self.keyCode
											  withString:self.outputString];
			if ([displayText length] == 0) {
				displayText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"U+%X", firstChar]];
			}
		}
		else if (stringLength == 1 && [XMLCocoaUtilities isCombiningDiacritic:firstChar]) {
				// Combining diacritic by itself
			unichar combinedString[2];
			unichar diacriticChar = (unichar)[[NSUserDefaults standardUserDefaults] integerForKey:UKDiacriticDisplayCharacter];
			combinedString[0] = diacriticChar;
			combinedString[1] = firstChar;
			displayText = [[NSMutableAttributedString alloc]
							initWithString:[NSString stringWithCharacters:combinedString length:2]];
		}
		else {
			displayText = [[NSMutableAttributedString alloc] initWithString:self.outputString];
		}
	}
	else {
			// More than a single character
		displayText = [[NSMutableAttributedString alloc] init];
		for (NSUInteger i = 0; i < stringLength; i++) {
			unichar theChar = [self.outputString characterAtIndex:i];
			BOOL isLowASCII = theChar >= kFirstASCIIPrintingChar &&
							  theChar <= kLastASCIIPrintingChar;
			BOOL isAboveControlRange = theChar > kLastControlChar;
			BOOL isControlCharacter = !isLowASCII && !isAboveControlRange;
			NSAttributedString *charString;
			NSString *formatString;
			if (isControlCharacter) {
					// Create a hex representation
				formatString = @"U+%X";
			}
			else {
				formatString = @"%C";
			}
			charString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:formatString, theChar]];
			[displayText appendAttributedString:charString];
		}
	}
	NSDictionary *myStyle = self.small ? self.styleInfo.smallAttributes : self.styleInfo.largeAttributes;
	[displayText setAttributes:myStyle range:NSMakeRange(0, [displayText length])];
	[self.textView.textStorage setAttributedString:displayText];
//	[self clearFrame];
}

- (void)flipInRect:(NSRect)boundingRect
{
	NSRect frameRect = [self frame];
	frameRect.origin.y = boundingRect.size.height - frameRect.origin.y - frameRect.size.height;
	[self setFrame:frameRect];
}

- (void)setScale:(CGFloat)scaleValue
{
	NSRect newFrame = NSMakeRect(keyRect.origin.x * scaleValue, keyRect.origin.y * scaleValue,
								 keyRect.size.width * scaleValue, keyRect.size.height * scaleValue);
	[self setFrame:newFrame];
	NSRect oldViewFrame = [self.textView frame];
	NSRect newViewFrame = NSMakeRect(oldViewFrame.origin.x * scaleValue, oldViewFrame.origin.y * scaleValue, oldViewFrame.size.width * scaleValue, oldViewFrame.size.height * scaleValue);
	[self.textView setFrame:newViewFrame];
}

- (void)changeScaleBy:(CGFloat)scaleMultiplier
{
	NSRect oldFrame = [self frame];
	NSRect newFrame = NSMakeRect(oldFrame.origin.x * scaleMultiplier,
								 oldFrame.origin.y * scaleMultiplier,
								 oldFrame.size.width * scaleMultiplier,
								 oldFrame.size.height * scaleMultiplier);
	[self setFrame:newFrame];
	NSRect oldViewFrame = [self.textView frame];
	NSRect newViewFrame = NSMakeRect(oldViewFrame.origin.x * scaleMultiplier, oldViewFrame.origin.y * scaleMultiplier, oldViewFrame.size.width * scaleMultiplier, oldViewFrame.size.height * scaleMultiplier);
	[self.textView setFrame:newViewFrame];
}

- (void)offsetFrameX:(CGFloat)xOffset Y:(CGFloat)yOffset
{
	[self setFrame:NSOffsetRect([self frame], xOffset, yOffset)];
}

- (void)finishInit
{
	keyRect = [self frame];
	NSRect textRect = NSInsetRect([self bounds], kKeyInset, self.small ? kSmallKeyInset : kKeyInset);
	[self setupTextView:textRect];
}

- (void)setupTextView:(NSRect)textRect {
	self.textView = [[NSTextView alloc] initWithFrame:textRect];
	[self.textView setDrawsBackground:NO];
	[self.textView setEditable:NO];
	[self.textView setSelectable:NO];
//	NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
//	[paraStyle setAlignment:NSCenterTextAlignment];
//	[self.textView setDefaultParagraphStyle:paraStyle];
	[self.textView setVerticallyResizable:NO];
	[self.textView setHorizontallyResizable:NO];
	[self addSubview:self.textView];
	[self createDisplayText];
}

#pragma mark Drawing

- (void)drawText:(NSRect)dirtyRect
{
#pragma unused(dirtyRect)
	if ([displayText length] == 0) {
		return;
	}
    if (self.styleInfo.largeAttributes) {
			// Use Cocoa text
        if (!textStorage) {
            [self setUpFrame];
        }
        NSRect textRect = NSInsetRect([self insideRect], kKeyInset, self.small ? kSmallKeyInset : kKeyInset);
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
		CGFloat yOffset = self.small ? 0.4 : 0.3;	// Just a value that seems to work!
		drawPoint.y -= neededBox.size.height * yOffset;
		NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
		[layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:drawPoint];
    }
    else {
			// Use CoreText
        if (!textFrame) {
            [self setUpFrame];
        }
        CGContextRef myContext = [[NSGraphicsContext currentContext] graphicsPort];
        CTFrameDraw(textFrame, myContext);
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
	if (self.dragHighlight) {
		NSColor *dragColour = [NSColor colorWithCalibratedWhite:1.0 alpha:0.375];
		[dragColour setFill];
		[NSBezierPath fillRect:boundingRect];
	}
		// Ensure that the text matrix is correct
	CGContextRef myContext = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSetTextMatrix(myContext, kTextTransform);
//	[self drawText:dirtyRect];
	if (self.fallback) {
			// Paint over the whole rect with a transparent grey
		NSColor *greyColour = [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:fallbackAlpha];
		[greyColour setFill];
		[NSBezierPath fillRect:dirtyRect];
	}
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
	if (mouseIsInside) {
			// Let the system know that the string has changed
		[self signalMouseEntered];
	}
}

- (void)setColourTheme:(ColourTheme *)newColourTheme {
	if (_colourTheme != newColourTheme) {
		_colourTheme = newColourTheme;
		[self clearFrame];
		[self setNeedsDisplay:YES];
	}
}

- (void)setStyleInfo:(UKStyleInfo *)styleInfo {
	if (styleInfo != _styleInfo) {
		_styleInfo = styleInfo;
		[self clearFrame];
		[self setNeedsLayout:YES];
	}
}

- (void)setCurrentTextColour:(NSColor *)newTextColour {
	if (_currentTextColour != newTextColour) {
		_currentTextColour = newTextColour;
//		[self clearFrame];
//		[self setNeedsDisplay:YES];
	}
}

#pragma mark Events

- (void)mouseEntered:(NSEvent *)theEvent {
#pragma unused(theEvent)
	mouseIsInside = YES;
	[self signalMouseEntered];
}

- (void)signalMouseEntered {
	UKKeyboardController *theDocumentWindow = [[self window] windowController];
	[theDocumentWindow messageMouseEntered:(int)self.keyCode];
}

- (void)mouseExited:(NSEvent *)theEvent {
#pragma unused(theEvent)
	mouseIsInside = NO;
	[self signalMouseExited];
}

- (void)signalMouseExited {
	UKKeyboardController *theDocumentWindow = [[self window] windowController];
	[theDocumentWindow messageMouseExited:(int)self.keyCode];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if (self.clickDelegate) {
		[self.clickDelegate handleKeyCapClick:self clickCount:[theEvent clickCount]];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent {
		// Only drag text for ordinary keys
	if (self.keyType == kOrdinaryKeyType) {
		NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:self];
		NSImage *dragImage = [[NSImage alloc] initWithSize:keyRect.size];
		[dragImage lockFocus];
		[self drawText:keyRect];
		[dragImage unlockFocus];
		[dragItem setDraggingFrame:NSMakeRect(0.0, 0.0, keyRect.size.width, keyRect.size.height) contents:dragImage];
		NSArray *dragItems = [NSArray arrayWithObject:dragItem];
		[self beginDraggingSessionWithItems:dragItems event:theEvent source:self];
	}
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
#pragma unused(sender)
	if (self.keyType == kOrdinaryKeyType) {
		self.dragHighlight = YES;
		[self setNeedsDisplay:YES];
		return NSDragOperationGeneric;
	}
	return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
#pragma unused(sender)
	self.dragHighlight = NO;
	[self setNeedsDisplay:YES];
}

- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender {
#pragma unused(sender)
	return self.keyType == kOrdinaryKeyType;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
	NSArray *classArray = @[[NSString class]];
	NSDictionary *dictionary = @{};
	NSArray *draggedItems = [pboard readObjectsForClasses:classArray options:dictionary];
	self.dragHighlight = NO;
	if (draggedItems != nil && [draggedItems count] > 0) {
			// Got the text
		UKKeyboardController *theDocumentWindow = [[self window] windowController];
		[theDocumentWindow messageDragText:draggedItems[0] toKey:(int)self.keyCode];
		[self setNeedsDisplay:YES];
		return YES;
	}
	[self setNeedsDisplay:YES];
	return NO;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender {
#pragma unused(sender)
	self.dragHighlight = NO;
	[self setNeedsLayout:YES];
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
#pragma unused(event)
	NSDictionary *dataDictionary = @{kKeyKeyCode: @(self.keyCode)};
	return [self.menuDelegate contextualMenuForData:dataDictionary];
}

- (void)styleDidUpdate {
		// Notification that the style was updated
//	[self clearFrame];
	[self createDisplayText];
	[self setNeedsDisplay:YES];
}

#pragma mark Contextual menus

- (IBAction)cutKey:(id)sender {
#pragma unused(sender)
	[[self nextResponder] tryToPerform:@selector(cutKey:) with:self];
}

- (IBAction)copyKey:(id)sender {
#pragma unused(sender)
	[[self nextResponder] tryToPerform:@selector(copyKey:) with:self];
}

- (IBAction)pasteKey:(id)sender {
#pragma unused(sender)
	[[self nextResponder] tryToPerform:@selector(pasteKey:) with:self];
}

- (IBAction)unlinkKey:(id)sender {
#pragma unused(sender)
	[[self nextResponder] tryToPerform:@selector(unlinkKey:) with:self];
}

- (IBAction)makeOutput:(id)sender {
#pragma unused(sender)
	[[self nextResponder] tryToPerform:@selector(makeOutput:) with:self];
}

- (IBAction)makeDeadKey:(id)sender {
#pragma unused(sender)
	[[self nextResponder] tryToPerform:@selector(makeDeadKey:) with:self];
}

- (IBAction)changeNextState:(id)sender {
#pragma unused(sender)
	[[self nextResponder] tryToPerform:@selector(changeNextState:) with:self];
}

- (IBAction)changeTerminator:(id)sender {
#pragma unused(sender)
	[[self nextResponder] tryToPerform:@selector(changeTerminator:) with:self];
}

- (IBAction)changeOutput:(id)sender {
#pragma unused(sender)
	[[self nextResponder] tryToPerform:@selector(changeOutput:) with:self];
}

- (IBAction)attachComment:(id)sender {
#pragma unused(sender)
	[[self nextResponder] tryToPerform:@selector(attachComment:) with:self];
}

#pragma mark Drag and Drop

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
#pragma unused(session)
	switch (context) {
		case NSDraggingContextWithinApplication:
		case NSDraggingContextOutsideApplication:
			break;
			
		default:
			return NSDragOperationNone;
	}
		// Can supply a drag if we have some display text
	if ([displayText length] > 0) {
		return NSDragOperationCopy;
	}
	else {
		return NSDragOperationNone;
	}
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
#pragma unused(pasteboard)
	const NSString *utf8Type = (const NSString *)kUTTypeUTF8PlainText;
	return @[utf8Type];
}

- (id)pasteboardPropertyListForType:(NSString *)type {
	const NSString *utf8Type = (const NSString *)kUTTypeUTF8PlainText;
	if ([utf8Type isEqualToString:type]) {
		return self.outputString;
	}
	return nil;
}

@end

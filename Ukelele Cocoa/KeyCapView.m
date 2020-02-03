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
		displayText = [[NSMutableAttributedString alloc] initWithString:@""];
		NSTrackingArea *trackingArea =
			[[NSTrackingArea alloc] initWithRect:[self bounds]
										 options:NSTrackingMouseEnteredAndExited | NSTrackingActiveInActiveApp | NSTrackingInVisibleRect
										   owner:self
										userInfo:nil];
		[self addTrackingArea:trackingArea];
		_textView = nil;
		mouseIsInside = NO;
		_showCodePoints = YES;
		self.accessibilityElement = YES;
    }
    return self;
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

- (void)assignStyle
{
	NSDictionary *myStyle = self.styleInfo.largeAttributes;
	[displayText setAttributes:myStyle range:NSMakeRange(0, [displayText length])];
		// Check whether it fits into the space given the padding on either side
	NSSize frameSize = self.textView.bounds.size;
	frameSize.width -= 2 * self.textView.textContainer.lineFragmentPadding;
	NSSize textSize = [displayText size];
	if (textSize.width > frameSize.width || textSize.height > frameSize.height) {
		myStyle = self.styleInfo.smallAttributes;
		[displayText setAttributes:myStyle range:NSMakeRange(0, [displayText length])];
	}
	[self.textView.textStorage setAttributedString:displayText];
	[self setNeedsLayout:YES];
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
		if ((self.showCodePoints || self.keyType != kOrdinaryKeyType) && isControlCharacter) {
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
			if ((self.showCodePoints || self.keyType != kOrdinaryKeyType) && isControlCharacter) {
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
	[self assignStyle];
	[self setAccessibilityText];
}

- (void)setAccessibilityText {
	NSMutableString *accessibilityText = [NSMutableString string];
	if (self.selected) {
		[accessibilityText appendString:@"Selected, "];
	}
	if (self.deadKey) {
		[accessibilityText appendString:@"Dead key, "];
	}
	if (self.down) {
		[accessibilityText appendString:@"Down, "];
	}
	switch (self.keyType) {
		case kModifierKeyType:
			[accessibilityText appendString:@"Modifier: "];
			break;
			
		case kOrdinaryKeyType:
		case kSpecialKeyType:
			[accessibilityText appendString:@"Output: "];
			break;
			
		default:
			break;
	}
	[accessibilityText appendString:[displayText string]];
	self.accessibilityValueDescription = accessibilityText;
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
	NSRect baseRect = keyRect;
	baseRect.origin = NSZeroPoint;
	NSRect textRect = NSInsetRect(baseRect, kKeyInset, self.small ? kSmallKeyInset : kKeyInset);
	NSRect newViewFrame = NSMakeRect(textRect.origin.x * scaleValue, textRect.origin.y * scaleValue, textRect.size.width * scaleValue, textRect.size.height * scaleValue);
	[self.textView setFrame:newViewFrame];
	newFrame.origin = NSZeroPoint;
	NSPoint viewFrametopRight = newViewFrame.origin;
	viewFrametopRight.x += newViewFrame.size.width;
	viewFrametopRight.y += newViewFrame.size.height;
	NSAssert(NSPointInRect(viewFrametopRight, newFrame), @"View rect must be inside the frame rect");
	[self assignStyle];
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
	[self.textView setVerticallyResizable:NO];
	[self.textView setHorizontallyResizable:NO];
	[self addSubview:self.textView];
	[self createDisplayText];
}

#pragma mark Drawing

- (void)drawRect:(NSRect)dirtyRect {
	[NSGraphicsContext saveGraphicsState];
		// Get drawing parameters
	NSRect boundingRect = [self bounds];
	NSColor *innerColour;
	NSColor *outerColour;
	NSColor *textColour;
	NSUInteger gradientType;
	[self getInnerColour:&innerColour outerColour:&outerColour textColour:&textColour gradientType:&gradientType];
	[self.textView.textStorage addAttribute:NSForegroundColorAttributeName value:textColour range:NSMakeRange(0, self.textView.textStorage.length)];
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
	CGContextRef myContext = [[NSGraphicsContext currentContext] CGContext];
	CGContextSetTextMatrix(myContext, kTextTransform);
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
	[self setAccessibilityText];
	[self setNeedsDisplay:YES];
}

- (void)setSelected:(BOOL)value {
	_selected = value;
	[self setAccessibilityText];
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
		[self setNeedsDisplay:YES];
	}
}

- (void)setStyleInfo:(UKStyleInfo *)styleInfo {
	if (styleInfo != _styleInfo) {
		_styleInfo = styleInfo;
		[self setNeedsLayout:YES];
	}
}

- (void)setShowCodePoints:(BOOL)showCodePoints {
	_showCodePoints = showCodePoints;
	[self createDisplayText];
	[self setNeedsDisplay:YES];
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
	if (self.keyType == kOrdinaryKeyType && [displayText length] > 0) {
		NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:self];
		[self.textView setSelectedRange:NSMakeRange(0, [displayText length])];
		NSImage *dragImage = [self.textView dragImageForSelectionWithEvent:theEvent origin:nil];
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
	return (self.keyType == kOrdinaryKeyType) && ([self.outputString length] > 0);
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
	[self assignStyle];
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

- (IBAction)enterDeadKeyState:(id)sender {
#pragma unused(sender)
	[[self nextResponder] tryToPerform:@selector(enterDeadKeyState:) with:self];
}

- (IBAction)editKey:(id)sender {
#pragma unused(sender)
	[[self nextResponder] tryToPerform:@selector(editKey:) with:self];
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

#pragma mark Accessibility needs

- (NSRect)accessibilityFrame {
	return [self.window convertRectToScreen:[self.superview convertRect:self.frame toView:nil]];
}

- (nullable id)accessibilityParent {
	return self.superview;
}

- (nullable NSString *)accessibilityValue {
	return [displayText string];
}

- (nullable id)animationForKey:(nonnull NSAnimatablePropertyKey)key {
	return [super animationForKey:key];
}

- (nonnull instancetype)animator {
	return [super animator];
}

+ (nullable id)defaultAnimationForKey:(nonnull NSAnimatablePropertyKey)key {
	return [super defaultAnimationForKey:key];
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
	[super encodeWithCoder:coder];
}

@end

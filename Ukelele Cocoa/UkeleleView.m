//
//  UkeleleView.m
//  Ukelele 3
//
//  Created by John Brownie on 11/01/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "UkeleleView.h"
#import "UKKeyboardController.h"
#import "LayoutInfo.h"
#import "UkeleleConstants.h"
#import "KeyCapView2Rect.h"
#import "UkeleleConstantStrings.h"

static int kWindowTopMargin = 50;
static int kWindowLeftMargin = 10;
static int kWindowBottomMargin = 9;
static int kWindowRightMargin = 8;
static int kKeyCapInset = 2;
static CGFloat kMininumScaleFactor = 1.0f;
static CGFloat kMaximumScaleFactor = 5.0f;

#define kDefaultFontName	@"Lucida Grande"
#define kDefaultFontSize	18.0

typedef enum UkeleleViewEventState : NSUInteger {
	kEventStateNone = 0,
	kEventStateMagnify = 1
} UkeleleViewEventState;

typedef struct KeyEntryRec {
	char modifierMask;
	char keyCode;
	short deltaV;
	short deltaH;
} KeyEntryRec;
	
@interface UkeleleView()
@property UkeleleViewEventState eventState;
@end

@implementation UkeleleView {
	KeyCodeMap *keyCapMap;
	NSMutableArray *keyCapList;
	CGFloat baseFontSize;
	ModifiersController *modifiersController;
}

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _scaleFactor = 1.0;
		keyCapMap = [[KeyCodeMap alloc] init];
		keyCapList = [NSMutableArray arrayWithCapacity:128];
		NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
		NSString *themeName = [theDefaults stringForKey:UKColourTheme];
		if (themeName == nil || themeName.length == 0) {
				// No default theme
			_colourTheme = [[ColourTheme defaultColourTheme] copy];
		}
		else {
			_colourTheme = [ColourTheme colourThemeNamed:themeName];
		}
		if (_colourTheme == nil) {
				// Failed to get a valid colour theme, so get the default one
			_colourTheme = [[ColourTheme defaultColourTheme] copy];
		}
		NSString *defaultFontName = [theDefaults stringForKey:UKTextFont];
		if (defaultFontName == nil || defaultFontName.length == 0) {
				// Nothing came from the defaults
			defaultFontName = kDefaultFontName;
		}
		CGFloat textSize = [theDefaults floatForKey:UKTextSize];
		if (textSize <= 0) {
				// Nothing came from the defaults
			textSize = kDefaultFontSize;
		}
		CTFontDescriptorRef fontDescriptor = CTFontDescriptorCreateWithNameAndSize((__bridge CFStringRef)defaultFontName, textSize);
		_styleInfo = [[UKStyleInfo alloc] init];
		[_styleInfo setFontDescriptor:fontDescriptor];
		CFRelease(fontDescriptor);
		modifiersController = [[ModifiersController alloc] init];
		_eventState = kEventStateNone;
    }
    return self;
}

- (BOOL)isFlipped {
	return NO;
}

- (BOOL)canBecomeKeyView {
	return YES;
}

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (BOOL)isOpaque {
	return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
	[NSGraphicsContext saveGraphicsState];
	NSColor *backgroundColour = [[self colourTheme] windowBackgroundColour];
	[backgroundColour setFill];
	NSRectFill(dirtyRect);
	[NSGraphicsContext restoreGraphicsState];
}

#pragma mark Create window

- (void)clearView
{
	[keyCapMap clearMap];
	[modifiersController clearController];
	NSArray *subViews = [self subviews];
	NSInteger subViewCount = [subViews count];
	for (NSInteger i = subViewCount - 1; i >= 0; i--) {
		KeyCapView *keyCapView = subViews[i];
		[keyCapView removeFromSuperviewWithoutNeedingDisplay];
	}
}

- (NSRect)get1RectBounds:(NSPoint)originPoint withPoint:(Point)newPoint withScaleFactor:(float)scaleValue
{
	NSRect boundingRect;
	boundingRect.origin = NSMakePoint(originPoint.x + kKeyCapInset, originPoint.y + kKeyCapInset);
	boundingRect.size = NSMakeSize(scaleValue * (newPoint.h - 1) - kKeyCapInset,
								   scaleValue * (newPoint.v - 1) - kKeyCapInset);
	return boundingRect;
}

- (KeyCapView *)read1RectKey:(NSPoint)originPoint withPoint:(Point)newPoint withScaleFactor:(float)scaleValue
{
	NSRect boundingRect = [self get1RectBounds:originPoint
									 withPoint:newPoint
							   withScaleFactor:scaleValue];
	KeyCapView *keyCap = [[KeyCapView alloc] initWithFrame:boundingRect];
	return keyCap;
}

- (void)calculate2RectKey:(NSPoint)originPoint
			   withPoint1:(Point)point1
			   withPoint2:(Point)point2
		  withScaleFactor:(float)scaleValue
				  toRect1:(NSRect *)rect1
				  toRect2:(NSRect *)rect2
{
		// It's possible that there are negative vertical offsets in one
		// or both points, so we need to work out where the two rectangles
		// will join before insetting them.
	NSRect keyRect1, keyRect2;
	keyRect1.origin.x = originPoint.x;
	keyRect1.size.width = scaleValue * point1.h;
	if (point1.v > 0) {
		keyRect1.origin.y = originPoint.y;
		keyRect1.size.height = scaleValue * point1.v;
	}
	else {
		keyRect1.origin.y = originPoint.y + scaleValue * point1.v;
		keyRect1.size.height = -scaleValue * point1.v;
	}
	NSPoint newPoint = NSMakePoint(originPoint.x + scaleValue * point1.h,
								   originPoint.y + scaleValue * point1.v);
	if (point1.h > point2.h) {
		keyRect2.origin.x = originPoint.x + scaleValue * point2.h;
		keyRect2.size.width = newPoint.x - keyRect2.origin.x;
	}
	else {
		keyRect2.origin.x = newPoint.x;
		keyRect2.size.width = originPoint.x + scaleValue * point2.h - newPoint.x;
	}
	if (point2.v > 0) {
		keyRect2.origin.y = newPoint.y;
		keyRect2.size.height = originPoint.y + scaleValue * point2.v - newPoint.y;
	}
	else {
		keyRect2.origin.y = originPoint.y + scaleValue * point2.v;
		keyRect2.size.height = newPoint.y - keyRect2.origin.y;
	}
		// At this point, we have the two rectangles, but they need to be inset.
		// First, though, we'll normalise them to have keyRect1 on top.
	if (keyRect1.origin.y > keyRect2.origin.y) {
		NSRect tempRect = keyRect1;
		keyRect1 = keyRect2;
		keyRect2 = tempRect;
	}
	keyRect1.origin.x += kKeyCapInset;
	keyRect1.size.width -= scaleValue + kKeyCapInset;
	keyRect2.origin.x += kKeyCapInset;
	keyRect2.size.width -= scaleValue + kKeyCapInset;
	keyRect1.origin.y += kKeyCapInset;
	keyRect2.size.height -= scaleValue;
	if (keyRect1.origin.x < keyRect2.origin.x) {
		keyRect1.size.height -= scaleValue + kKeyCapInset;
		keyRect2.origin.y -= scaleValue;
		keyRect2.size.height += scaleValue;
	}
	else {
		keyRect2.origin.y += kKeyCapInset;
		keyRect2.size.height -= kKeyCapInset;
	}
	*rect1 = keyRect1;
	*rect2 = keyRect2;
}

- (NSRect)get2RectBounds:(NSPoint)originPoint
			  withPoint1:(Point)point1
			  withPoint2:(Point)point2
		 withScaleFactor:(float)scaleValue
{
	NSRect keyRect1, keyRect2;
	[self calculate2RectKey:originPoint
				 withPoint1:point1
				 withPoint2:point2
			withScaleFactor:scaleValue
					toRect1:&keyRect1
					toRect2:&keyRect2];
	return NSRectFromCGRect(CGRectUnion(NSRectToCGRect(keyRect1), NSRectToCGRect(keyRect2)));
}

- (KeyCapView2Rect *)read2RectKey:(NSPoint)originPoint
					   withPoint1:(Point)point1
					   withPoint2:(Point)point2
				  withScaleFactor:(float)scaleValue
{
	NSRect keyRect1, keyRect2;
	[self calculate2RectKey:originPoint
				 withPoint1:point1
				 withPoint2:point2
			withScaleFactor:scaleValue
					toRect1:&keyRect1
					toRect2:&keyRect2];
	KeyCapView2Rect *keyCap = [[KeyCapView2Rect alloc] initWithRect1:keyRect1 withRect2:keyRect2];
	return keyCap;
}

	// Set the absolute scale to a given figure

- (void)scaleViewToScale:(CGFloat)scaleValue limited:(BOOL)limited
{
	NSAssert(scaleValue > 0.0, @"Must have a positive scale factor");
		// Clamp scaleValue to a valid scale
	if (limited && scaleValue < kMininumScaleFactor) {
		scaleValue = kMininumScaleFactor;
	}
	else if (limited && scaleValue > kMaximumScaleFactor) {
		scaleValue = kMaximumScaleFactor;
	}
	if ([self scaleFactor] < scaleValue) {
			// Expand the view first, so the subviews have somewhere to go
		NSRect newFrame;
		newFrame.origin.x = self.baseFrame.origin.x * scaleValue;
		newFrame.origin.y = self.baseFrame.origin.y * scaleValue;
		newFrame.size.height = self.baseFrame.size.height * scaleValue;
		newFrame.size.width = self.baseFrame.size.width * scaleValue;
		[self setFrame:newFrame];
	}
	for (KeyCapView *keyCap in [self subviews]) {
		[keyCap setScale:scaleValue];
	}
	if ([self scaleFactor] > scaleValue) {
			// Contract the view to the required size
		NSRect newFrame;
		newFrame.origin.x = self.baseFrame.origin.x * scaleValue;
		newFrame.origin.y = self.baseFrame.origin.y * scaleValue;
		newFrame.size.height = self.baseFrame.size.height * scaleValue;
		newFrame.size.width = self.baseFrame.size.width * scaleValue;
		[self setFrame:newFrame];
	}
	[self.styleInfo setScaleFactor:scaleValue];
	UKKeyboardController *theDocumentWindow = [[self window] windowController];
	[theDocumentWindow messageScaleChanged:[self scaleFactor]];
}

	// Scale the view by a relative figure

- (void)scaleViewBy:(CGFloat)scaleValue limited:(BOOL)limited
{
	NSAssert(scaleValue > 0.0, @"Must have a positive scale factor");
	CGFloat newScale = [self scaleFactor] * scaleValue;
	[self scaleViewToScale:newScale limited:limited];
}

- (void)createViewWithStream:(char *)theStream forID:(int)keyboardID withScale:(float)scaleValue {
	NSAssert(scaleValue > 0.0, @"Must have a positive scale factor");
	NSAssert(keyboardID >= 0, @"Must have a valid keyboard ID");
	char *resourcePtr = theStream;
	[self clearView];
	
		// First item: Boundary rectangle
	Rect boundaryRect;
	boundaryRect = *(Rect *)resourcePtr;
	resourcePtr += sizeof(Rect);
		// Remove the margins
	boundaryRect.bottom -= kWindowTopMargin + kWindowBottomMargin;
	boundaryRect.right -= kWindowLeftMargin + kWindowRightMargin;
		// Enlarge by doubling the scale
	boundaryRect.bottom = 2 * boundaryRect.bottom - boundaryRect.top;
	boundaryRect.right = 2 * boundaryRect.right - boundaryRect.left;
		// Keep track of the bounds of the content
	NSRect contentRect = NSZeroRect;
	
		// Second item: Text rectangle, which we ignore
	resourcePtr += sizeof(Rect);
	
		// Third item: Count of shape items in main array
	UInt16 shapeCount = *(UInt16 *)resourcePtr;
	resourcePtr += sizeof(UInt16);
	NSAssert(shapeCount > 0, @"Must be data");
	
		// Get the layout information for this layout
	LayoutInfo *layoutInfo = [[LayoutInfo alloc] initWithLayoutID:keyboardID];
	
		// Get a list of heights of key rectangles we find
	int maxHeight = (boundaryRect.bottom - boundaryRect.top);
	unsigned int *heightList = malloc(maxHeight * sizeof(unsigned int));
	for (unsigned int h = 0; h <= (unsigned int)maxHeight; h++) {
		heightList[h] = 0;
	}

		// Last item: Main array
	for (unsigned int shapeNum = 0; shapeNum < shapeCount; shapeNum++) {
			// Current point starts at origin of read boundary rectangle
		NSPoint currentPt;
		currentPt.x = -kWindowLeftMargin;
		currentPt.y = -kWindowTopMargin;
		
			// First item of main array element: Shape array,
			// beginning with count of point entries - 1
		UInt16 pointCount = *(UInt16 *)(resourcePtr);
		resourcePtr += sizeof(UInt16);
		pointCount++;
		
			// Next are the point entries
		Point *pointList = malloc(pointCount * sizeof(Point));
		for (UInt16 pointNum = 0; pointNum < pointCount; pointNum++) {
			pointList[pointNum] = *(Point *)resourcePtr;
			resourcePtr += sizeof(Point);
		}
		
			// Second item of main array element: Count of key entries - 1
		UInt16 keyCount = *(UInt16 *)resourcePtr;
		resourcePtr += sizeof(UInt16);
		keyCount++;
		
			// Remaining items are key entries
		for (UInt16 keyNum = 0; keyNum < keyCount; keyNum++) {
				// Key entry has modifier mask (which we ignore), then virtual key code,
				// then vertical and horizontal deltas
			KeyEntryRec keyEntry = *(KeyEntryRec *)resourcePtr;
			resourcePtr += sizeof(KeyEntryRec);
			char keyCode = keyEntry.keyCode & 0x7f;
				// Work around apparent bug in resource flipper on Intel
			if (keyCode == 0 && keyEntry.modifierMask != 0) {
				keyCode = keyEntry.modifierMask & 0x7f;
			}
			SInt16 deltaV = keyEntry.deltaV;
			SInt16 deltaH = keyEntry.deltaH;
			
			if (deltaV == 0 && deltaH == 0 && keyNum > 0) {
				continue;	// Repeat of the same key
			}
			
				// Now create the key cap
			currentPt.x += 2 * deltaH;
			currentPt.y += 2 * deltaV;
			NSRect keyCapBounds;
			KeyCapView *keyCap;
			if (pointCount == 1) {
					// Simple rectangular key
				keyCap = [self read1RectKey:currentPt
								  withPoint:pointList[0]
							withScaleFactor:2.0];
			}
			else {
                NSAssert1(pointCount == 2, @"Key with more than 2 (%d) rectangles", pointCount);
					// Three or more rectangle key!
                // Create two rectangle key
				keyCap = [self read2RectKey:currentPt
								 withPoint1:pointList[0]
								 withPoint2:pointList[1]
							withScaleFactor:2.0];
			}
			keyCapBounds = [keyCap boundingRect];
			if ((NSInteger)contentRect.size.width == 0 && (NSInteger)contentRect.size.height == 0) {
				contentRect = keyCapBounds;
			}
			else {
				contentRect = NSRectFromCGRect(CGRectUnion(NSRectToCGRect(contentRect), NSRectToCGRect(keyCapBounds)));
			}
				// Note the height
			SInt16 keyHeight = (SInt16)(ceil(keyCapBounds.size.height));
			heightList[keyHeight]++;
				// Get the key codes
			unsigned int fnKeyCode = [layoutInfo getFnKeyCodeForKey:keyCode];
				// Create the key cap view
			[keyCap setKeyCode:keyCode];
			[keyCap setFnKeyCode:fnKeyCode];
			[keyCap setColourTheme:[self colourTheme]];
			[keyCap setStyleInfo:self.styleInfo];
			[self addSubview:keyCap];
			[keyCapMap addKeyCode:keyCode withKeyKapView:keyCap];
			if ((char)fnKeyCode != keyCode && fnKeyCode != kNoKeyCode) {
				[keyCapMap addKeyCode:fnKeyCode withKeyKapView:keyCap];
			}
				// Set the string for modifier keys
			UInt32 keyType = [LayoutInfo getKeyType:keyCode];
			[keyCap setKeyType:keyType];
			if (keyType == kModifierKeyType) {
				NSString *modifierString = [LayoutInfo getKeySymbol:keyCode withString:@""];
				[keyCap setOutputString:modifierString];
				[modifiersController addModifier:keyCap];
			}
			else {
				[keyCapList addObject:keyCap];
				[keyCap registerForDraggedTypes:@[NSPasteboardTypeString]];
			}
		}
		free(pointList);
	}
	
		// Work out whether we need to move the views
	contentRect = NSRectFromCGRect(CGRectOffset(NSRectToCGRect(contentRect), -kKeyCapInset, -kKeyCapInset));
	contentRect.size.width += 2 * kKeyCapInset;
	contentRect.size.height += 2 * kKeyCapInset;
	BOOL needMove = fabs(contentRect.origin.x) > 0.5 || fabs(contentRect.origin.y) > 0.5;
	
		// Find the most common key height
	SInt16 commonHeight = (SInt16)heightList[0];
	for (SInt16 h = 1; h <= maxHeight; h++) {
		if (heightList[h] > heightList[commonHeight]) {
			commonHeight = h;
		}
	}
	free(heightList);
		// Run through the panes and set whether they are small, and move if needed
	NSArray *subViews = [self subviews];
	NSInteger numSubViews = [subViews count];
	for (NSInteger subViewIndex = 0; subViewIndex < numSubViews; subViewIndex++) {
		KeyCapView *keyCapView = subViews[subViewIndex];
		NSRect subViewFrame = [keyCapView frame];
		[keyCapView setSmall:ceil(subViewFrame.size.height) < commonHeight];
		if (needMove) {
			[keyCapView offsetFrameX:-contentRect.origin.x Y:-contentRect.origin.y];
		}
	}
	
	[self setFrameSize:contentRect.size];
	[self setBaseFrame:contentRect];
		// Run through the panes and flip them
	subViews = [self subviews];
	NSRect boundsRect = [self bounds];
	for (KeyCapView *keyCapView in subViews) {
		[keyCapView flipInRect:boundsRect];
		[keyCapView finishInit];
	}
		// Now scale to the appropriate value
	[self setScaleFactor:0.5];
	[self scaleViewToScale:scaleValue limited:YES];
	[self setNeedsDisplay:YES];
}

- (int)createViewWithKeyboardID:(int)keyboardID withScale:(float)scaleValue
{
	NSAssert(scaleValue > 0.0, @"Must have a positive scale factor");
		// Read the resource into memory and treat as a stream
	int actualID = keyboardID;
	NSURL *resourceURL = [[NSBundle mainBundle] URLForResource:UKKCAPListFile withExtension:@"plist"];
	NSDictionary *resourceDict = [NSDictionary dictionaryWithContentsOfURL:resourceURL];
	NSString *idString = [NSString stringWithFormat:@"%d", keyboardID];
	NSData *resourceData = resourceDict[idString];
	if (resourceData == nil) {
			// No such keyboard
		NSLog(@"Failed to create a keyboard with id %d, using default", keyboardID);
		actualID = gestaltUSBAndyANSIKbd;
		idString = [NSString stringWithFormat:@"%d", actualID];
		resourceData = resourceDict[idString];
		NSAssert(resourceData != nil, @"Must be able to create the default keyboard");
	}
		// The data is what used to be a resource, and we'll get a pointer to it and use
		// that as a stream of characters
	char *resourcePtr = (char *)[resourceData bytes];
	[self createViewWithStream:resourcePtr forID:keyboardID withScale:scaleValue];
	return actualID;
}

#pragma mark Access routines

- (KeyCapView *)getKeyWithIndex:(int)keyIndex
{
	return keyCapList[keyIndex];
}

- (void)setKeyText:(int)keyCode withModifiers:(unsigned int)modifiers withString:(NSString *)text
{
#pragma unused(modifiers)
	NSArray *keyList = [keyCapMap getKeysWithCode:keyCode];
	NSUInteger keyCount = [keyList count];
	for (NSUInteger i = 0; i < keyCount; i++) {
		KeyCapView *keyCap = (KeyCapView *)keyList[i];
		[keyCap setOutputString:text];
	}
}

- (KeyCapView *)findKeyWithCode:(int)keyCode
{
	NSArray *keyList = [keyCapMap getKeysWithCode:keyCode];
	if ([keyList count] == 0) {
		return nil;
	}
	return keyList[0];
}

- (NSArray *)keyCapViews
{
	return keyCapList;
}

- (void)updateModifiers:(unsigned int)modifierCombination
{
	[modifiersController updateModifiers:modifierCombination];
}

- (void)setColourTheme:(ColourTheme *)newColourTheme {
	NSAssert(newColourTheme != nil, @"Must have a non-nil theme");
	if (_colourTheme != newColourTheme) {
		_colourTheme = newColourTheme;
		for (NSView *subView in [self subviews]) {
			if ([subView isKindOfClass:[KeyCapView class]] || [subView isKindOfClass:[KeyCapView2Rect class]]) {
				[(KeyCapView *)subView setColourTheme:_colourTheme];
			}
		}
	}
}

- (void)setMenuDelegate:(id<UKMenuDelegate>)theDelegate {
	for (NSView *subView in [self subviews]) {
		if ([subView isKindOfClass:[KeyCapView class]] || [subView isKindOfClass:[KeyCapView2Rect class]]) {
			[(KeyCapView *)subView setMenuDelegate:theDelegate];
		}
	}
}

- (void)changeLargeFont:(NSFont *)newLargeFont {
	[self.styleInfo changeLargeFont:newLargeFont];
	for (NSView *subView in [self subviews]) {
		if ([subView isKindOfClass:[KeyCapView class]] || [subView isKindOfClass:[KeyCapView2Rect class]]) {
			[(KeyCapView *)subView styleDidUpdate];
		}
	}
}

#pragma mark Events

- (void)magnifyWithEvent:(NSEvent *)event
{
	CGFloat magnification = [event magnification] + 1.0;
	if (magnification <= 0.0) {
		magnification = 0.1;
	}
	[self scaleViewBy:magnification limited:YES];
	[self setEventState:kEventStateMagnify];
}

- (void)endGestureWithEvent:(NSEvent *)event
{
#pragma unused(event)
	if ([self eventState] == kEventStateMagnify) {
		UKKeyboardController *theDocumentWindow = [[self window] windowController];
		[theDocumentWindow messageScaleCompleted];
		[self setEventState:kEventStateNone];
	}
}

- (BOOL)isFnKey:(NSEvent *)theEvent
{
	int keyCode = [theEvent keyCode];
	BOOL result = NO;
	switch (keyCode) {
		case kKeyEnd:
		case kKeyForwardDelete:
		case kKeyHome:
		case kKeyPad0:
		case kKeyPad1:
		case kKeyPad2:
		case kKeyPad3:
		case kKeyPad4:
		case kKeyPad5:
		case kKeyPad6:
		case kKeyPad7:
		case kKeyPad8:
		case kKeyPad9:
		case kKeyPadClear:
		case kKeyPadDot:
		case kKeyPadEnter:
		case kKeyPadEquals:
		case kKeyPadMinus:
		case kKeyPadPlus:
		case kKeyPadSlash:
		case kKeyPadStar:
		case kKeyPageDown:
		case kKeyPageUp:
			result = YES;
			break;
	}
	return result;
}

- (void)passOnModifiers:(int)modifiers
{
	UKKeyboardController *theDocumentWindow = [[self window] windowController];
	[theDocumentWindow messageModifiersChanged:modifiers];
}

- (void)keyDown:(NSEvent *)theEvent
{
	int keyCode = [theEvent keyCode];
	KeyCapView *keyCap = [self findKeyWithCode:keyCode];
	[keyCap setDown:YES];
	if ([self isFnKey:theEvent]) {
		unsigned int flags = (unsigned int)[theEvent modifierFlags] | NSNumericPadKeyMask;
		[self passOnModifiers:flags];
	}
	UKKeyboardController *theDocumentWindow = [[self window] windowController];
	[theDocumentWindow messageKeyDown:keyCode];
}

- (void)keyUp:(NSEvent *)theEvent
{
	int keyCode = [theEvent keyCode];
	KeyCapView *keyCap = [self findKeyWithCode:keyCode];
	[keyCap setDown:NO];
	if ([self isFnKey:theEvent]) {
		unsigned int flags = (unsigned int)[theEvent modifierFlags] & ~NSNumericPadKeyMask;
		[self passOnModifiers:flags];
	}
	UKKeyboardController *theDocumentWindow = [[self window] windowController];
	[theDocumentWindow messageKeyUp:keyCode];
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	int flags = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
	[self passOnModifiers:flags];
	[super flagsChanged:theEvent];
}

@end

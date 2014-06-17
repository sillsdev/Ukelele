//
//  UkeleleView.m
//  Ukelele 3
//
//  Created by John Brownie on 11/01/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "UkeleleView.h"
#import "UKKeyboardWindow.h"
#import "LayoutInfo.h"
#import "UkeleleConstants.h"
#import "KeyCapView2Rect.h"
#import "UkeleleConstantStrings.h"

static int kWindowTopMargin = 50;
static int kWindowLeftMargin = 10;
static int kWindowBottomMargin = 9;
static int kWindowRightMargin = 8;
//static int kWindowMargin = 2;
static int kKeyCapInset = 2;
static CGFloat kLineHeightFactor = 1.5f;
static CGFloat kSmallLineHeightFactor = 1.3f;
static CGFloat kMininumScaleFactor = 1.0f;
static CGFloat kMaximumScaleFactor = 5.0f;

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

@implementation UkeleleView

- (void)setUpStyles
{
		// Set up Core Text styles
	CTFontRef largeFont = CTFontCreateWithFontDescriptor(_fontDescriptor, 0.0f, NULL);
	CGFloat largeFontSize = CTFontGetSize(largeFont);
	CGFloat smallFontSize = largeFontSize * kDefaultSmallFontSize / kDefaultLargeFontSize;
	CTParagraphStyleSetting styleSetting[2];
	styleSetting[0].spec = kCTParagraphStyleSpecifierAlignment;
	styleSetting[0].valueSize = sizeof(CTTextAlignment);
	CTTextAlignment alignType = kCTCenterTextAlignment;
	styleSetting[0].value = &alignType;
	styleSetting[1].spec = kCTParagraphStyleSpecifierMinimumLineHeight;
	styleSetting[1].valueSize = sizeof(CGFloat);
	CGFloat minLineHeight = largeFontSize * kLineHeightFactor;
	styleSetting[1].value = &minLineHeight;
	_largeParagraphStyle = CTParagraphStyleCreate(styleSetting, 2);
	minLineHeight = smallFontSize * kSmallLineHeightFactor;
	_smallParagraphStyle = CTParagraphStyleCreate(styleSetting, 2);
	CFRelease(largeFont);
    
		// Set up Cocoa styles
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
	NSString *fontName = [theDefaults stringForKey:UKTextFont];
    NSFont *defaultLargeFont = [NSFont fontWithName:fontName size:kDefaultLargeFontSize];
    _largeAttributes = [NSMutableDictionary dictionary];
    [_largeAttributes setValue:defaultLargeFont forKey:NSFontAttributeName];
    [_largeAttributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
    NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
    [paraStyle setAlignment:NSCenterTextAlignment];
    [_largeAttributes setValue:paraStyle forKey:NSParagraphStyleAttributeName];
    NSFont *defaultSmallFont = [[NSFontManager sharedFontManager] convertFont:defaultLargeFont toSize:kDefaultSmallFontSize];
    _smallAttributes = [NSMutableDictionary dictionary];
    [_smallAttributes setValue:defaultSmallFont forKey:NSFontAttributeName];
    [_smallAttributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
    [_smallAttributes setValue:paraStyle forKey:NSParagraphStyleAttributeName];
	baseFontSize = [theDefaults floatForKey:UKTextSize] / [self scaleFactor];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _scaleFactor = 1.0;
		_colourTheme = [[ColourTheme defaultColourTheme] copy];
		keyCapMap = [[KeyCodeMap alloc] init];
		keyCapList = [NSMutableArray arrayWithCapacity:128];
		NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
		NSString *defaultFontName = [theDefaults stringForKey:UKTextFont];
		_fontDescriptor = CTFontDescriptorCreateWithNameAndSize((__bridge CFStringRef)defaultFontName, [theDefaults floatForKey:UKTextSize]);
		[self setUpStyles];
		modifiersController = [[ModifiersController alloc] init];
		_eventState = kEventStateNone;
    }
    return self;
}

- (void)dealloc
{
	if (_fontDescriptor) {
		CFRelease(_fontDescriptor);
	}
	if (_largeParagraphStyle) {
		CFRelease(_largeParagraphStyle);
	}
	if (_smallParagraphStyle) {
		CFRelease(_smallParagraphStyle);
	}
}

- (BOOL)isFlipped
{
	return NO;
}

- (BOOL)canBecomeKeyView
{
	return YES;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    // Drawing code here.
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
	NSRect boundingRect = [self get1RectBounds:originPoint withPoint:newPoint
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
	NSMutableDictionary *newLargeAttributes = [[self largeAttributes] mutableCopy];
	NSFont *largeFont = newLargeAttributes[NSFontAttributeName];
	NSFontManager *fm = [NSFontManager sharedFontManager];
	NSFont *newLargeFont = [fm convertFont:largeFont toSize:baseFontSize * scaleValue];
	newLargeAttributes[NSFontAttributeName] = newLargeFont;
	NSMutableDictionary *newSmallAttributes = [[self smallAttributes] mutableCopy];
	NSFont *smallFont = newSmallAttributes[NSFontAttributeName];
	NSFont *newSmallFont = [fm convertFont:smallFont
									toSize:baseFontSize * scaleValue * kDefaultSmallFontSize / kDefaultLargeFontSize];
	newSmallAttributes[NSFontAttributeName] = newSmallFont;
	[self setScaleFactor:scaleValue];
	[self setLargeAttributes:newLargeAttributes];
	[self setSmallAttributes:newSmallAttributes];
	UKKeyboardWindow *theDocumentWindow = [[self window] windowController];
	[theDocumentWindow messageScaleChanged:[self scaleFactor]];
}

	// Scale the view by a relative figure

- (void)scaleViewBy:(CGFloat)scaleValue limited:(BOOL)limited
{
	CGFloat newScale = [self scaleFactor] * scaleValue;
	[self scaleViewToScale:newScale limited:limited];
}

- (void)createViewWithKeyboardID:(int)keyboardID withScale:(float)scaleValue
{
	CGFloat kFontSizeFactor = kDefaultSmallFontSize / kDefaultLargeFontSize;
		// Read the resource into memory and treat as a stream
	Handle dataHandle = GetResource(kResType_KCAP, keyboardID);
	if (dataHandle == NULL || HandToHand(&dataHandle) != noErr) {
		return;
	}
	char *resourcePtr = *dataHandle;
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
	if (shapeCount == 0) {
			// There are no keys defined in this layout, so abort
		DisposeHandle(dataHandle);
		return;
	}
	
		// Get the layout information for this layout
	LayoutInfo *layoutInfo = [[LayoutInfo alloc] initWithLayoutID:keyboardID];
	
		// Get a list of heights of key rectangles we find
	int maxHeight = (boundaryRect.bottom - boundaryRect.top);
	unsigned int *heightList = malloc(maxHeight * sizeof(unsigned int));
	for (unsigned int h = 0; h <= maxHeight; h++) {
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
			contentRect = NSRectFromCGRect(CGRectUnion(NSRectToCGRect(contentRect), NSRectToCGRect(keyCapBounds)));
				// Note the height
			SInt16 keyHeight = ceil(keyCapBounds.size.height);
			heightList[keyHeight]++;
				// Get the key codes
			unsigned int fnKeyCode = [layoutInfo getFnKeyCodeForKey:keyCode];
				// Create the key cap view
			[keyCap setKeyCode:keyCode];
			[keyCap setFnKeyCode:fnKeyCode];
			[keyCap setColourTheme:[self colourTheme]];
			CTFontRef largeFont = CTFontCreateWithFontDescriptor([self fontDescriptor], 0.0f, NULL);
			CGFloat smallFontSize = CTFontGetSize(largeFont) * kFontSizeFactor;
			CTFontRef smallFont = CTFontCreateWithFontDescriptor([self fontDescriptor], smallFontSize, NULL);
			[keyCap setLargeCTFont:largeFont];
			[keyCap setSmallCTFont:smallFont];
			[keyCap setLargeCTStyle:[self largeParagraphStyle]];
			[keyCap setSmallCTStyle:[self smallParagraphStyle]];
            if ([self largeAttributes]) {
                [keyCap setLargeAttributes:[self largeAttributes]];
                [keyCap setSmallAttributes:[self smallAttributes]];
            }
			[self addSubview:keyCap];
			CFRelease(smallFont);
			CFRelease(largeFont);
			[keyCapMap addKeyCode:keyCode withKeyKapView:keyCap];
			if (fnKeyCode != keyCode && fnKeyCode != kNoKeyCode) {
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
	DisposeHandle(dataHandle);
	
		// Work out whether we need to move the views
	contentRect = NSRectFromCGRect(CGRectOffset(NSRectToCGRect(contentRect), -kKeyCapInset, -kKeyCapInset));
	contentRect.size.width += 2 * kKeyCapInset;
	contentRect.size.height += 2 * kKeyCapInset;
	BOOL needMove = fabs(contentRect.origin.x) > 0.5 || fabs(contentRect.origin.y) > 0.5;
	
		// Find the most common key height
	SInt16 commonHeight = heightList[0];
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

#pragma mark Access routines

- (void)setLargeAttributes:(NSDictionary *)newAttributes
{
    _largeAttributes = newAttributes;
	NSFont *font = _largeAttributes[NSFontAttributeName];
	baseFontSize = [font pointSize] / [self scaleFactor];
    // Have to update all the key views
    NSArray *subViews = [self subviews];
    for (KeyCapView *subView in subViews) {
        [subView setLargeAttributes:_largeAttributes];
    }
    [self setNeedsDisplay:YES];
}

- (void)setSmallAttributes:(NSDictionary *)newAttributes
{
    _smallAttributes = newAttributes;
    // Have to update all the key views
    NSArray *subViews = [self subviews];
    for (KeyCapView *subView in subViews) {
        [subView setSmallAttributes:_smallAttributes];
    }
    [self setNeedsDisplay:YES];
}

- (KeyCapView *)getKeyWithIndex:(int)keyIndex
{
	return keyCapList[keyIndex];
}

- (void)setKeyText:(int)keyCode withModifiers:(unsigned int)modifiers withString:(NSString *)text
{
	NSArray *keyList = [keyCapMap getKeysWithCode:keyCode];
	NSUInteger keyCount = [keyList count];
	for (NSUInteger i = 0; i < keyCount; i++) {
		KeyCapView *keyCap = (KeyCapView *)keyList[i];
		[keyCap setOutputString:text];
//		if (modifiers & kEventKeyModifierNumLockMask) {
//			if ([keyCap numLockKeyCode] == keyCode) {
//				[keyCap setOutputString:text];
//			}
//		}
//		else if (modifiers & kEventKeyModifierFnMask) {
//			if ([keyCap fnKeyCode] == keyCode) {
//				[keyCap setOutputString:text];
//			}
//		}
//		else {
//			[keyCap setOutputString:text];
//		}
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

- (void)setFontDescriptor:(CTFontDescriptorRef)newFont
{
	if (newFont != _fontDescriptor) {
		CFRelease(_fontDescriptor);
		_fontDescriptor = newFont;
		CFRetain(_fontDescriptor);
		CTFontRef largeFont = CTFontCreateWithFontDescriptor(_fontDescriptor, 0.0f, NULL);
		CGFloat largeFontSize = CTFontGetSize(largeFont);
		CGFloat smallFontSize = largeFontSize * kDefaultLargeFontSize / kDefaultSmallFontSize;
		CTFontRef smallFont = CTFontCreateWithFontDescriptor(_fontDescriptor, smallFontSize, NULL);
			// Update the styles
		CFRelease(_largeParagraphStyle);
		CFRelease(_smallParagraphStyle);
		[self setUpStyles];
			// Replace the styles for all the subviews
		NSArray *allSubViews = [self subviews];
		NSUInteger subViewCount = [allSubViews count];
		for (NSUInteger i = 0; i < subViewCount; i++) {
			KeyCapView *keyCapView = allSubViews[i];
			[keyCapView setLargeCTFont:largeFont];
			[keyCapView setSmallCTFont:smallFont];
			[keyCapView setLargeCTStyle:[self largeParagraphStyle]];
			[keyCapView setSmallCTStyle:[self smallParagraphStyle]];
		}
		CFRelease(smallFont);
		CFRelease(largeFont);
	}
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
	if (_colourTheme != newColourTheme) {
		_colourTheme = newColourTheme;
		for (NSView *subView in [self subviews]) {
			if ([subView isKindOfClass:[KeyCapView class]]  || [subView isKindOfClass:[KeyCapView2Rect class]]) {
				[(KeyCapView *)subView setColourTheme:_colourTheme];
			}
		}
	}
}

- (void)setMenuDelegate:(id<UKMenuDelegate>)theDelegate {
	for (NSView *subView in [self subviews]) {
		if ([subView isKindOfClass:[KeyCapView class]]  || [subView isKindOfClass:[KeyCapView2Rect class]]) {
			[(KeyCapView *)subView setMenuDelegate:theDelegate];
		}
	}
}

#pragma mark Events

- (void)magnifyWithEvent:(NSEvent *)event
{
	[self scaleViewBy:[event magnification] + 1.0 limited:YES];
	[self setEventState:kEventStateMagnify];
}

- (void)endGestureWithEvent:(NSEvent *)event
{
	if ([self eventState] == kEventStateMagnify) {
		UKKeyboardWindow *theDocumentWindow = [[self window] windowController];
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
	UKKeyboardWindow *theDocumentWindow = [[self window] windowController];
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
	UKKeyboardWindow *theDocumentWindow = [[self window] windowController];
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
	UKKeyboardWindow *theDocumentWindow = [[self window] windowController];
	[theDocumentWindow messageKeyUp:keyCode];
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	int flags = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
	[self passOnModifiers:flags];
	[super flagsChanged:theEvent];
}

@end

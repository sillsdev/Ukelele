//
//  KeyCapView2Rect.m
//  Ukelele 3
//
//  Created by John Brownie on 21/01/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "KeyCapView2Rect.h"

enum e_orientations {
	topLeft, topRight, bottomLeft, bottomRight
};
static CGAffineTransform kTextTransform = {
	1.0, 0.0, 0.0, 1.0, 0.0, 0.0
};

#define kKeyInset 2.0f
#define kSmallKeyInset 1.0f

@implementation KeyCapView2Rect {
	NSRect keyRect1;
	NSRect keyRect2;
	NSRect frameRect;
	NSRect frameRect1;
	NSRect frameRect2;
	unsigned int orientation;
	NSRect interiorRect;
	NSPoint pointList[6];
}

- (void)setRect1:(NSRect)rect1 andRect2:(NSRect)rect2
{
	if (rect1.origin.y < rect2.origin.y) {
		keyRect1 = rect1;
		keyRect2 = rect2;
	}
	else {
		keyRect1 = rect2;
		keyRect2 = rect1;
	}
	keyRect1 = NSOffsetRect(keyRect1, -frameRect.origin.x, -frameRect.origin.y);
	keyRect2 = NSOffsetRect(keyRect2, -frameRect.origin.x, -frameRect.origin.y);
	CGFloat x1 = keyRect1.origin.x;
	CGFloat x2 = x1 + keyRect1.size.width;
	CGFloat x3 = keyRect2.origin.x;
	CGFloat x4 = x3 + keyRect2.size.width;
	CGFloat y1 = keyRect1.origin.y;
	CGFloat y2 = y1 + keyRect1.size.height;
	CGFloat y3 = keyRect2.origin.y + keyRect2.size.height;
	if ((int) x2 == (int) x4) {
		if (x1 < x3) {
				// Top left
			orientation = topLeft;
			interiorRect.origin = NSMakePoint(x3, y1);
			interiorRect.size = NSMakeSize(keyRect2.size.width, frameRect.size.height);
		}
		else {
				// Bottom left
			orientation = bottomLeft;
			interiorRect.origin = NSMakePoint(x1, y1);
			interiorRect.size = NSMakeSize(keyRect1.size.width, frameRect.size.height);
		}
		pointList[0] = NSMakePoint(x1, y1);
		pointList[1] = NSMakePoint(x2, y1);
		pointList[2] = NSMakePoint(x2, y3);
		pointList[3] = NSMakePoint(x3, y3);
		pointList[4] = NSMakePoint(x3, y2);
		pointList[5] = NSMakePoint(x1, y2);
	}
	else {
		if (x2 > x4) {
				// Top right
			orientation = topRight;
			interiorRect.origin = NSMakePoint(x1, y1);
			interiorRect.size = NSMakeSize(keyRect2.size.width, frameRect.size.height);
		}
		else {
				// Bottom right
			orientation = bottomRight;
			interiorRect.origin = NSMakePoint(x1, y1);
			interiorRect.size = NSMakeSize(keyRect1.size.width, frameRect.size.height);
		}
		pointList[0] = NSMakePoint(x1, y1);
		pointList[1] = NSMakePoint(x2, y1);
		pointList[2] = NSMakePoint(x2, y2);
		pointList[3] = NSMakePoint(x4, y2);
		pointList[4] = NSMakePoint(x4, y3);
		pointList[5] = NSMakePoint(x1, y3);
	}
}

- (instancetype)initWithRect1:(NSRect)rect1 withRect2:(NSRect)rect2
{
	frameRect = NSUnionRect(rect1, rect2);
	self = [super initWithFrame:frameRect];
	if (self) {
		[self setRect1:rect1 andRect2:rect2];
        NSTrackingAreaOptions trackingOptions = NSTrackingMouseEnteredAndExited |
            NSTrackingActiveInActiveApp | NSTrackingInVisibleRect;
		NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:rect1
                                                                    options:trackingOptions
                                                                      owner:self
                                                                   userInfo:nil];
		[self addTrackingArea:trackingArea];
		trackingArea = [[NSTrackingArea alloc] initWithRect:rect2
                                                    options:trackingOptions
                                                      owner:self
                                                   userInfo:nil];
		[self addTrackingArea:trackingArea];
	}
	return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
#pragma unused(dirtyRect)
		// Save state
	[NSGraphicsContext saveGraphicsState];
		// Clip to the two rectangles
	NSRect clipList[2] = { keyRect1, keyRect2 };
	NSRectClipList(clipList, 2);
		// See what gradient type we have
	NSRect boundingRect = NSUnionRect(keyRect1, keyRect2);
	NSColor *innerColour;
	NSColor *outerColour;
	NSColor *textColour;
	NSUInteger gradientType;
	[self getInnerColour:&innerColour outerColour:&outerColour textColour:&textColour gradientType:&gradientType];
	[self setCurrentTextColour:textColour];
	NSGradient *colourGradient = nil;
	if (gradientType == gradientTypeLinear) {
			// Linear gradient
		colourGradient = [[NSGradient alloc] initWithStartingColor:innerColour endingColor:outerColour];
		[colourGradient drawInRect:boundingRect angle:90];
	}
	else if (gradientType == gradientTypeRadial) {
			// Radial gradient
		colourGradient = [[NSGradient alloc] initWithStartingColor:innerColour endingColor:outerColour];
		[colourGradient drawInRect:boundingRect relativeCenterPosition:NSZeroPoint];
	}
	else {
			// No gradient
		[innerColour setFill];
		NSRectFill(boundingRect);
		[outerColour setStroke];
		[NSBezierPath setDefaultLineWidth:2.0];
		CGFloat inset = 1.0f;
		NSBezierPath *path = [NSBezierPath bezierPath];
		[path moveToPoint:NSMakePoint(pointList[0].x + inset, pointList[0].y + inset)];
		[path lineToPoint:NSMakePoint(pointList[1].x - inset, pointList[1].y + inset)];
		switch (orientation) {
			case topLeft:
				[path lineToPoint:NSMakePoint(pointList[2].x - inset, pointList[2].y - inset)];
				[path lineToPoint:NSMakePoint(pointList[3].x + inset, pointList[3].y - inset)];
				[path lineToPoint:NSMakePoint(pointList[4].x + inset, pointList[4].y - inset)];
				[path lineToPoint:NSMakePoint(pointList[5].x + inset, pointList[5].y - inset)];
				break;
				
			case topRight:
				[path lineToPoint:NSMakePoint(pointList[2].x - inset, pointList[2].y - inset)];
				[path lineToPoint:NSMakePoint(pointList[3].x - inset, pointList[3].y - inset)];
				[path lineToPoint:NSMakePoint(pointList[4].x - inset, pointList[4].y - inset)];
				[path lineToPoint:NSMakePoint(pointList[5].x + inset, pointList[5].y - inset)];
				break;
				
			case bottomLeft:
				[path lineToPoint:NSMakePoint(pointList[2].x - inset, pointList[2].y - inset)];
				[path lineToPoint:NSMakePoint(pointList[3].x + inset, pointList[3].y - inset)];
				[path lineToPoint:NSMakePoint(pointList[4].x + inset, pointList[4].y + inset)];
				[path lineToPoint:NSMakePoint(pointList[5].x + inset, pointList[5].y + inset)];
				break;
				
			case bottomRight:
				[path lineToPoint:NSMakePoint(pointList[2].x - inset, pointList[2].y + inset)];
				[path lineToPoint:NSMakePoint(pointList[3].x - inset, pointList[3].y + inset)];
				[path lineToPoint:NSMakePoint(pointList[4].x - inset, pointList[4].y - inset)];
				[path lineToPoint:NSMakePoint(pointList[5].x + inset, pointList[5].y - inset)];
				break;
		}
		[path closePath];
		[path stroke];
	}
	if (self.dragHighlight) {
			// Draw the drag highlight
		NSColor *dragColour = [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.375];
		[dragColour set];
		[NSBezierPath fillRect:boundingRect];
	}
		// Draw the text
	CGContextRef myContext = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSetTextMatrix(myContext, kTextTransform);
	[self.outputString drawInRect:interiorRect withAttributes:nil];
		// Restore state
	[NSGraphicsContext restoreGraphicsState];
	if (self.fallback) {
			// Draw grey
		NSColor *greyColour = [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:fallbackAlpha];
		[greyColour setFill];
		[NSBezierPath fillRect:keyRect1];
		[NSBezierPath fillRect:keyRect2];
	}
}

- (NSRect)boundingRect
{
	return frameRect;
}

- (NSRect)insideRect
{
	return interiorRect;
}

- (void)flipInRect:(NSRect)boundingRect
{
	NSRect newFrameRect = [self frame];
	NSRect rect1 = keyRect1;
	NSRect rect2 = keyRect2;
		// Flip the frame within the bounding rectangle
	newFrameRect.origin.y = boundingRect.size.height - newFrameRect.origin.y - newFrameRect.size.height;
		// Flip the rectangles within the frame
	rect1.origin.y = newFrameRect.size.height - rect1.origin.y - rect1.size.height;
	rect2.origin.y = newFrameRect.size.height - rect2.origin.y - rect2.size.height;
		// Adjust the rectangles to frame coordinates
	rect1 = NSOffsetRect(rect1, newFrameRect.origin.x, newFrameRect.origin.y);
	rect2 = NSOffsetRect(rect2, newFrameRect.origin.x, newFrameRect.origin.y);
		// Adjust the rectangles and drawing points
	[self setRect1:rect1 andRect2:rect2];
	[self setFrame:newFrameRect];
}

- (void)finishInit
{
		// Lock the coordinates of the unscaled rectangles
	frameRect1 = NSOffsetRect(keyRect1, frameRect.origin.x, frameRect.origin.y);
	frameRect2 = NSOffsetRect(keyRect2, frameRect.origin.x, frameRect.origin.y);
	NSRect textRect = NSInsetRect(interiorRect, kKeyInset, self.small ? kSmallKeyInset : kKeyInset);
	[self setupTextView:textRect];
}

- (void)changeScaleBy:(CGFloat)scaleMultiplier
{
	frameRect.origin.x *= scaleMultiplier;
	frameRect.origin.y *= scaleMultiplier;
	frameRect.size.height *= scaleMultiplier;
	frameRect.size.width *= scaleMultiplier;
	keyRect1.origin.x *= scaleMultiplier;
	keyRect1.origin.y *= scaleMultiplier;
	keyRect1.size.height *= scaleMultiplier;
	keyRect1.size.width *= scaleMultiplier;
	keyRect2.origin.x *= scaleMultiplier;
	keyRect2.origin.y *= scaleMultiplier;
	keyRect2.size.height *= scaleMultiplier;
	keyRect2.size.width *= scaleMultiplier;
	[self setRect1:keyRect1 andRect2:keyRect2];
	[self setFrame:frameRect];
}

- (void)setScale:(CGFloat)scaleValue
{
	NSRect rect1 = NSRectFromCGRect(CGRectMake((frameRect1.origin.x) * scaleValue,
											   (frameRect1.origin.y) * scaleValue,
											   frameRect1.size.width * scaleValue, frameRect1.size.height * scaleValue));
	NSRect rect2 = NSRectFromCGRect(CGRectMake((frameRect2.origin.x) * scaleValue,
											   (frameRect2.origin.y) * scaleValue,
											   frameRect2.size.width * scaleValue, frameRect2.size.height * scaleValue));
	frameRect = NSUnionRect(rect1, rect2);
	[self setRect1:rect1 andRect2:rect2];
	[self setFrame:frameRect];
}

- (void)offsetFrameX:(CGFloat)xOffset Y:(CGFloat)yOffset
{
	[self setFrame:NSOffsetRect([self frame], xOffset, yOffset)];
	frameRect = NSOffsetRect(frameRect, xOffset, yOffset);
}

@end

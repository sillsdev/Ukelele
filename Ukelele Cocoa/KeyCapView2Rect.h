//
//  KeyCapView2Rect.h
//  Ukelele 3
//
//  Created by John Brownie on 21/01/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KeyCapView.h"

@interface KeyCapView2Rect : KeyCapView {
	NSRect keyRect1;
	NSRect keyRect2;
	NSRect frameRect;
	NSRect frameRect1;
	NSRect frameRect2;
	unsigned int orientation;
	NSRect interiorRect;
	NSPoint pointList[6];
}

- (id)initWithRect1:(NSRect)rect1 withRect2:(NSRect)rect2;

@end

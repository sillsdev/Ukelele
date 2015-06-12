//
//  UKKeyboardPrintView.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 21/02/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import "UKKeyboardPrintView.h"

@implementation UKKeyboardPrintInfo

- (instancetype)init {
	self = [super init];
	if (self) {
		_viewDict = nil;
		_stateCount = 0;
		_modifierCount = 0;
		_stateList = nil;
		_modifierList = nil;
		_viewHeight = 0;
		_availablePageHeight = 0;
		_viewsPerPage = 0;
	}
	return self;
}

@end

@implementation UKKeyboardPrintView

- (BOOL)isOpaque {
	return YES;
}

- (void)setAllStates:(BOOL)allStates {
	BOOL oldState = _allStates;
	_allStates = allStates;
	if (oldState != allStates) {
		[self calculatePageCount];
	}
}

- (void)setAllModifiers:(BOOL)allModifiers {
	BOOL oldModifiers = _allModifiers;
	_allModifiers = allModifiers;
	if (oldModifiers != allModifiers) {
		[self calculatePageCount];
	}
}

- (void)calculatePageCount {
	NSUInteger keyboardCount = 1;
	if (self.allStates) {
		keyboardCount *= self.printingInfo.stateCount;
	}
	if (self.allModifiers) {
		keyboardCount *= self.printingInfo.modifierCount;
	}
	CGFloat totalHeight = keyboardCount * self.printingInfo.viewHeight;
	[self setFrameSize:NSMakeSize(self.bounds.size.width, totalHeight)];
	NSArray *subViews = [self subviews];
	while ([subViews count] > 0) {
		NSView *subView = subViews[0];
		[subView removeFromSuperview];
		subViews = [self subviews];
	}
	NSMutableArray *viewsToAdd = [NSMutableArray arrayWithCapacity:keyboardCount];
	if (self.allStates) {
			// Run through all the states
		for (NSString *stateName in self.printingInfo.stateList) {
			NSArray *stateSet = self.printingInfo.viewDict[stateName];
			if (self.allModifiers) {
					// Run through the modifiers
				[viewsToAdd addObjectsFromArray:stateSet];
			}
			else {
					// Just the current modifiers
				[viewsToAdd addObject:stateSet[self.currentModifierIndex]];
			}
		}
	}
	else {
			// Just the current state
		NSArray *viewList = self.printingInfo.viewDict[self.currentState];
		if (self.allModifiers) {
				// Run through all the modifiers
			[viewsToAdd addObjectsFromArray:viewList];
		}
		else {
				// Just the current modifier
			[viewsToAdd addObject:viewList[self.currentModifierIndex]];
		}
	}
	NSUInteger viewCount = [viewsToAdd count];
	for (NSUInteger i = 0; i < viewCount; i++) {
		NSView *theView = viewsToAdd[i];
		[theView setFrameOrigin:NSMakePoint(0, totalHeight - (i + 1) * self.printingInfo.viewHeight)];
		[self addSubview:theView];
	}
}

- (BOOL)knowsPageRange:(NSRangePointer)range {
	range->length = (NSUInteger)(ceil([[self subviews] count] / (CGFloat)self.printingInfo.viewsPerPage));
	return YES;
}

- (NSRect)rectForPage:(NSInteger)page {
	CGFloat totalHeight = self.bounds.size.height;
	CGFloat pageHeight = self.printingInfo.viewHeight * self.printingInfo.viewsPerPage;
	CGFloat heightAbove = (page - 1) * pageHeight;
	CGFloat yOrigin;
	CGFloat rectHeight;
	if (totalHeight - heightAbove <= pageHeight) {
		yOrigin = 0.0;
		rectHeight = totalHeight - heightAbove;
	}
	else {
		yOrigin = totalHeight - heightAbove - pageHeight;
		rectHeight = pageHeight;
	}
	return NSMakeRect(0, yOrigin, self.bounds.size.width, rectHeight);
}

@end

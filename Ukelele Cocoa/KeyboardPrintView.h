//
//  KeyboardPrintView.h
//  Ukelele 3
//
//  Created by John Brownie on 22/11/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UKKeyboardController;

@interface KeyboardPrintView : NSView {
	NSMutableArray *keyboardViews;
	NSMutableArray *labelViews;
	CGFloat keyboardScaleValue;
	CGFloat keyboardHeight;
	NSInteger keyboardsPerPage;
	NSMutableArray *keyboardPlaceHolders;
}

@property (nonatomic, weak) UKKeyboardController *parentDocument;
@property (nonatomic) BOOL allStates;
@property (nonatomic) BOOL allModifiers;

- (void)setupPageParameters;
- (NSInteger)pageCount;

@end

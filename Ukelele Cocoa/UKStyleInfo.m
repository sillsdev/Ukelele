//
//  UKStyleInfo.m
//  Ukelele
//
//  Created by John Brownie on 8/08/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import "UKStyleInfo.h"
#import "UkeleleConstants.h"
#import "UkeleleConstantStrings.h"

#define kDefaultFontName	@"Lucida Grande"
#define kDefaultFontSize	18.0

@implementation UKStyleInfo {
	CGFloat baseFontSize;
}

- (instancetype)init {
	if (self = [super init]) {
		_scaleFactor = 1.0;
		_largeAttributes = nil;
		_smallAttributes = nil;
		_largeFont = nil;
	}
	return self;
}

- (void)setUpStyles {
		// Set up Cocoa styles
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
	NSString *fontName = [theDefaults stringForKey:UKTextFont];
	if (fontName == nil || fontName.length == 0) {
			// Nothing came from the defaults
		fontName = kDefaultFontName;
	}
	CGFloat textSize = [theDefaults floatForKey:UKTextSize];
	if (textSize <= 0) {
			// Nothing came from the defaults
		textSize = kDefaultFontSize;
	}
	baseFontSize = textSize;
	NSFont *defaultLargeFont = [NSFont fontWithName:fontName size:baseFontSize * self.scaleFactor];
	self.largeFont = defaultLargeFont;
	self.largeAttributes = [NSMutableDictionary dictionary];
	[self.largeAttributes setValue:defaultLargeFont forKey:NSFontAttributeName];
	[self.largeAttributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
	[paraStyle setAlignment:NSCenterTextAlignment];
	[self.largeAttributes setValue:paraStyle forKey:NSParagraphStyleAttributeName];
	NSFont *defaultSmallFont = [[NSFontManager sharedFontManager] convertFont:defaultLargeFont toSize:kDefaultSmallFontSize * self.scaleFactor];
	self.smallAttributes = [NSMutableDictionary dictionary];
	[self.smallAttributes setValue:defaultSmallFont forKey:NSFontAttributeName];
	[self.smallAttributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	[self.smallAttributes setValue:paraStyle forKey:NSParagraphStyleAttributeName];
}

- (void)updateStyles {
		// Set up Cocoa styles
	NSString *fontName = [self.largeFont fontName];
	if (fontName == nil || fontName.length == 0) {
			// No font name found
		fontName = kDefaultFontName;
	}
	CGFloat largeFontSize = baseFontSize * self.scaleFactor;
	NSFont *cocoaLargeFont = [NSFont fontWithName:fontName size:largeFontSize];
	self.largeFont = cocoaLargeFont;
	self.largeAttributes = [NSMutableDictionary dictionary];
	[self.largeAttributes setValue:cocoaLargeFont forKey:NSFontAttributeName];
	[self.largeAttributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
	[paraStyle setAlignment:NSCenterTextAlignment];
	[self.largeAttributes setValue:paraStyle forKey:NSParagraphStyleAttributeName];
	CGFloat smallFontSize = largeFontSize * kDefaultSmallFontSize / kDefaultLargeFontSize;
	NSFont *cocoaSmallFont = [[NSFontManager sharedFontManager] convertFont:cocoaLargeFont toSize:smallFontSize];
	self.smallAttributes = [NSMutableDictionary dictionary];
	[self.smallAttributes setValue:cocoaSmallFont forKey:NSFontAttributeName];
	[self.smallAttributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	[self.smallAttributes setValue:paraStyle forKey:NSParagraphStyleAttributeName];
}

- (void)setScaleFactor:(CGFloat)scaleFactor {
	_scaleFactor = scaleFactor;
	[self updateStyles];
}

- (void)changeLargeFont:(NSFont *)newFont {
	self.largeFont = newFont;
	[self updateStyles];
}

@end

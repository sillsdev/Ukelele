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

static CGFloat kLineHeightFactor = 1.5f;
static CGFloat kSmallLineHeightFactor = 1.3f;

#define kDefaultFontName	@"Lucida Grande"
#define kDefaultFontSize	18.0

@implementation UKStyleInfo {
	CGFloat baseFontSize;
}

- (instancetype)init {
	if (self = [super init]) {
		_scaleFactor = 1.0;
		_fontDescriptor = nil;
		_largeParagraphStyle = nil;
		_smallParagraphStyle = nil;
		_largeAttributes = nil;
		_smallAttributes = nil;
		_largeFont = nil;
		_smallFont = nil;
	}
	return self;
}

- (void)dealloc {
	if (_fontDescriptor) {
		CFRelease(_fontDescriptor);
	}
	if (_largeParagraphStyle) {
		CFRelease(_largeParagraphStyle);
	}
	if (_smallParagraphStyle) {
		CFRelease(_smallParagraphStyle);
	}
	if (_largeFont) {
		CFRelease(_largeFont);
	}
	if (_smallFont) {
		CFRelease(_smallFont);
	}
}

- (void)setUpStyles {
		// Set up Core Text styles
	CGFloat largeFontSize = CTFontGetSize(_largeFont);
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
	if (_largeParagraphStyle) {
		CFRelease(_largeParagraphStyle);
	}
	self.largeParagraphStyle = CTParagraphStyleCreate(styleSetting, 2);
	minLineHeight = smallFontSize * kSmallLineHeightFactor;
	if (_smallParagraphStyle) {
		CFRelease(_smallParagraphStyle);
	}
	self.smallParagraphStyle = CTParagraphStyleCreate(styleSetting, 2);
	
		// Set up Cocoa styles
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
	NSString *fontName = [theDefaults stringForKey:UKTextFont];
	if (fontName == nil || fontName.length == 0) {
			// Nothing came from the defaults
		fontName = kDefaultFontName;
	}
	NSFont *defaultLargeFont = [NSFont fontWithName:fontName size:kDefaultLargeFontSize];
	self.largeAttributes = [NSMutableDictionary dictionary];
	[self.largeAttributes setValue:defaultLargeFont forKey:NSFontAttributeName];
	[self.largeAttributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
	[paraStyle setAlignment:NSCenterTextAlignment];
	[self.largeAttributes setValue:paraStyle forKey:NSParagraphStyleAttributeName];
	NSFont *defaultSmallFont = [[NSFontManager sharedFontManager] convertFont:defaultLargeFont toSize:kDefaultSmallFontSize];
	self.smallAttributes = [NSMutableDictionary dictionary];
	[self.smallAttributes setValue:defaultSmallFont forKey:NSFontAttributeName];
	[self.smallAttributes setValue:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	[self.smallAttributes setValue:paraStyle forKey:NSParagraphStyleAttributeName];
	CGFloat textSize = [theDefaults floatForKey:UKTextSize];
	if (textSize <= 0) {
			// Nothing came from the defaults
		textSize = kDefaultFontSize;
	}
	baseFontSize = textSize / self.scaleFactor;
}

- (void)setScaleFactor:(CGFloat)scaleFactor {
	_scaleFactor = scaleFactor;
	[self setUpStyles];
}

- (void)setFontDescriptor:(CTFontDescriptorRef)fontDescriptor {
	if (fontDescriptor != _fontDescriptor) {
		if (_fontDescriptor) {
			CFRelease(_fontDescriptor);
		}
		_fontDescriptor = fontDescriptor;
		CFRetain(_fontDescriptor);
		self.largeFont = CTFontCreateWithFontDescriptor(_fontDescriptor, 0.0f, NULL);
		CGFloat largeFontSize = CTFontGetSize(self.largeFont);
		CGFloat smallFontSize = largeFontSize * kDefaultLargeFontSize / kDefaultSmallFontSize;
		self.smallFont = CTFontCreateWithFontDescriptor(_fontDescriptor, smallFontSize, NULL);
			// Update the styles
		[self setUpStyles];
	}
}

- (void)changeLargeFont:(NSFont *)newFont {
	NSString *fontName = [newFont fontName];
	CGFloat fontSize = [newFont pointSize];
	CTFontDescriptorRef fontDescriptor = CTFontDescriptorCreateWithNameAndSize((CFStringRef)fontName, fontSize);
	[self setFontDescriptor:fontDescriptor];
}

@end

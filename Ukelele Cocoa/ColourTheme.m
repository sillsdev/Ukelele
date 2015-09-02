//
//  ColourTheme.m
//  Ukelele 3
//
//  Created by John Brownie on 5/02/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "ColourTheme.h"
#import "UkeleleConstantStrings.h"

	
// Constants for encoding gradient type information

enum {
	kNormalShift = 0,
	kDeadKeyShift = 4,
	kSelectedShift = 8,
	kSelectedDeadShift = 12,
	kNormalDownShift = 16,
	kDeadKeyDownShift = 20,
	kSelectedDownShift = 24,
	kSelectedDeadDownShift = 28
};

enum {
	kNormalMask = 0x7,
	kDeadKeyMask = 0x7 << kDeadKeyShift,
	kSelectedMask = 0x7 << kSelectedShift,
	kSelectedDeadMask = 0x7 << kSelectedDeadShift,
	kNormalDownMask = 0x7 << kNormalDownShift,
	kDeadKeyDownMask = 0x7 << kDeadKeyDownShift,
	kSelectedDownMask = 0x7 << kSelectedDownShift,
	kSelectedDeadDownMask = 0x7 << kSelectedDeadDownShift
};

	// Standard colour components

const CGFloat component50 = (0x50 * 1.0) / 255.0;
const CGFloat component10 = (0x10 * 1.0) / 255.0;
const CGFloat componentBD = (0xBD * 1.0) / 255.0;
const CGFloat component45 = (0x45 * 1.0) / 255.0;
const CGFloat component88 = (0x88 * 1.0) / 255.0;
const CGFloat component3E = (0x3E * 1.0) / 255.0;
const CGFloat component94 = (0x94 * 1.0) / 255.0;
const CGFloat componentD5 = (0xD5 * 1.0) / 255.0;
const CGFloat componentAC = (0xAC * 1.0) / 255.0;
const CGFloat componentE2 = (0xE2 * 1.0) / 255.0;
const CGFloat component0C = (0x0C * 1.0) / 255.0;
const CGFloat componentB0 = (0xB0 * 1.0) / 255.0;
const CGFloat componentD1 = (0xD1 * 1.0) / 255.0;
const CGFloat component16 = (0x16 * 1.0) / 255.0;
const CGFloat componentE1 = (0xE1 * 1.0) / 255.0;
const CGFloat component8B = (0x8B * 1.0) / 255.0;
const CGFloat component93 = (0x93 * 1.0) / 255.0;
const CGFloat component57 = (0x57 * 1.0) / 255.0;

	// Constants for coding

static NSString *kCTThemeNameKey = @"CTTheme Name";
static NSString *kCTGradientTypeKey = @"CTGradientType";
static NSString *kCTNormalUpInnerColourKey = @"CTNormalUpInnerColour";
static NSString *kCTNormalUpOuterColourKey = @"CTNormalUpOuterColour";
static NSString *kCTNormalUpTextColourKey = @"CTNormalUpTextColour";
static NSString *kCTNormalDownInnerColourKey = @"CTNormalDownInnerColour";
static NSString *kCTNormalDownOuterColourKey = @"CTNormalDownOuterColour";
static NSString *kCTNormalDownTextColourKey = @"CTNormalDownTextColour";
static NSString *kCTDeadKeyUpInnerColourKey = @"CTDeadKeyUpInnerColour";
static NSString *kCTDeadKeyUpOuterColourKey = @"CTDeadKeyUpOuterColour";
static NSString *kCTDeadKeyUpTextColourKey = @"CTDeadKeyUpTextColour";
static NSString *kCTDeadKeyDownInnerColourKey = @"CTDeadKeyDownInnerColour";
static NSString *kCTDeadKeyDownOuterColourKey = @"CTDeadKeyDownOuterColour";
static NSString *kCTDeadKeyDownTextColourKey = @"CTDeadKeyDownTextColour";
static NSString *kCTSelectedUpInnerColourKey = @"CTSelectedUpInnerColour";
static NSString *kCTSelectedUpOuterColourKey = @"CTSelectedUpOuterColour";
static NSString *kCTSelectedUpTextColourKey = @"CTSelectedUpTextColour";
static NSString *kCTSelectedDownInnerColourKey = @"CTSelectedDownInnerColour";
static NSString *kCTSelectedDownOuterColourKey = @"CTSelectedDownOuterColour";
static NSString *kCTSelectedDownTextColourKey = @"CTSelectedDownTextColour";
static NSString *kCTSelectedDeadUpInnerColourKey = @"CTSelectedDeadUpInnerColour";
static NSString *kCTSelectedDeadUpOuterColourKey = @"CTSelectedDeadUpOuterColour";
static NSString *kCTSelectedDeadUpTextColourKey = @"CTSelectedDeadUpTextColour";
static NSString *kCTSelectedDeadDownInnerColourKey = @"CTSelectedDeadDownInnerColour";
static NSString *kCTSelectedDeadDownOuterColourKey = @"CTSelectedDeadDownOuterColour";
static NSString *kCTSelectedDeadDownTextColourKey = @"CTSelectedDeadDownTextColour";
static NSString *kCTWindowBackgroundColourKey = @"CTWindowBackgroundColour";

static ColourTheme *sDefaultColourTheme = nil;
static ColourTheme *sDefaultPrintTheme = nil;
static NSString *currentlySetColourTheme = nil;

NSString *kDefaultThemeName = @"Default";
NSString *kPrintThemeName = @"Print";

@implementation ColourTheme {
	unsigned int gradientTypes;
}

- (instancetype)init
{
	self = [super init];
	_normalUpInnerColour = nil;
	_normalUpOuterColour = nil;
	_normalUpTextColour = nil;
	_normalDownInnerColour = nil;
	_normalDownOuterColour = nil;
	_normalDownTextColour = nil;
	_deadKeyUpInnerColour = nil;
	_deadKeyUpOuterColour = nil;
	_deadKeyUpTextColour = nil;
	_deadKeyDownInnerColour = nil;
	_deadKeyDownOuterColour = nil;
	_deadKeyDownTextColour = nil;
	_selectedUpInnerColour = nil;
	_selectedUpOuterColour = nil;
	_selectedUpTextColour = nil;
	_selectedDownInnerColour = nil;
	_selectedDownOuterColour = nil;
	_selectedDownTextColour = nil;
	_selectedDeadUpInnerColour = nil;
	_selectedDeadUpOuterColour = nil;
	_selectedDeadUpTextColour = nil;
	_selectedDeadDownInnerColour = nil;
	_selectedDeadDownOuterColour = nil;
	_selectedDeadDownTextColour = nil;
	_windowBackgroundColour = nil;
	gradientTypes = 0;
	return self;
}


- (ColourTheme *)copy
{
	ColourTheme *theCopy = [[ColourTheme alloc] init];
	[theCopy setThemeName:[self themeName]];
	[theCopy setNormalUpInnerColour:[self normalUpInnerColour]];
	[theCopy setNormalUpOuterColour:[self normalUpOuterColour]];
	[theCopy setNormalUpTextColour:[self normalUpTextColour]];
	[theCopy setNormalDownInnerColour:[self normalDownInnerColour]];
	[theCopy setNormalDownOuterColour:[self normalDownOuterColour]];
	[theCopy setNormalDownTextColour:[self normalDownTextColour]];
	[theCopy setDeadKeyUpInnerColour:[self deadKeyUpInnerColour]];
	[theCopy setDeadKeyUpOuterColour:[self deadKeyUpOuterColour]];
	[theCopy setDeadKeyUpTextColour:[self deadKeyUpTextColour]];
	[theCopy setDeadKeyDownInnerColour:[self deadKeyDownInnerColour]];
	[theCopy setDeadKeyDownOuterColour:[self deadKeyDownOuterColour]];
	[theCopy setDeadKeyDownTextColour:[self deadKeyDownTextColour]];
	[theCopy setSelectedUpInnerColour:[self selectedUpInnerColour]];
	[theCopy setSelectedUpOuterColour:[self selectedUpOuterColour]];
	[theCopy setSelectedUpTextColour:[self selectedUpTextColour]];
	[theCopy setSelectedDownInnerColour:[self selectedDownInnerColour]];
	[theCopy setSelectedDownOuterColour:[self selectedDownOuterColour]];
	[theCopy setSelectedDownTextColour:[self selectedDownTextColour]];
	[theCopy setSelectedDeadUpInnerColour:[self selectedDeadUpInnerColour]];
	[theCopy setSelectedDeadUpOuterColour:[self selectedDeadUpOuterColour]];
	[theCopy setSelectedDeadUpTextColour:[self selectedDeadUpTextColour]];
	[theCopy setSelectedDeadDownInnerColour:[self selectedDeadDownInnerColour]];
	[theCopy setSelectedDeadDownOuterColour:[self selectedDeadDownOuterColour]];
	[theCopy setSelectedDeadDownTextColour:[self selectedDeadDownTextColour]];
	[theCopy setWindowBackgroundColour:[self windowBackgroundColour]];
	[theCopy setNormalGradientType:[self normalGradientType]];
	[theCopy setDeadKeyGradientType:[self deadKeyGradientType]];
	[theCopy setSelectedGradientType:[self selectedGradientType]];
	[theCopy setSelectedDeadGradientType:[self selectedDeadGradientType]];
	[theCopy setNormalDownGradientType:[self normalDownGradientType]];
	[theCopy setDeadKeyDownGradientType:[self deadKeyDownGradientType]];
	[theCopy setSelectedDownGradientType:[self selectedDownGradientType]];
	[theCopy setSelectedDeadDownGradientType:[self selectedDeadDownGradientType]];
	return theCopy;
}

+ (ColourTheme *)defaultColourTheme
{
	if (sDefaultColourTheme == nil) {
			// Create the default theme
		sDefaultColourTheme = [[ColourTheme alloc] init];
		[sDefaultColourTheme setThemeName:kDefaultThemeName];
		[sDefaultColourTheme setNormalUpInnerColour:[NSColor colorWithCalibratedRed:component10
																			  green:component10
																			   blue:1.0
																			  alpha:1.0]];
		[sDefaultColourTheme setNormalUpOuterColour:[NSColor colorWithCalibratedRed:component50
																			  green:component50
																			   blue:1.0
																			  alpha:1.0]];
		[sDefaultColourTheme setNormalUpTextColour:[NSColor whiteColor]];
		[sDefaultColourTheme setNormalDownInnerColour:[NSColor colorWithCalibratedRed:0.0
																				green:component88
																				 blue:component45
																				alpha:1.0]];
		[sDefaultColourTheme setNormalDownOuterColour:[NSColor colorWithCalibratedRed:0.0
																				green:componentBD
																				 blue:component45
																				alpha:1.0]];
		[sDefaultColourTheme setNormalDownTextColour:[NSColor whiteColor]];
		[sDefaultColourTheme setNormalGradientType:gradientTypeRadial];
		[sDefaultColourTheme setNormalDownGradientType:gradientTypeRadial];
		[sDefaultColourTheme setDeadKeyUpInnerColour:[NSColor colorWithCalibratedRed:component94
																			   green:component3E
																			    blue:0.0
																			   alpha:1.0]];
		[sDefaultColourTheme setDeadKeyUpOuterColour:[NSColor colorWithCalibratedRed:1.0
																			   green:component3E
																				blue:0.0
																			   alpha:1.0]];
		[sDefaultColourTheme setDeadKeyUpTextColour:[NSColor whiteColor]];
		[sDefaultColourTheme setDeadKeyDownInnerColour:[NSColor colorWithCalibratedRed:1.0
																				 green:componentAC
																				  blue:0.0
																				 alpha:1.0]];
		[sDefaultColourTheme setDeadKeyDownOuterColour:[NSColor colorWithCalibratedRed:1.0
																				 green:componentD5
																				  blue:0.0
																				 alpha:1.0]];
		[sDefaultColourTheme setDeadKeyDownTextColour:[NSColor whiteColor]];
		[sDefaultColourTheme setDeadKeyGradientType:gradientTypeRadial];
		[sDefaultColourTheme setDeadKeyDownGradientType:gradientTypeRadial];
		[sDefaultColourTheme setSelectedUpInnerColour:[NSColor colorWithCalibratedRed:componentB0
																				green:componentD1
																				 blue:component16
																				alpha:1.0]];
		[sDefaultColourTheme setSelectedUpOuterColour:[NSColor colorWithCalibratedRed:componentE2
																				green:1.0
																				 blue:component0C
																				alpha:1.0]];
		[sDefaultColourTheme setSelectedUpTextColour:[NSColor whiteColor]];
		[sDefaultColourTheme setSelectedDownInnerColour:[NSColor colorWithCalibratedRed:componentE1
																				  green:component57
																				   blue:component93
																				  alpha:1.0]];
		[sDefaultColourTheme setSelectedDownOuterColour:[NSColor colorWithCalibratedRed:componentE1
																				  green:component8B
																				   blue:component93
																				  alpha:1.0]];
		[sDefaultColourTheme setSelectedDownTextColour:[NSColor whiteColor]];
		[sDefaultColourTheme setSelectedGradientType:gradientTypeRadial];
		[sDefaultColourTheme setSelectedDownGradientType:gradientTypeRadial];
		[sDefaultColourTheme setSelectedDeadUpInnerColour:[NSColor colorWithCalibratedRed:componentB0
																				green:component88
																				 blue:component16
																				alpha:1.0]];
		[sDefaultColourTheme setSelectedDeadUpOuterColour:[NSColor colorWithCalibratedRed:componentE2
																				green:1.0
																				 blue:component0C
																				alpha:1.0]];
		[sDefaultColourTheme setSelectedDeadUpTextColour:[NSColor whiteColor]];
		[sDefaultColourTheme setSelectedDeadDownInnerColour:[NSColor colorWithCalibratedRed:componentE1
																				  green:component57
																				   blue:component93
																				  alpha:1.0]];
		[sDefaultColourTheme setSelectedDeadDownOuterColour:[NSColor colorWithCalibratedRed:componentE1
																				  green:component8B
																				   blue:component93
																				  alpha:1.0]];
		[sDefaultColourTheme setSelectedDeadDownTextColour:[NSColor whiteColor]];
		[sDefaultColourTheme setSelectedDeadGradientType:gradientTypeLinear];
		[sDefaultColourTheme setSelectedDeadDownGradientType:gradientTypeLinear];
		[sDefaultColourTheme setWindowBackgroundColour:[NSColor whiteColor]];
	}
	return sDefaultColourTheme;
}

+ (ColourTheme *)defaultPrintTheme {
	if (sDefaultPrintTheme == nil) {
			// Create the default theme
		sDefaultPrintTheme = [[ColourTheme alloc] init];
		[sDefaultPrintTheme setThemeName:kPrintThemeName];
		[sDefaultPrintTheme setNormalUpInnerColour:[NSColor whiteColor]];
		[sDefaultPrintTheme setNormalUpOuterColour:[NSColor blackColor]];
		[sDefaultPrintTheme setNormalUpTextColour:[NSColor blackColor]];
		[sDefaultPrintTheme setNormalDownInnerColour:[NSColor colorWithCalibratedWhite:0.6 alpha:1.0]];
		[sDefaultPrintTheme setNormalDownOuterColour:[NSColor blackColor]];
		[sDefaultPrintTheme setNormalDownTextColour:[NSColor blackColor]];
		[sDefaultPrintTheme setNormalGradientType:gradientTypeNone];
		[sDefaultPrintTheme setNormalDownGradientType:gradientTypeNone];
		[sDefaultPrintTheme setDeadKeyUpInnerColour:[NSColor colorWithCalibratedWhite:0.2 alpha:1.0]];
		[sDefaultPrintTheme setDeadKeyUpOuterColour:[NSColor whiteColor]];
		[sDefaultPrintTheme setDeadKeyUpTextColour:[NSColor whiteColor]];
		[sDefaultPrintTheme setDeadKeyDownInnerColour:[NSColor colorWithCalibratedWhite:0.1 alpha:1.0]];
		[sDefaultPrintTheme setDeadKeyDownOuterColour:[NSColor whiteColor]];
		[sDefaultPrintTheme setDeadKeyDownTextColour:[NSColor whiteColor]];
		[sDefaultPrintTheme setDeadKeyGradientType:gradientTypeNone];
		[sDefaultPrintTheme setDeadKeyDownGradientType:gradientTypeNone];
		[sDefaultPrintTheme setSelectedUpInnerColour:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0]];
		[sDefaultPrintTheme setSelectedUpOuterColour:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0]];
		[sDefaultPrintTheme setSelectedUpTextColour:[NSColor blackColor]];
		[sDefaultPrintTheme setSelectedDownInnerColour:[NSColor colorWithCalibratedWhite:0.6 alpha:1.0]];
		[sDefaultPrintTheme setSelectedDownOuterColour:[NSColor colorWithCalibratedWhite:0.2 alpha:1.0]];
		[sDefaultPrintTheme setSelectedDownTextColour:[NSColor whiteColor]];
		[sDefaultPrintTheme setSelectedGradientType:gradientTypeLinear];
		[sDefaultPrintTheme setSelectedDownGradientType:gradientTypeLinear];
		[sDefaultPrintTheme setSelectedDeadUpInnerColour:[NSColor colorWithCalibratedWhite:0.9 alpha:1.0]];
		[sDefaultPrintTheme setSelectedDeadUpOuterColour:[NSColor colorWithCalibratedWhite:0.5 alpha:1.0]];
		[sDefaultPrintTheme setSelectedDeadUpTextColour:[NSColor blackColor]];
		[sDefaultPrintTheme setSelectedDeadDownInnerColour:[NSColor colorWithCalibratedWhite:0.6 alpha:1.0]];
		[sDefaultPrintTheme setSelectedDeadDownOuterColour:[NSColor colorWithCalibratedWhite:0.2 alpha:1.0]];
		[sDefaultPrintTheme setSelectedDeadDownTextColour:[NSColor whiteColor]];
		[sDefaultPrintTheme setSelectedDeadGradientType:gradientTypeNone];
		[sDefaultPrintTheme setSelectedDeadDownGradientType:gradientTypeNone];
		[sDefaultPrintTheme setWindowBackgroundColour:[NSColor whiteColor]];
	}
	return sDefaultPrintTheme;
}

+ (ColourTheme *)currentColourTheme {
	return [ColourTheme colourThemeNamed:currentlySetColourTheme];
}

+ (void)setCurrentColourTheme:(NSString *)themeName {
	currentlySetColourTheme = themeName;
}

+ (ColourTheme *)colourThemeNamed:(NSString *)themeName {
	NSDictionary *colourThemes = [ColourTheme colourThemeDictionary];
	NSData *themeData = colourThemes[themeName];
	if (themeData != nil) {
		ColourTheme *theTheme = [NSKeyedUnarchiver unarchiveObjectWithData:themeData];
		if (theTheme != nil) {
			return theTheme;
		}
	}
		// Getting here means the name was not in the dictionary
	if ([themeName isEqualToString:kDefaultThemeName]) {
		return [ColourTheme defaultColourTheme];
	}
	else if ([themeName isEqualToString:kPrintThemeName]) {
		return [ColourTheme defaultPrintTheme];
	}
	return nil;
}

+ (ColourTheme *)createColourThemeNamed:(NSString *)themeName {
	NSMutableDictionary *themeDict = [ColourTheme colourThemeDictionary];
	NSAssert([themeDict objectForKey:themeName] == nil, @"Cannot create a theme that already exists");
	ColourTheme *newTheme = [[ColourTheme defaultColourTheme] copy];
	[newTheme setThemeName:themeName];
	themeDict[themeName] = [NSKeyedArchiver archivedDataWithRootObject:newTheme];
	[ColourTheme saveColourThemes:themeDict];
	return newTheme;
}

+ (void)addTheme:(ColourTheme *)colourTheme {
	NSMutableDictionary *themeDict = [ColourTheme colourThemeDictionary];
	themeDict[[colourTheme themeName]] = [NSKeyedArchiver archivedDataWithRootObject:colourTheme];
	[ColourTheme saveColourThemes:themeDict];
}

+ (void)deleteThemeNamed:(NSString *)themeName {
	NSMutableDictionary *themeDict = [ColourTheme colourThemeDictionary];
	[themeDict removeObjectForKey:themeName];
	[ColourTheme saveColourThemes:themeDict];
}

+ (void)saveTheme:(ColourTheme *)updatedTheme {
	NSMutableDictionary *theThemes = [ColourTheme colourThemeDictionary];
	theThemes[[updatedTheme themeName]] = [NSKeyedArchiver archivedDataWithRootObject:updatedTheme];
	[ColourTheme saveColourThemes:theThemes];
}

+ (NSMutableDictionary *)colourThemeDictionary {
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *colourThemes = [theDefaults objectForKey:UKColourThemes];
	NSAssert(colourThemes != nil, @"Must have a colour themes dictionary");
	return [colourThemes mutableCopy];
}

+ (void)saveColourThemes:(NSDictionary *)themeDictionary {
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
	[theDefaults setObject:themeDictionary forKey:UKColourThemes];
}

+ (BOOL)themeExistsWithName:(NSString *)themeName {
	NSMutableDictionary *themeDict = [ColourTheme colourThemeDictionary];
	return [themeDict objectForKey:themeName] != nil;
}

+ (NSSet *)allColourThemes {
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *colourThemes = [theDefaults objectForKey:UKColourThemes];
	return [NSSet setWithArray:[colourThemes allKeys]];
}

- (void)renameTheme:(NSString *)newName {
	NSAssert(![ColourTheme themeExistsWithName:newName], @"Cannot rename a theme to an existing name");
	NSString *oldName = self.themeName;
	[self setThemeName:newName];
	NSMutableDictionary *themeDict = [ColourTheme colourThemeDictionary];
	[themeDict removeObjectForKey:oldName];
	themeDict[newName] = [NSKeyedArchiver archivedDataWithRootObject:self];
	[ColourTheme saveColourThemes:themeDict];
}

#pragma mark Access routines

- (unsigned int)normalGradientType {
	return gradientTypes & kNormalMask;
}

- (unsigned int)deadKeyGradientType {
	return (gradientTypes & kDeadKeyMask) >> kDeadKeyShift;
}

- (unsigned int)selectedGradientType {
	return (gradientTypes & kSelectedMask) >> kSelectedShift;
}

- (unsigned int)selectedDeadGradientType {
	return (gradientTypes & kSelectedDeadMask) >> kSelectedDeadShift;
}

- (unsigned int)normalDownGradientType {
	return (gradientTypes & kNormalDownMask) >> kNormalDownShift;
}

- (unsigned int)deadKeyDownGradientType {
	return (gradientTypes & kDeadKeyDownMask) >> kDeadKeyDownShift;
}

- (unsigned int)selectedDownGradientType {
	return (gradientTypes & kSelectedDownMask) >> kSelectedDownShift;
}

- (unsigned int)selectedDeadDownGradientType {
	return (gradientTypes & kSelectedDeadDownMask) >> kSelectedDeadDownShift;
}

- (void)setNormalGradientType:(unsigned int)gradientType {
	gradientTypes &= ~kNormalMask;
	gradientTypes |= gradientType;
}

- (void)setDeadKeyGradientType:(unsigned int)gradientType {
	gradientTypes &= ~kDeadKeyMask;
	gradientTypes |= (gradientType << kDeadKeyShift);
}

- (void)setSelectedGradientType:(unsigned int)gradientType {
	gradientTypes &= ~kSelectedMask;
	gradientTypes |= (gradientType << kSelectedShift);
}

- (void)setSelectedDeadGradientType:(unsigned int)gradientType {
	gradientTypes &= ~kSelectedDeadMask;
	gradientTypes |= (gradientType << kSelectedDeadShift);
}

- (void)setNormalDownGradientType:(unsigned int)gradientType {
	gradientTypes &= ~kNormalDownMask;
	gradientTypes |= (gradientType << kNormalDownShift);
}

- (void)setDeadKeyDownGradientType:(unsigned int)gradientType {
	gradientTypes &= ~kDeadKeyDownMask;
	gradientTypes |= (gradientType << kDeadKeyDownShift);
}

- (void)setSelectedDownGradientType:(unsigned int)gradientType {
	gradientTypes &= ~kSelectedDownMask;
	gradientTypes |= (gradientType << kSelectedDownShift);
}

- (void)setSelectedDeadDownGradientType:(unsigned int)gradientType {
	gradientTypes &= ~kSelectedDeadDownMask;
	gradientTypes |= (gradientType << kSelectedDeadDownShift);
}

#pragma mark Coding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[aCoder encodeObject:self.themeName forKey:kCTThemeNameKey];
	[aCoder encodeObject:self.normalUpInnerColour forKey:kCTNormalUpInnerColourKey];
	[aCoder encodeObject:self.normalUpOuterColour forKey:kCTNormalUpOuterColourKey];
	[aCoder encodeObject:self.normalUpTextColour forKey:kCTNormalUpTextColourKey];
	[aCoder encodeObject:self.normalDownInnerColour forKey:kCTNormalDownInnerColourKey];
	[aCoder encodeObject:self.normalDownOuterColour forKey:kCTNormalDownOuterColourKey];
	[aCoder encodeObject:self.normalDownTextColour forKey:kCTNormalDownTextColourKey];
	[aCoder encodeObject:self.deadKeyUpInnerColour forKey:kCTDeadKeyUpInnerColourKey];
	[aCoder encodeObject:self.deadKeyUpOuterColour forKey:kCTDeadKeyUpOuterColourKey];
	[aCoder encodeObject:self.deadKeyUpTextColour forKey:kCTDeadKeyUpTextColourKey];
	[aCoder encodeObject:self.deadKeyDownInnerColour forKey:kCTDeadKeyDownInnerColourKey];
	[aCoder encodeObject:self.deadKeyDownOuterColour forKey:kCTDeadKeyDownOuterColourKey];
	[aCoder encodeObject:self.deadKeyDownTextColour forKey:kCTDeadKeyDownTextColourKey];
	[aCoder encodeObject:self.selectedUpInnerColour forKey:kCTSelectedUpInnerColourKey];
	[aCoder encodeObject:self.selectedUpOuterColour forKey:kCTSelectedUpOuterColourKey];
	[aCoder encodeObject:self.selectedUpTextColour forKey:kCTSelectedUpTextColourKey];
	[aCoder encodeObject:self.selectedDownInnerColour forKey:kCTSelectedDownInnerColourKey];
	[aCoder encodeObject:self.selectedDownOuterColour forKey:kCTSelectedDownOuterColourKey];
	[aCoder encodeObject:self.selectedDownTextColour forKey:kCTSelectedDownTextColourKey];
	[aCoder encodeObject:self.selectedDeadUpInnerColour forKey:kCTSelectedDeadUpInnerColourKey];
	[aCoder encodeObject:self.selectedDeadUpOuterColour forKey:kCTSelectedDeadUpOuterColourKey];
	[aCoder encodeObject:self.selectedDeadUpTextColour forKey:kCTSelectedDeadUpTextColourKey];
	[aCoder encodeObject:self.selectedDeadDownInnerColour forKey:kCTSelectedDeadDownInnerColourKey];
	[aCoder encodeObject:self.selectedDeadDownOuterColour forKey:kCTSelectedDeadDownOuterColourKey];
	[aCoder encodeObject:self.selectedDeadDownTextColour forKey:kCTSelectedDeadDownTextColourKey];
	[aCoder encodeObject:self.windowBackgroundColour forKey:kCTWindowBackgroundColourKey];
	[aCoder encodeInt:gradientTypes forKey:kCTGradientTypeKey];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	_themeName = [aDecoder decodeObjectForKey:kCTThemeNameKey];
	_normalUpInnerColour = [aDecoder decodeObjectForKey:kCTNormalUpInnerColourKey];
	_normalUpOuterColour = [aDecoder decodeObjectForKey:kCTNormalUpOuterColourKey];
	_normalUpTextColour = [aDecoder decodeObjectForKey:kCTNormalUpTextColourKey];
	_normalDownInnerColour = [aDecoder decodeObjectForKey:kCTNormalDownInnerColourKey];
	_normalDownOuterColour = [aDecoder decodeObjectForKey:kCTNormalDownOuterColourKey];
	_normalDownTextColour = [aDecoder decodeObjectForKey:kCTNormalDownTextColourKey];
	_deadKeyUpInnerColour = [aDecoder decodeObjectForKey:kCTDeadKeyUpInnerColourKey];
	_deadKeyUpOuterColour = [aDecoder decodeObjectForKey:kCTDeadKeyUpOuterColourKey];
	_deadKeyUpTextColour = [aDecoder decodeObjectForKey:kCTDeadKeyUpTextColourKey];
	_deadKeyDownInnerColour = [aDecoder decodeObjectForKey:kCTDeadKeyDownInnerColourKey];
	_deadKeyDownOuterColour = [aDecoder decodeObjectForKey:kCTDeadKeyDownOuterColourKey];
	_deadKeyDownTextColour = [aDecoder decodeObjectForKey:kCTDeadKeyDownTextColourKey];
	_selectedUpInnerColour = [aDecoder decodeObjectForKey:kCTSelectedUpInnerColourKey];
	_selectedUpOuterColour = [aDecoder decodeObjectForKey:kCTSelectedUpOuterColourKey];
	_selectedUpTextColour = [aDecoder decodeObjectForKey:kCTSelectedUpTextColourKey];
	_selectedDownInnerColour = [aDecoder decodeObjectForKey:kCTSelectedDownInnerColourKey];
	_selectedDownOuterColour = [aDecoder decodeObjectForKey:kCTSelectedDownOuterColourKey];
	_selectedDownTextColour = [aDecoder decodeObjectForKey:kCTSelectedDownTextColourKey];
	_selectedDeadUpInnerColour = [aDecoder decodeObjectForKey:kCTSelectedDeadUpInnerColourKey];
	_selectedDeadUpOuterColour = [aDecoder decodeObjectForKey:kCTSelectedDeadUpOuterColourKey];
	_selectedDeadUpTextColour = [aDecoder decodeObjectForKey:kCTSelectedDeadUpTextColourKey];
	_selectedDeadDownInnerColour = [aDecoder decodeObjectForKey:kCTSelectedDeadDownInnerColourKey];
	_selectedDeadDownOuterColour = [aDecoder decodeObjectForKey:kCTSelectedDeadDownOuterColourKey];
	_selectedDeadDownTextColour = [aDecoder decodeObjectForKey:kCTSelectedDeadDownTextColourKey];
	_windowBackgroundColour = [aDecoder decodeObjectForKey:kCTWindowBackgroundColourKey];
	gradientTypes = [aDecoder decodeIntForKey:kCTGradientTypeKey];
	return self;
}

@end

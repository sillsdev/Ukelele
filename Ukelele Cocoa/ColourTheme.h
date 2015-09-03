//
//  ColourTheme.h
//  Ukelele 3
//
//  Created by John Brownie on 5/02/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum GradientTypes {
	gradientTypeNone = 0x1,
	gradientTypeLinear = 0x2,
	gradientTypeRadial = 0x4
};

MY_EXTERN NSString *kDefaultThemeName;
MY_EXTERN NSString *kPrintThemeName;

@interface ColourTheme : NSObject<NSCoding>

@property (copy) NSString *themeName;
@property (copy) NSColor *normalUpInnerColour;
@property (copy) NSColor *normalUpOuterColour;
@property (copy) NSColor *normalUpTextColour;
@property (copy) NSColor *normalDownInnerColour;
@property (copy) NSColor *normalDownOuterColour;
@property (copy) NSColor *normalDownTextColour;
@property (copy) NSColor *deadKeyUpInnerColour;
@property (copy) NSColor *deadKeyUpOuterColour;
@property (copy) NSColor *deadKeyUpTextColour;
@property (copy) NSColor *deadKeyDownInnerColour;
@property (copy) NSColor *deadKeyDownOuterColour;
@property (copy) NSColor *deadKeyDownTextColour;
@property (copy) NSColor *selectedUpInnerColour;
@property (copy) NSColor *selectedUpOuterColour;
@property (copy) NSColor *selectedUpTextColour;
@property (copy) NSColor *selectedDownInnerColour;
@property (copy) NSColor *selectedDownOuterColour;
@property (copy) NSColor *selectedDownTextColour;
@property (copy) NSColor *selectedDeadUpInnerColour;
@property (copy) NSColor *selectedDeadUpOuterColour;
@property (copy) NSColor *selectedDeadUpTextColour;
@property (copy) NSColor *selectedDeadDownInnerColour;
@property (copy) NSColor *selectedDeadDownOuterColour;
@property (copy) NSColor *selectedDeadDownTextColour;
@property (copy) NSColor *windowBackgroundColour;
@property (nonatomic) unsigned int normalGradientType;
@property (nonatomic) unsigned int deadKeyGradientType;
@property (nonatomic) unsigned int selectedGradientType;
@property (nonatomic) unsigned int selectedDeadGradientType;
@property (nonatomic) unsigned int normalDownGradientType;
@property (nonatomic) unsigned int deadKeyDownGradientType;
@property (nonatomic) unsigned int selectedDownGradientType;
@property (nonatomic) unsigned int selectedDeadDownGradientType;

+ (ColourTheme *)defaultColourTheme;
+ (ColourTheme *)defaultPrintTheme;
+ (ColourTheme *)colourThemeNamed:(NSString *)themeName;
+ (ColourTheme *)createColourThemeNamed:(NSString *)themeName;
+ (void)addTheme:(ColourTheme *)colourTheme;
+ (void)deleteThemeNamed:(NSString *)themeName;
+ (void)saveTheme:(ColourTheme *)updatedTheme;
+ (BOOL)themeExistsWithName:(NSString *)themeName;
+ (NSSet *)allColourThemes;
+ (ColourTheme *)currentColourTheme;
+ (void)setCurrentColourTheme:(NSString *)themeName;
+ (void)saveCurrentColourThemes;
+ (void)restoreColourThemes;

- (ColourTheme *)copy;
- (void)renameTheme:(NSString *)newName;

@end

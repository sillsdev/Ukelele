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

+ (ColourTheme *)defaultColourTheme;
+ (ColourTheme *)defaultPrintTheme;

- (ColourTheme *)copy;
- (unsigned int)normalGradientType;
- (unsigned int)deadKeyGradientType;
- (unsigned int)selectedGradientType;
- (unsigned int)selectedDeadGradientType;
- (void)setNormalGradientType:(unsigned int)gradientType;
- (void)setDeadKeyGradientType:(unsigned int)gradientType;
- (void)setSelectedGradientType:(unsigned int)gradientType;
- (void)setSelectedDeadGradientType:(unsigned int)gradientType;

@end
//
//  UKDiacriticDisplay.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 5/05/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import "UKDiacriticDisplay.h"
#import "UkeleleConstants.h"

#define kNumberOfDiacritics	5

@implementation UKDiacriticDisplay {
	NSMutableArray *diacriticList;
	NSMutableArray *textList;
}

- (instancetype)init {
	self = [super init];
	if (self) {
		diacriticList = [NSMutableArray arrayWithCapacity:kNumberOfDiacritics];
		textList = [NSMutableArray arrayWithCapacity:kNumberOfDiacritics];
		diacriticList[UKDiacriticSquare] = [NSString stringWithFormat:@"%C", (unichar)kWhiteSquareUnicode];
		textList[UKDiacriticSquare] = @"Square";
		diacriticList[UKDiacriticDottedSquare] = [NSString stringWithFormat:@"%C", (unichar)kDottedSquareUnicode];
		textList[UKDiacriticDottedSquare] = @"Dotted square";
		diacriticList[UKDiacriticCircle] = [NSString stringWithFormat:@"%C", (unichar)kWhiteCircleUnicode];
		textList[UKDiacriticCircle] = @"Circle";
		diacriticList[UKDiacriticDottedCircle] = [NSString stringWithFormat:@"%C", (unichar)kDottedCircleUnicode];
		textList[UKDiacriticDottedCircle] = @"Dotted circle";
		diacriticList[UKDiacriticSpace] = @" ";
		textList[UKDiacriticSpace] = @"Space";
	}
	return self;
}

+ (UKDiacriticDisplay *)getInstance {
	static UKDiacriticDisplay *theInstance;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		theInstance = [[UKDiacriticDisplay alloc] init];
	});
	return theInstance;
}

- (NSString *)diacriticForIndex:(NSUInteger)index {
	return diacriticList[index];
}

- (NSString *)textForIndex:(NSUInteger)index {
	return textList[index];
}

- (NSUInteger)indexForDiacritic:(UniChar)diacritic {
	NSUInteger index = 0;
	switch (diacritic) {
		case kWhiteSquareUnicode:
			index = UKDiacriticSquare;
			break;
			
		case kDottedSquareUnicode:
			index = UKDiacriticDottedSquare;
			break;
			
		case kWhiteCircleUnicode:
			index = UKDiacriticCircle;
			break;
			
		case kDottedCircleUnicode:
			index = UKDiacriticDottedCircle;
			break;
			
		case ' ':
			index = UKDiacriticSpace;
			break;
	}
	return index;
}

@end

//
//  MathsUtilities.mm
//  Ukelele 3
//
//  Created by John Brownie on 23/02/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "MathsUtilities.h"
#import "NMathUtilities.h"

@implementation MathsUtilities

+ (BOOL)number:(float)number1 isEqualTo:(float)number2
{
	return NMathUtilities::AreEqual(number1, number2);
}

+ (BOOL)isZero:(float)value
{
	return NMathUtilities::IsZero(value);
}

+ (BOOL)isOdd:(int)value
{
	return NMathUtilities::IsOdd(value);
}

+ (BOOL)isEven:(int)value
{
	return NMathUtilities::IsEven(value);
}

+ (BOOL)isPowerOf2:(int)value
{
	return NMathUtilities::IsPowerOf2(value);
}

+ (int)countBits:(int)value
{
	return NMathUtilities::CountBits(value);
}

@end

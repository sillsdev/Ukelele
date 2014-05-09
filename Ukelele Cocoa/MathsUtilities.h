//
//  MathsUtilities.h
//  Ukelele 3
//
//  Created by John Brownie on 23/02/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MathsUtilities : NSObject {
}

+ (BOOL)number:(float)number1 isEqualTo:(float)number2;
+ (BOOL)isZero:(float)value;
+ (BOOL)isOdd:(int)value;
+ (BOOL)isEven:(int)value;
+ (BOOL)isPowerOf2:(int)value;
+ (int)countBits:(int)value;

@end

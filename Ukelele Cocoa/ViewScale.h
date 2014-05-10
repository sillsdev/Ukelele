//
//  ViewScale.h
//  Ukelele 3
//
//  Created by John Brownie on 23/02/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ViewScale : NSObject

@property (readwrite, copy) NSString *scaleLabel;
@property (readwrite) float scaleValue;

+ (ViewScale *)createWithLabel:(NSString *)label value:(float)value;
+ (NSMutableArray *)standardScales;

@end

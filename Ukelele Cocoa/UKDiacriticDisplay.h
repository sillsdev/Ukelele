//
//  UKDiacriticDisplay.h
//  Ukelele Cocoa
//
//  Created by John Brownie on 5/05/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UKDiacriticDisplay : NSObject

+ (UKDiacriticDisplay *)getInstance;

- (NSString *)diacriticForIndex:(NSUInteger)index;
- (NSString *)textForIndex:(NSUInteger)index;
- (NSUInteger)indexForDiacritic:(UniChar)diacritic;

@end

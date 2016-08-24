//
//  UKStyleInfo.h
//  Ukelele
//
//  Created by John Brownie on 8/08/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UKStyleInfo : NSObject

@property (nonatomic) CGFloat scaleFactor;
@property (strong, nonatomic) NSDictionary *largeAttributes;
@property (strong, nonatomic) NSDictionary *smallAttributes;
@property (strong, nonatomic) NSFont *largeFont;

- (void)setUpStyles;
- (void)changeLargeFont:(NSFont *)newFont;

@end

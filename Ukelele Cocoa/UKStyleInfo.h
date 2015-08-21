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
@property (assign, nonatomic) CTFontDescriptorRef fontDescriptor;
@property (assign, nonatomic) CTParagraphStyleRef largeParagraphStyle;
@property (assign, nonatomic) CTParagraphStyleRef smallParagraphStyle;
@property (strong, nonatomic) NSDictionary *largeAttributes;
@property (strong, nonatomic) NSDictionary *smallAttributes;
@property (assign, nonatomic) CTFontRef largeFont;
@property (assign, nonatomic) CTFontRef smallFont;

- (void)setUpStyles;
- (void)changeLargeFont:(NSFont *)newFont;

@end

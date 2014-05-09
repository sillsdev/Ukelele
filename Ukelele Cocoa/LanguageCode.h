//
//  LanguageCode.h
//  Ukelele 3
//
//  Created by John Brownie on 25/10/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LanguageCode : NSObject

@property (copy) NSString *languageCode;
@property (copy) NSString *scriptCode;
@property (copy) NSString *regionCode;
@property (copy) NSString *variantCode;

+ (LanguageCode *)languageCodeFromString:(NSString *)languageString;

- (NSString *)stringRepresentation;

@end

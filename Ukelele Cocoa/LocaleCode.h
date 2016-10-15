//
//  LocaleCode.h
//  Ukelele
//
//  Created by John Brownie on 14/10/16.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LocaleCode : NSObject

@property (copy) NSString *languageCode;
@property (copy) NSString *scriptCode;
@property (copy) NSString *regionCode;
@property (copy, readonly) NSString *stringRepresentation;

+ (LocaleCode *)localeCodeFromString:(NSString *)languageString;

@end

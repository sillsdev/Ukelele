//
//  LanguageRegistry.h
//  Ukelele 3
//
//  Created by John Brownie on 15/10/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LanguageCode.h"
#import "LocaleCode.h"

@interface LanguageRegistryEntry : NSObject

@property (copy) NSString *code;
@property (copy) NSString *name;
@property (copy) NSString *other;

@end

@interface LanguageRegistry : NSObject

@property (weak, readonly) NSArray *languageList;
@property (weak, readonly) NSArray *scriptList;
@property (weak, readonly) NSArray *regionList;
@property (weak, readonly) NSArray *variantList;

+ (LanguageRegistry *)getInstance;

- (NSArray *)searchLanguage:(NSString *)searchTerm;
- (NSArray *)searchScript:(NSString *)searchTerm;
- (NSArray *)searchRegion:(NSString *)searchTerm;
- (NSArray *)searchVariant:(NSString *)searchTerm;

- (LanguageCode *)normaliseLanguageCode:(LanguageCode *)originalCode;
- (NSString *)descriptionForLocaleCode:(LocaleCode *)localeCode;

@end

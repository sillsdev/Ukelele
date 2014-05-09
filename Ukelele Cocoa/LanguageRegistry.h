//
//  LanguageRegistry.h
//  Ukelele 3
//
//  Created by John Brownie on 15/10/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LanguageCode.h"

@interface LanguageRegistryEntry : NSObject

@property (copy) NSString *code;
@property (copy) NSString *name;
@property (copy) NSString *other;

@end

@interface LanguageRegistry : NSObject

@property (readonly) NSArray *languageList;
@property (readonly) NSArray *scriptList;
@property (readonly) NSArray *regionList;
@property (readonly) NSArray *variantList;

+ (LanguageRegistry *)getInstance;

- (NSArray *)searchLanguage:(NSString *)searchTerm;
- (NSArray *)searchScript:(NSString *)searchTerm;
- (NSArray *)searchRegion:(NSString *)searchTerm;
- (NSArray *)searchVariant:(NSString *)searchTerm;

- (LanguageCode *)normaliseLanguageCode:(LanguageCode *)originalCode;

@end

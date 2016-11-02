//
//  LocalisationData.h
//  Ukelele
//
//  Created by John Brownie on 2/11/16.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocaleCode.h"

@interface LocalisationData : NSObject

@property (strong) LocaleCode *localeCode;
@property (strong) NSMutableDictionary *localisationStrings;
@property (readonly) NSString *localeString;
@property (readonly) NSString *localeDescription;

@end

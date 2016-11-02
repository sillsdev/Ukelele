//
//  LocalisationData.m
//  Ukelele
//
//  Created by John Brownie on 2/11/16.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#import "LocalisationData.h"
#import "LanguageRegistry.h"

@implementation LocalisationData

- (instancetype)init {
	if (self = [super init]) {
		_localeCode = nil;
		_localisationStrings = [NSMutableDictionary dictionary];
	}
	return self;
}

- (NSString *)localeString {
	if (self.localeCode == nil) {
		return @"";
	}
	return [self.localeCode stringRepresentation];
}

- (NSString *)localeDescription {
	if (self.localeCode == nil) {
		return @"";
	}
	LanguageRegistry *theRegistry = [LanguageRegistry getInstance];
	return [theRegistry descriptionForLocaleCode:self.localeCode];
}

@end

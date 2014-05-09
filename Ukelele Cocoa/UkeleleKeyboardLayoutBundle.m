//
//  UkeleleKeyboardLayoutBundle.m
//  Ukelele 3
//
//  Created by John Brownie on 9/10/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "UkeleleKeyboardLayoutBundle.h"

@interface UkeleleKeyboardLayoutBundle()


@end

@implementation UkeleleKeyboardLayoutBundle

@synthesize keyboardLayouts;
@synthesize bundleName;

- (id)init {
	self = [super init];
	if (self) {
		keyboardLayouts = [[NSMutableArray array] retain];
		infoPlist = [[NSMutableDictionary dictionary] retain];
		languageList = [[NSMutableDictionary dictionary] retain];
		bundleName = @"";
		bundleVersion = @"";
		buildVersion = @"";
		sourceVersion = @"";
	}
	return self;
}

- (void)dealloc {
	[keyboardLayouts release];
	[infoPlist release];
	[languageList release];
	[bundleName release];
	[buildVersion release];
	[buildVersion release];
	[sourceVersion release];
	[super dealloc];
}

#pragma mark Basic operations

- (void)insertKeyboardLayout:(NSDictionary *)keyboardInfo atIndex:(NSUInteger)index {
	
}

- (void)removeKeyboardLayoutAtIndex:(NSUInteger)index {
	
}

- (void)setKeyboardLanguage:(NSString *)languageID forIndex:(NSUInteger)index {
	
}

- (void)setBundleVersion:(NSString *)versionString buildVersion:(NSString *)buildString sourceVersion:(NSString *)sourceString {
	
}

#pragma mark Derived operations

- (void)addNewKeyboardLayout {
	
}

@end

//
//  UkeleleKeyboardLayoutBundle.h
//  Ukelele 3
//
//  Created by John Brownie on 9/10/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UkeleleKeyboardLayoutBundle : NSObject {
	NSMutableArray *keyboardLayouts;
	NSMutableDictionary *infoPlist;
	NSMutableDictionary *languageList;
	NSString *bundleName;
	NSString *bundleVersion;
	NSString *buildVersion;
	NSString *sourceVersion;
}

@property (readonly) NSArray *keyboardLayouts;
@property (copy) NSString *bundleName;


	// Basic operations: add/remove keyboard layout, modify properties
- (void)insertKeyboardLayout:(NSDictionary *)keyboardInfo atIndex:(NSUInteger)index;
- (void)removeKeyboardLayoutAtIndex:(NSUInteger)index;
- (void)setKeyboardLanguage:(NSString *)languageID forIndex:(NSUInteger)index;
- (void)setBundleVersion:(NSString *)versionString buildVersion:(NSString *)buildString sourceVersion:(NSString *)sourceString;

	// Derived operations
- (void)addNewKeyboardLayout;

@end

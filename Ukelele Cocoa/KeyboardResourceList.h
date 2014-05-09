//
//  KeyboardResourceList.h
//  Ukelele 3
//
//  Created by John Brownie on 29/02/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

	// Dictionary keys
extern NSString *kKeyNameIndex;
extern NSString *kKeyCodingIndex;

@interface KeyboardType : NSObject

@property (copy) NSString *keyboardName;
@property (copy) NSString *keyboardDescription;
@property (strong) NSArray *keyboardCodings;
@property (strong) NSArray *keyboardResourceIDs;

+ (KeyboardType *)keyboardTypeName:(NSString *)theName withDescription:(NSString *)theDescription withCodings:(NSArray *)theCodings withIDs:(NSArray *)theIDs;

@end

@interface KeyboardResourceList : NSObject

@property (strong) NSArray *keyboardTypeTable;

+ (KeyboardResourceList *)getInstance;

- (NSInteger)resourceForType:(NSInteger)typeIndex code:(NSInteger)codeIndex;
- (NSDictionary *)indicesForResourceID:(NSInteger)resourceID;
- (NSArray *)namesList;
- (NSArray *)descriptionsList;
- (NSArray *)codingsForType:(NSInteger)typeIndex;

@end

//
//  ScriptInfo.h
//  Ukelele 3
//
//  Created by John Brownie on 1/08/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kScriptCount 8

@interface ScriptInfo : NSObject

@property (strong, readonly) NSString *scriptName;
@property (readonly) NSInteger scriptID;
@property (readonly) NSInteger minID;
@property (readonly) NSInteger maxID;
@property (strong, readonly) NSString *scriptDescription;

- (instancetype)initWithName:(NSString *)theName scriptID:(NSInteger)ID minID:(NSInteger)minimumID maxID:(NSInteger)maximumID description:(NSString *)description NS_DESIGNATED_INITIALIZER;

+ (NSArray *)standardScripts;
+ (NSInteger)randomIDforScript:(NSInteger)scriptID;
+ (NSInteger)indexForScript:(NSInteger)scriptID;

@property (NS_NONATOMIC_IOSONLY, readonly) NSInteger randomID;

@end

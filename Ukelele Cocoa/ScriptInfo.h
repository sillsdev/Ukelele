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

- (id)initWithName:(NSString *)theName scriptID:(NSInteger)ID minID:(NSInteger)minimumID maxID:(NSInteger)maximumID;

+ (NSArray *)standardScripts;
+ (NSInteger)randomIDforScript:(NSInteger)scriptID;
+ (NSInteger)indexForScript:(NSInteger)scriptID;

- (NSInteger)randomID;

@end

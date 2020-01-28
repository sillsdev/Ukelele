//
//  UKFileUtilities.h
//  Ukelele
//
//  Created by John Brownie on 3/1/17.
//  Copyright © 2017 John Brownie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UKFileUtilities : NSObject

+ (BOOL)isKeyboardLayoutsURL:(NSURL *)fileURL;
+ (BOOL)dataIsicns:(NSData *)icnsData;
+ (NSURL *)userLibrary;

@end

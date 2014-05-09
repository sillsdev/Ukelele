//
//  XMLCocoaUtilities.h
//  Ukelele 3
//
//  Created by John Brownie on 4/02/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface XMLCocoaUtilities : NSObject

+ (BOOL)isValidUnicode:(unsigned int)codePoint withError:(NSString **)errorMessage;
+ (BOOL)isCombiningDiacritic:(unsigned int)codePoint;
+ (NSString *)createCanonicalForm:(NSString *)inputString;
+ (NSString *)makeXMLString:(NSString *)inputString codingNonAscii:(BOOL)codeNonAscii;
+ (NSString *)convertEncodedString:(NSString *)inputString;
+ (NSString *)convertToXMLString:(NSString *)inputString;
+ (NSString *)makeXMLName:(NSString *)inputString;

@end

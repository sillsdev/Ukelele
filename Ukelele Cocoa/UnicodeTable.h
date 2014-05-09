//
//  UnicodeTable.h
//  Ukelele 3
//
//  Created by John Brownie on 14/02/13.
//
//

#import <Foundation/Foundation.h>

@interface UnicodeTable : NSObject

+ (UnicodeTable *)getInstance;
+ (void)setup;

- (NSString *)descriptionForCodePoint:(NSInteger)codePoint;

@end

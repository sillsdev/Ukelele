//
//  UKMenuDelegate.h
//  Ukelele 3
//
//  Created by John Brownie on 27/08/13.
//
//

#import <Cocoa/Cocoa.h>

@protocol UKMenuDelegate <NSObject>

- (NSMenu *)contextualMenuForData:(NSDictionary *)dataDict;

@end

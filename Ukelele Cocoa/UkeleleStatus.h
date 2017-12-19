//
//  UkeleleStatus.h
//  Ukelele
//
//  Created by John Brownie on 20/12/17.
//  Copyright © 2017 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UkeleleStatus : NSObject

@property (strong) NSString *stateName;
@property (strong) NSString *keyboardType;
@property (strong) NSString *keyboardCoding;
@property (nonatomic) NSInteger modifierIndex;

- (NSString *)statusString;

@end

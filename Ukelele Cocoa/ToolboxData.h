//
//  ToolboxData.h
//  Ukelele 3
//
//  Created by John Brownie on 26/12/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ToolboxData : NSObject

@property (nonatomic) BOOL stickyModifiers;
@property (nonatomic) BOOL JISOnly;

+ (ToolboxData *)sharedToolboxData;

@end

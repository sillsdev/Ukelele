//
//  ActionElementSetWrapper.h
//  Ukelele 3
//
//  Created by John Brownie on 14/06/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifdef __cplusplus
#include "ActionElementSetHolder.h"
#else
typedef void *ActionElementSetHolder;
#endif

@interface ActionElementSetWrapper : NSObject

@property (assign) ActionElementSetHolder *actionElements;

@end

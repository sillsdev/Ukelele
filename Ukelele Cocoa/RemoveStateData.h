//
//  RemoveStateData.h
//  Ukelele 3
//
//  Created by John Brownie on 12/06/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifdef __cplusplus
#include "RemoveStateDataBlock.h"
#else
typedef void *RemoveStateDataBlock;
#endif

@interface RemoveStateData : NSObject

@property (assign) RemoveStateDataBlock *dataBlock;

@end

//
//  AddMissingOutputData.h
//  Ukelele 3
//
//  Created by John Brownie on 30/07/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifdef __cplusplus
#include "AddMissingOutputDataBlock.h"
#else
typedef void *AddMissingOutputDataBlock;
#endif

@interface AddMissingOutputData : NSObject

@property (assign) AddMissingOutputDataBlock *dataBlock;

@end

//
//  KeyboardTypeController.h
//  Ukelele 3
//
//  Created by John Brownie on 2/03/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KeyboardResourceList.h"

@interface KeyboardTypeController : NSArrayController {
	KeyboardResourceList *resourceList;
	NSArray *namesList;
}

@property (readonly) KeyboardResourceList *resourceList;
@property (readonly) NSArray *namesList;

- (NSUInteger)countOfResourceList;
- (id)objectInResourceListAtIndex:(NSUInteger)index;

@end

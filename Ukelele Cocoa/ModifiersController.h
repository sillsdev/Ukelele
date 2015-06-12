//
//  ModifiersController.h
//  Ukelele 3
//
//  Created by John Brownie on 15/02/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KeyCapView.h"

@interface ModifiersController : NSObject {
#if defined(__cplusplus)
	std::vector<KeyCapView *> shiftKeys;
	std::vector<KeyCapView *> optionKeys;
	std::vector<KeyCapView *> controlKeys;
	std::vector<KeyCapView *> commandKeys;
	std::vector<KeyCapView *> capsLockKeys;
	std::vector<KeyCapView *> fnKeys;
#endif
}

- (void)addModifier:(KeyCapView *)inKeyCap;
- (void)updateModifiers:(unsigned int)modifierCombination;
- (void)clearController;

@end

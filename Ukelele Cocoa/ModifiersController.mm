//
//  ModifiersController.mm
//  Ukelele 3
//
//  Created by John Brownie on 15/02/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "ModifiersController.h"
#import "KeyboardDefinitions.h"

@implementation ModifiersController

- (void)addModifier:(KeyCapView *)inKeyCap
{
	switch ([inKeyCap keyCode]) {
		case kKeyShift:
			shiftKeys.push_back(inKeyCap);
			break;
			
		case kKeyOption:
			optionKeys.push_back(inKeyCap);
			break;
			
		case kKeyControl:
			controlKeys.push_back(inKeyCap);
			break;
			
		case kKeyCapsLock:
			capsLockKeys.push_back(inKeyCap);
			break;
			
		case kKeyCommand:
			commandKeys.push_back(inKeyCap);
			break;
			
		case kKeyFn:
			fnKeys.push_back(inKeyCap);
			break;
	}
}

- (void)updateModifiers:(unsigned int)modifierCombination
{
	BOOL keyState;
	std::vector<KeyCapView *>::iterator pos;
	KeyCapView *keyCap;
		// Shift
	keyState = (modifierCombination & NSShiftKeyMask) != 0;
	for (pos = shiftKeys.begin(); pos != shiftKeys.end(); ++pos) {
		keyCap = *pos;
		[keyCap setDown:keyState];
	}
		// Option
	keyState = (modifierCombination & NSAlternateKeyMask) != 0;
	for (pos = optionKeys.begin(); pos != optionKeys.end(); ++pos) {
		keyCap = *pos;
		[keyCap setDown:keyState];
	}
		// Control
	keyState = (modifierCombination & NSControlKeyMask) != 0;
	for (pos = controlKeys.begin(); pos != controlKeys.end(); ++pos) {
		keyCap = *pos;
		[keyCap setDown:keyState];
	}
		// Caps lock
	keyState = (modifierCombination & NSAlphaShiftKeyMask) != 0;
	for (pos = capsLockKeys.begin(); pos != capsLockKeys.end(); ++pos) {
		keyCap = *pos;
		[keyCap setDown:keyState];
	}
		// Command
	keyState = (modifierCombination & NSCommandKeyMask) != 0;
	for (pos = commandKeys.begin(); pos != commandKeys.end(); ++pos) {
		keyCap = *pos;
		[keyCap setDown:keyState];
	}
		// Fn
	keyState = (modifierCombination & NSNumericPadKeyMask) != 0;
	for (pos = fnKeys.begin(); pos != fnKeys.end(); ++pos) {
		keyCap = *pos;
		[keyCap setDown:keyState];
	}
}

- (void)clearController
{
	shiftKeys.clear();
	optionKeys.clear();
	controlKeys.clear();
	commandKeys.clear();
	capsLockKeys.clear();
	fnKeys.clear();
}

@end

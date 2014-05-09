/*
 *  ModifierConstants.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 18/05/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

	// Constants for key status
enum {
	kModifierNotPressed = 1,
	kModifierPressed = 2,
	kModifierEither = 3
};

	// Bit position constants
enum {
	kModifierNone = 0x4,
	kModifierRight = 0x8,
	kModifierLeft = 0x10,
	kModifierLeftRight = 0x20,
	kModifierRightOpt = 0xc,
	kModifierLeftOpt = 0x14,
	kModifierLeftOptRight = 0x28,
	kModifierLeftRightOpt = 0x30,
	kModifierAny = 0x38,
	kModifierAnyOpt = 0x3c
};

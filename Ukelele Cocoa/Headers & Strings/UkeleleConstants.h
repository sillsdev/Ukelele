/*
 *  UkeleleConstants.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 15/01/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _UkeleleConstants_h_
#define _UkeleleConstants_h_

typedef void (^UKSheetCompletionBlock) (id);

	// Types of state search
enum {
	kAllStates,
	kReachableStates
};

	// Action types
enum {
	kOutputType,
	kStateType,
	kTerminatorType
};

	// Resource type
#define kResType_uchr 'uchr'

	// Default modifiers
enum {
	kStandardDefaultIndex = 0,
	kNumBasicModifiers = 5,
	kNumStandardModifiers = 9,
	kLowerCaseModifiers = 0,
	kUpperCaseModifiers = 1,
	kOptionModifiers = 2,
	kCapsLockModifiers = 3,
	kOptionShiftModifiers = 4,
	kCommandModifiers = 5,
	kCommandShiftModifiers = 6,
	kCapsLockShiftModifiers = 7,
	kControlModifiers = 8
};

	// Standard keyboard types

enum {
	kStandardKeyMapqwerty = 0,
	kStandardKeyMapQWERTY = 1,
	kStandardKeyMapDvorackLower = 2,
	kStandardKeyMapDvorackUpper = 3,
	kStandardKeyMapazerty = 4,
	kStandardKeyMapAZERTY = 5,
	kStandardKeyMapqwertz = 6,
	kStandardKeyMapQWERTZ = 7,
	kStandardKeyMapColemakLower = 8,
	kStandardKeyMapColemakUpper = 9
};

enum {
	kStandardLayoutEmpty = 0,
	kStandardLayoutQWERTY = 1,
	kStandardLayoutDvorak = 2,
	kStandardLayoutAZERTY = 3,
	kStandardLayoutQWERTZ = 4,
	kStandardLayoutColemak = 5,
	kStandardLayoutNone = 999
};

	// Special key codes
enum {
	kNoKeyCode = 999,
	kMinKeyCode = 0,
	kMaxKeyCode = 511
};

	// Unicode code points for symbols
enum {
	kUpArrowUnicode				= 0x2191,
	kDownArrowUnicode			= 0x2193,
	kDashedUpArrowUnicode		= 0x21e1,
	kDashedDownArrowUnicode		= 0x21e3,
	kRightArrowUnicode			= 0x21e2,
	kLeftArrowUnicode			= 0x21e0,
	kTabUnicode					= 0x21e5,
	kBackTabUnicode				= 0x21e4,
	kDeleteUnicode				= 0x232b,
	kForwardDeleteUnicode		= 0x2326,
	kReturnUnicode				= 0x21a9,
	kCapsLockUnicode			= 0x21ea,
	kEnterUnicode				= 0x2324,
	kDoubleArrowLeftUnicode		= 0x219e,
	kDoubleArrowUpUnicode		= 0x219f,
	kDoubleArrowRightUnicode	= 0x21a0,
	kDoubleArrowDownUnicode		= 0x21a1,
	kNorthWestArrowUnicode		= 0x2196,
	kSouthEastArrowUnicode		= 0x2198,
	kClearUnicode				= 0x2327,
	kPageUpUnicode				= 0x21de,
	kPageDownUnicode			= 0x21df,
	kDottedCircleUnicode		= 0x25cc,
	kDottedSquareUnicode		= 0x2b1a,
	kMediumVerticalBarUnicode	= 0x2759,
	kWhiteSquareUnicode			= 0x25a1,
	kWhiteSmallSquareUnicode	= 0x25ab,
	kWhiteCircleUnicode			= 0x25cb,
	kWhiteVerticalRectangleUnicode = 0x25af,
	kSpaceUnicode				= 0x20,
	kEscapeUnicode				= 0x241b,
	kJapaneseLeft1Unicode		= 0x82f1,
	kJapaneseLeft2Unicode		= 0x6570,
	kKatakanaKaUnicode			= 0x30ab,
	kKatakanaNaUnicode			= 0x30ca
};

	// Default font sizes
#define kDefaultLargeFontSize	18.0
#define kDefaultSmallFontSize	12.0

	// String files
#define kErrorTableName											"Errors"
#define kDialogsTableName										"dialogs"
#define kKeyboardTableName										"keyboards"

	// Local versions of Carbon modifier constants
enum {
	/* modifiers */
	UKCmdKeyBit                     = 8,    /* command key down?*/
	UKShiftKeyBit                   = 9,    /* shift key down?*/
	UKAlphaLockBit                  = 10,   /* alpha lock down?*/
	UKOptionKeyBit                  = 11,   /* option key down?*/
	UKControlKeyBit                 = 12,   /* control key down?*/
	UKRightShiftKeyBit              = 13,   /* right shift key down? Not supported on Mac OS X.*/
	UKRightOptionKeyBit             = 14,   /* right Option key down? Not supported on Mac OS X.*/
	UKRightControlKeyBit            = 15    /* right Control key down? Not supported on Mac OS X.*/
};

enum {
	UKCmdKey                        = 1 << UKCmdKeyBit,
	UKShiftKey                      = 1 << UKShiftKeyBit,
	UKAlphaLock                     = 1 << UKAlphaLockBit,
	UKOptionKey                     = 1 << UKOptionKeyBit,
	UKControlKey                    = 1 << UKControlKeyBit,
	UKRightShiftKey                 = 1 << UKRightShiftKeyBit, /* Not supported on Mac OS X.*/
	UKRightOptionKey                = 1 << UKRightOptionKeyBit, /* Not supported on Mac OS X.*/
	UKRightControlKey               = 1 << UKRightControlKeyBit /* Not supported on Mac OS X.*/
};

	// Diacritic display constants

enum {
	UKDiacriticSquare = 0,
	UKDiacriticDottedSquare = 1,
	UKDiacriticCircle = 2,
	UKDiacriticDottedCircle = 3,
	UKDiacriticSpace = 4
};

#endif

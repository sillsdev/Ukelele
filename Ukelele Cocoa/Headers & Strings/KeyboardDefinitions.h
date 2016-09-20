/*
 *  KeyboardDefinitions.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 13/01/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

enum {
	kModifierKeyType,
	kSpecialKeyType,
	kOrdinaryKeyType,
	kProtectedKeyType
};

	// Constants for various key codes that we'll be needing

enum eKeyNameSymbols {
	kKeyPad0 = 82,			// Keypad keys
	kKeyPad1 = 83,
	kKeyPad2 = 84,
	kKeyPad3 = 85,
	kKeyPad4 = 86,
	kKeyPad5 = 87,
	kKeyPad6 = 88,
	kKeyPad7 = 89,
	kKeyPad8 = 91,
	kKeyPad9 = 92,
	kKeyPadClear = 71,
	kKeyPadEquals = 81,
	kKeyPadSlash = 75,
	kKeyPadStar = 67,
	kKeyPadMinus = 78,
	kKeyPadPlus = 69,
	kKeyPadDot = 65,
	kKeyPadEnter = 76,
	kKeyBackTick = 50,
	kKey1 = 18,
	kKey2 = 19,
	kKey3 = 20,
	kKey4 = 21,
	kKey5 = 23,
	kKey6 = 22,				// Main keyboard keys forming embedded keypad
	kKey7 = 26,
	kKey8 = 28,
	kKey9 = 25,
	kKey0 = 29,
	kKeyMinus = 27,
	kKeyEquals = 24,
	kKeySpace = 49,
	kKeyA = 0,
	kKeyB = 11,
	kKeyC = 8,
	kKeyD = 2,
	kKeyE = 14,
	kKeyF = 3,
	kKeyG = 5,
	kKeyH = 4,
	kKeyI = 34,
	kKeyJ = 38,
	kKeyK = 40,
	kKeyL = 37,
	kKeyM = 46,
	kKeyN = 45,
	kKeyO = 31,
	kKeyP = 35,
	kKeyQ = 12,
	kKeyR = 15,
	kKeyS = 1,
	kKeyT = 17,
	kKeyU = 32,
	kKeyV = 9,
	kKeyW = 13,
	kKeyX = 7,
	kKeyY = 16,
	kKeyZ = 6,
	kKeyOpenBracket = 33,
	kKeyCloseBracket = 30,
	kKeyBackslash = 42,
	kKeySemicolon = 41,
	kKeyQuote = 39,
	kKeyComma = 43,
	kKeyDot = 47,
	kKeySlash = 44,
	kKeyReturn = 36,		// Return becomes Enter on embedded keypad
	kKeyTab = 48,
	kKeyDelete = 51,
	kKeyEnter = 76,
	kKeyEscape = 53,
	kKeyClear = 71,
	kKeyLeftArrow = 123,	// Arrow keys
	kKeyRightArrow = 124,
	kKeyUpArrow = 126,
	kKeyDownArrow = 125,
	kKeyF1 = 122,			// Function keys
	kKeyF2 = 120,
	kKeyF3 = 99,
	kKeyF4 = 118,
	kKeyF5 = 96,
	kKeyF6 = 97,
	kKeyF7 = 98,
	kKeyF8 = 100,
	kKeyF9 = 101,
	kKeyF10 = 109,
	kKeyF11 = 103,
	kKeyF12 = 111,
	kKeyF13 = 105,
	kKeyF14 = 107,
	kKeyF15 = 113,
	kKeyF16 = 106,
	kKeyF17 = 64,
	kKeyF18 = 79,
	kKeyF19 = 80,
	kKeyHelp = 114,			// Navigation keys
	kKeyHome = 115,
	kKeyPageUp = 116,
	kKeyForwardDelete = 117,
	kKeyEnd = 119,
	kKeyPageDown = 121,
	kKeyCapsLock = 57,		// Modifier keys
	kKeyShift = 56,
	kKeyRightShift = 60,
	kKeyControl = 59,
	kKeyRightControl = 62,
	kKeyOption = 58,
	kKeyRightOption = 61,
	kKeyCommand = 55,
	kKeyRightCommand = 257,
	kKeyFn = 63,
	kKeyJapaneseConversionLeft = 102,	// Extra keys on Japanese keyboards
	kKeyJapaneseConversionRight = 104
};

	// Constants describing what layout types are available for keyboards

enum eKeyboardTypeList {
	kKeyboardTypeUniversal = 1,
	kKeyboardTypeANSI = 2,
	kKeyboardTypeISO = 4,
	kKeyboardTypeJIS = 8
};

enum eKeyboardAvailableTypes {
	kNoKeyboard = 0,
	kSingleCodeKeyboard = 1,
	kANSIOnlyKeyboard = 2,
	kISOOnlyKeyboard = 3,
	kJISOnlyKeyboard = 4,
	kANSIISOKeyboard = 5,
	kANSIJISKeyboard = 6,
	kISOJISKeyboard = 7,
	kANSIISOJISKeyboard = 8,
	kNumKeyboardTypes = 8
};

	// Condensed list of keyboard types

enum eKeyboardTypesCondensed {
	kKeyboardOriginalMac = 1,
	kKeyboardOriginalMacPad = 2,
	kKeyboardMacPlus = 3,
	kKeyboardStandardADB = 4,
	kKeyboardExtendedADB = 5,
	kKeyboardPortableADB = 6,
	kKeyboardADBII = 7,
	kKeyboardPowerBookADB = 8,
	kKeyboardAdjustablePad = 9,
	kKeyboardAdjustable = 10,
	kKeyboardPowerBookExtended = 11,
	kKeyboardSubnote = 12,
	kKeyboardPowerBookKeypad = 13,
	kKeyboardCosmo = 14,
	kKeyboard1999Japanese = 15,
	kKeyboardUSBPro = 16,
	kKeyboardPowerBook2ndCmd = 17,
	kKeyboardUSBProF16 = 18,
	kKeyboardProF16 = 19,
	kKeyboardPS2 = 20,
	kKeyboardPowerBookUSB = 21,
	kKeyboardThirdParty = 22,
	kKeyboardWirelessAluminium = 23,
	kKeyboardAluminium = 24,
	kKeyboardMacBookLate2007 = 25
};

	// Gestalt constants not in 10.4.10

enum {
	kGestaltAppleWirelessANSIKbd = 43,	/* Aluminium Apple Wireless Keyboard */
	kGestaltAppleWirelessISOKbd = 44,
	kGestaltAppleWirelessJISKbd = 45,
	kGestaltAppleANSIKbd = 46,	/* Aluminium Apple Keyboard */
	kGestaltAppleISOKbd = 47,
	kGestaltAppleJISKbd = 48,
	kGestaltMacBookLate2007ANSIkbd = 1202,	/* MacBook (Late 2007) */
	kGestaltMacBookLate2007ISOkbd = 1203,
	kGestaltMacBookLate2007JISkbd = 1207
};

enum eKeyboardTypesCondensedSupplement {
	kAdjustableJISkbd = 18
};

enum {
	kKeyCodeTableSize = 128,
	kKeyboardLayoutCount = 25,
	kSpecialKeyCount = 40
};

typedef struct {
	SInt16 all;
	SInt16 ANSI;
	SInt16 ISO;
	SInt16 JIS;
} KeyboardListType;

	// Keyboard description strings
enum {
	kOriginalMacDesc = 1,
	kOriginalMacPadDesc,
	kMacPlusDesc,
	kStandardADBDesc,
	kExtendedADBDesc,
	kPortableADBDesc,
	kADBIIDesc,
	kPowerBookADBDesc,
	kAdjustableKeypadDesc,
	kAdjustableDesc,
	kPowerBookExtendedDesc,
	kSubnoteDesc,
	kPowerBookKeypadDesc,
	kCosmoDesc,
	k1999JapaneseDesc,
	kUSBProDesc,
	kPowerBook2ndCmdDesc,
	kUSBProF16Desc,
	kProF16Desc,
	kPS2Desc,
	kPowerBookUSBDesc,
	kThirdPartyDesc,
	kAppleWirelessDesc,
	kAppleAluminiumDesc,
	kMacBookLate2007Desc,
	kUnknown18Desc,
	kUnknownDesc
};

enum eStandardKeyMapTypes {
	kStandardKeyMapEmpty = 1,
	kStandardKeyMapQWERTYLowerCase = 2,
	kStandardKeyMapQWERTYUpperCase = 3,
	kStandardKeyMapQWERTYCapsLock = 4,
	kStandardKeyMapDvorakLowerCase = 5,
	kStandardKeyMapDvorakUpperCase = 6,
	kStandardKeyMapDvorakCapsLock = 7,
	kStandardKeyMapAZERTYLowerCase = 8,
	kStandardKeyMapAZERTYUpperCase = 9,
	kStandardKeyMapAZERTYCapsLock = 10,
	kStandardKeyMapQWERTZLowerCase = 11,
	kStandardKeyMapQWERTZUpperCase = 12,
	kStandardKeyMapQWERTZCapsLock = 13,
	kStandardKeyMapColemakLowerCase = 14,
	kStandardKeyMapColemakUpperCase = 15,
	kStandardKeyMapColemakCapsLock = 16,
	kStandardKeyMapColemakOptionLowerCase = 17,
	kStandardKeyMapColemakOptionUpperCase = 18,
	kStandardKeyMapMaximum = 18
};

typedef NS_ENUM(NSUInteger, eStandardKeyboardTypes) {
    kStandardKeyboardEmpty,
    kStandardKeyboardQWERTY,
    kStandardKeyboardQWERTZ,
	kStandardKeyboardAZERTY,
	kStandardKeyboardDvorak,
	kStandardKeyboardColemak
};

typedef NS_ENUM(NSUInteger, eStandardKeyMapIndex) {
    kStandardKeyMapLowerCase,
    kStandardKeyMapUpperCase,
    kStandardKeyMapCapsLock
};

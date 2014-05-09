//
//  LayoutInfo.m
//  Ukelele 3
//
//  Created by John Brownie on 13/01/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "LayoutInfo.h"
#import "UkeleleConstants.h"
#import "NString.h"
#include "boost/unordered_map.hpp"
#include "boost/scoped_array.hpp"
#include <tr1/array>
#include <map>
#include <vector>
#import "NCocoa.h"
#import "XMLUtilities.h"
#import "NBundle.h"
#import "UkeleleConstantStrings.h"

	// Constants
const unsigned int kHasFnKey = 1;
const unsigned int kHasEmbeddedKeypad = 2;
const unsigned int kHasSeparateRightKeys = 4;

static BOOL layoutInfoInitialised = NO;

	// Glyph codes
enum {
	kGlyphCodeF1 = 76,
	kGlyphCodeF2 = 77,
	kGlyphCodeF3 = 78,
	kGlyphCodeF4 = 79,
	kGlyphCodeF5 = 80,
	kGlyphCodeF6 = 81,
	kGlyphCodeF7 = 82,
	kGlyphCodeF8 = 83,
	kGlyphCodeF9 = 84,
	kGlyphCodeF10 = 85,
	kGlyphCodeF11 = 86,
	kGlyphCodeF12 = 87,
	kGlyphCodeF13 = 88,
	kGlyphCodeF14 = 89,
	kGlyphCodeF15 = 90,
	kGlyphCodeF16 = 99,
	kGlyphCodeF17 = 100,
	kGlyphCodeF18 = 101,
	kGlyphCodeF19 = 102,
	kGlyphCodeF20 = 103,
	kGlyphCodeEnter = 122,
	kGlyphCodeHelp = 16
};

	// Names of keyboard types
const NString kOriginalMacName = "OriginalMac";
const NString kOriginalMacKeypadName = "OriginalMacKeypad";
const NString kMacPlusName = "MacPlus";
const NString kExtendedADBName = "ExtendedADB";
const NString kStandardADBName = "StandardADB";
const NString kPortableADBName = "PortableADB";
const NString kADBIIName = "ADBII";
const NString kPowerBookADBName = "PowerBookADB";
const NString kAdjustableKeypadName = "AdjustableKeypad";
const NString kAdjustableKeyboardName = "AdjustableKeyboard";
const NString kPowerBookExtendedName = "PowerBookExtended";
const NString kPowerBookSubnotebookName = "PowerBookSubnotebook";
const NString kPowerBookEmbeddedKeypadName = "PowerBookEmbeddedKeypad";
const NString kOriginalUSBName = "OriginalUSB";
const NString kJapanese1999PowerBookName = "Japanese1999PowerBook";
const NString kUSBProName = "USBPro";
const NString kPowerBook2ndCmdKeyName = "PowerBook2ndCmdKey";
const NString kUSBProF16Name = "USBProF16";
const NString kProF16Name = "ProF16";
const NString kPS2KeyboardName = "PS2Keyboard";
const NString kPowerBookUSBInternalName = "PowerBookUSBInternal";
const NString kThirdPartyName = "ThirdParty";
const NString kAluminiumWirelessName = "AluminiumWireless";
const NString kAluminiumAppleName = "AluminiumApple";
const NString kMacBookLate2007Name = "MacBookLate2007";
const NString kUnnamedJIS18Name = "UnnamedJIS18";
const NString kUnknownName = "Unknown";

	// Descriptions of keyboard types
const NString kOriginalMacDescription = "OriginalMacDesc";
const NString kOriginalMacKeypadDescription = "OriginalMacKeypadDesc";
const NString kMacPlusDescription = "MacPlusDesc";
const NString kExtendedADBDescription = "ExtendedADBDesc";
const NString kStandardADBDescription = "StandardADBDesc";
const NString kPortableADBDescription = "PortableADBDesc";
const NString kADBIIDescription = "ADBIIDesc";
const NString kPowerBookADBDescription = "PowerBookADBDesc";
const NString kAdjustableKeypadDescription = "AdjustableKeypadDesc";
const NString kAdjustableKeyboardDescription = "AdjustableKeyboardDesc";
const NString kPowerBookExtendedDescription = "PowerBookExtendedDesc";
const NString kPowerBookSubnotebookDescription = "PowerBookSubnotebookDesc";
const NString kPowerBookEmbeddedKeypadDescription = "PowerBookEmbeddedKeypadDesc";
const NString kOriginalUSBDescription = "OriginalUSBDesc";
const NString kJapanese1999PowerBookDescription = "Japanese1999PowerBookDesc";
const NString kUSBProDescription = "USBProDesc";
const NString kPowerBook2ndCmdKeyDescription = "PowerBook2ndCmdKeyDesc";
const NString kUSBProF16Description = "USBProF16Desc";
const NString kProF16Description = "ProF16Desc";
const NString kPS2KeyboardDescription = "PS2KeyboardDesc";
const NString kPowerBookUSBInternalDescription = "PowerBookUSBInternalDesc";
const NString kThirdPartyDescription = "ThirdPartyDesc";
const NString kAluminiumWirelessDescription = "AluminiumWirelessDesc";
const NString kAluminiumAppleDescription = "AluminiumAppleDesc";
const NString kMacBookLate2007Description = "MacBookLate2007Desc";
const NString kUnnamedJIS18Description = "UnnamedJIS18Desc";
const NString kUnknownDescription = "UnknownDesc";

	// Static array of key code types

const UInt32 sKeyCodeTable[] = {
	kOrdinaryKeyType,	// [0]		A
	kOrdinaryKeyType,	// [1]		S
	kOrdinaryKeyType,	// [2]		D
	kOrdinaryKeyType,	// [3]		F
	kOrdinaryKeyType,	// [4]		H
	kOrdinaryKeyType,	// [5]		G
	kOrdinaryKeyType,	// [6]		Z
	kOrdinaryKeyType,	// [7]		X
	kOrdinaryKeyType,	// [8]		C
	kOrdinaryKeyType,	// [9]		V
	kOrdinaryKeyType,	// [10]		Section mark
	kOrdinaryKeyType,	// [11]		B
	kOrdinaryKeyType,	// [12]		Q
	kOrdinaryKeyType,	// [13]		W
	kOrdinaryKeyType,	// [14]		E
	kOrdinaryKeyType,	// [15]		R
	kOrdinaryKeyType,	// [16]		Y
	kOrdinaryKeyType,	// [17]		T
	kOrdinaryKeyType,	// [18]		1
	kOrdinaryKeyType,	// [19]		2
	kOrdinaryKeyType,	// [20]		3
	kOrdinaryKeyType,	// [21]		4
	kOrdinaryKeyType,	// [22]		6
	kOrdinaryKeyType,	// [23]		5
	kOrdinaryKeyType,	// [24]		=
	kOrdinaryKeyType,	// [25]		9
	kOrdinaryKeyType,	// [26]		7
	kOrdinaryKeyType,	// [27]		-
	kOrdinaryKeyType,	// [28]		8
	kOrdinaryKeyType,	// [29]		0
	kOrdinaryKeyType,	// [30]		]
	kOrdinaryKeyType,	// [31]		O
	kOrdinaryKeyType,	// [32]		U
	kOrdinaryKeyType,	// [33]		[
	kOrdinaryKeyType,	// [34]		I
	kOrdinaryKeyType,	// [35]		P
	kSpecialKeyType,	// [36]		Return
	kOrdinaryKeyType,	// [37]		L
	kOrdinaryKeyType,	// [38]		J
	kOrdinaryKeyType,	// [39]		'
	kOrdinaryKeyType,	// [40]		K
	kOrdinaryKeyType,	// [41]		;
	kOrdinaryKeyType,	// [42]		Backslash
	kOrdinaryKeyType,	// [43]		,
	kOrdinaryKeyType,	// [44]		/
	kOrdinaryKeyType,	// [45]		N
	kOrdinaryKeyType,	// [46]		M
	kOrdinaryKeyType,	// [47]		.
	kSpecialKeyType,	// [48]		Tab
	kOrdinaryKeyType,	// [49]		Space
	kOrdinaryKeyType,	// [50]		`
	kSpecialKeyType,	// [51]		Delete
	kSpecialKeyType,	// [52]		Unknown
	kSpecialKeyType,	// [53]		Escape
	kSpecialKeyType,	// [54]		Unknown
	kModifierKeyType,	// [55]		Command
	kModifierKeyType,	// [56]		Shift
	kModifierKeyType,	// [57]		Caps lock
	kModifierKeyType,	// [58]		Option
	kModifierKeyType,	// [59]		Control
	kModifierKeyType,	// [60]		Right shift
	kModifierKeyType,	// [61]		Right option
	kModifierKeyType,	// [62]		Right control
	kModifierKeyType,	// [63]		Fn
	kSpecialKeyType,	// [64]		F17
	kOrdinaryKeyType,	// [65]		Keypad .
	kSpecialKeyType,	// [66]		Unknown
	kOrdinaryKeyType,	// [67]		Keypad *
	kSpecialKeyType,	// [68]		Unknown
	kOrdinaryKeyType,	// [69]		Keypad +
	kSpecialKeyType,	// [70]		Unknown
	kOrdinaryKeyType,	// [71]		Clear
	kSpecialKeyType,	// [72]		Unknown
	kSpecialKeyType,	// [73]		Unknown
	kSpecialKeyType,	// [74]		Unknown
	kOrdinaryKeyType,	// [75]		Keypad /
	kSpecialKeyType,	// [76]		Enter
	kSpecialKeyType,	// [77]		Unknown
	kOrdinaryKeyType,	// [78]		Keypad -
	kSpecialKeyType,	// [79]		F18
	kSpecialKeyType,	// [80]		F19
	kOrdinaryKeyType,	// [81]		Keypad =
	kOrdinaryKeyType,	// [82]		Keypad 0
	kOrdinaryKeyType,	// [83]		Keypad 1
	kOrdinaryKeyType,	// [84]		Keypad 2
	kOrdinaryKeyType,	// [85]		Keypad 3
	kOrdinaryKeyType,	// [86]		Keypad 4
	kOrdinaryKeyType,	// [87]		Keypad 5
	kOrdinaryKeyType,	// [88]		Keypad 6
	kOrdinaryKeyType,	// [89]		Keypad 7
	kSpecialKeyType,	// [90]		Unknown
	kOrdinaryKeyType,	// [91]		Keypad 8
	kOrdinaryKeyType,	// [92]		Keypad 9
	kOrdinaryKeyType,	// [93]		Yen (on JIS keyboard)
	kSpecialKeyType,	// [94]		Unknown
	kSpecialKeyType,	// [95]		Unknown
	kSpecialKeyType,	// [96]		F5
	kSpecialKeyType,	// [97]		F6
	kSpecialKeyType,	// [98]		F7
	kSpecialKeyType,	// [99]		F3
	kSpecialKeyType,	// [100]	F8
	kSpecialKeyType,	// [101]	F9
	kSpecialKeyType,	// [102]	Japanese conversion key
	kSpecialKeyType,	// [103]	F11
	kSpecialKeyType,	// [104]	Japanese conversion key
	kSpecialKeyType,	// [105]	F13
	kSpecialKeyType,	// [106]	F16
	kSpecialKeyType,	// [107]	F14
	kSpecialKeyType,	// [108]	Unknown
	kSpecialKeyType,	// [109]	F10
	kSpecialKeyType,	// [110]	Contextual Menu (Windows keyboards)
	kSpecialKeyType,	// [111]	F12
	kSpecialKeyType,	// [112]	Unknown
	kSpecialKeyType,	// [113]	F15
	kSpecialKeyType,	// [114]	Help
	kSpecialKeyType,	// [115]	Home
	kSpecialKeyType,	// [116]	Page up
	kSpecialKeyType,	// [117]	Forward delete
	kSpecialKeyType,	// [118]	F4
	kSpecialKeyType,	// [119]	End
	kSpecialKeyType,	// [120]	F2
	kSpecialKeyType,	// [121]	Page down
	kSpecialKeyType,	// [122]	F1
	kSpecialKeyType,	// [123]	Left arrow
	kSpecialKeyType,	// [124]	Right arrow
	kSpecialKeyType,	// [125]	Down arrow
	kSpecialKeyType,	// [126]	Up arrow
	kSpecialKeyType		// [127]	Unknown
};

const UInt32 kDefaultMapSize = 0;
bool sTablesSetUp = false;
boost::unordered_map<SInt16, SInt16> sKeyboardNameIndexTable(kDefaultMapSize);
std::vector<KeyboardListType> sKeyboardListTable;
boost::unordered_map<UInt32, UInt16> sKeyboardLayoutTable(kDefaultMapSize);
boost::unordered_map<UInt32, UInt16> sKeyboardTypeTable(kDefaultMapSize);
std::vector<UInt32> sKeyboardNameToIDTable;
boost::unordered_map<UInt16, UniChar> sSpecialKeyList(kDefaultMapSize);
boost::unordered_map<UniChar, UInt16> sSymbolList(kDefaultMapSize);
std::tr1::array<std::map<UInt32, NString>, kStandardKeyboardMaximum + 1> sStandardKeyList;

@implementation LayoutInfo

@synthesize layoutID;
@synthesize flags;

#pragma mark Initialisation

- (id)initWithLayoutID:(int)layout
{
	self = [super init];
	if (self) {
		layoutID = layout;
		flags = 0;
		switch (layoutID) {
			case gestaltPwrBkEKDomKbd:
			case gestaltPwrBkEKISOKbd:
			case gestaltPwrBkEKJISKbd:
			case gestaltPwrBk99JISKbd:
			case gestaltPortable2001ANSIKbd:
			case gestaltPortable2001ISOKbd:
			case gestaltPortable2001JISKbd:
			case gestaltPortableUSBANSIKbd:
			case gestaltPortableUSBISOKbd:
			case gestaltPortableUSBJISKbd:
			case kGestaltAppleANSIKbd:
			case kGestaltAppleISOKbd:
			case kGestaltAppleJISKbd:
				flags |= kHasFnKey;
				flags |= kHasEmbeddedKeypad;
				break;
				
			case kGestaltAppleWirelessANSIKbd:
			case kGestaltAppleWirelessISOKbd:
			case kGestaltAppleWirelessJISKbd:
			case kGestaltMacBookLate2007ANSIkbd:
			case kGestaltMacBookLate2007ISOkbd:
			case kGestaltMacBookLate2007JISkbd:
				flags |= kHasFnKey;
				flags &= ~kHasEmbeddedKeypad;
				break;
//				
//			default:
//				flags &= ~kHasFnKey;
//				flags &= ~kHasEmbeddedKeypad;
//				break;
		}
		switch (layoutID) {
			case gestaltMacKbd:
			case gestaltMacAndPad:
			case gestaltExtADBKbd:
			case gestaltStdADBKbd:
			case gestaltPrtblISOKbd:
			case gestaltStdISOADBKbd:
			case gestaltExtISOADBKbd:
			case gestaltAppleAdjustKeypad:
			case gestaltPS2Keyboard:
				flags |= kHasSeparateRightKeys;
				break;
				
			default:
				flags &= ~kHasSeparateRightKeys;
				break;
		}
	}
	return self;
}

+ (void)checkForInit
{
	if (!layoutInfoInitialised) {
			// Set up the tables we need for layout information
		sKeyboardNameToIDTable.resize(kKeyboardLayoutCount + 1, 0);
			// Original Mac
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltMacKbd, kANSIOnlyKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltMacKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltMacKbd, kKeyboardOriginalMac));
		sKeyboardNameToIDTable[kKeyboardOriginalMac] = gestaltMacKbd;
			// Mac and pad
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltMacAndPad, kANSIOnlyKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltMacAndPad, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltMacAndPad, kKeyboardOriginalMacPad));
		sKeyboardNameToIDTable[kKeyboardOriginalMacPad] = gestaltMacAndPad;
			// Mac Plus - now unknown third party
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltMacPlusKbd, kANSIOnlyKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltMacPlusKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltMacPlusKbd, kKeyboardMacPlus));
		sKeyboardNameToIDTable[kKeyboardMacPlus] = gestaltMacPlusKbd;
			// Extended ADB
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltExtADBKbd, kANSIISOKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltExtADBKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltExtADBKbd, kKeyboardExtendedADB));
		sKeyboardNameToIDTable[kKeyboardExtendedADB] = gestaltExtADBKbd;
			// Standard ADB
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltStdADBKbd, kANSIISOKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltStdADBKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltStdADBKbd, kKeyboardStandardADB));
		sKeyboardNameToIDTable[kKeyboardStandardADB] = gestaltStdADBKbd;
			// Portable ADB
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPrtblADBKbd, kANSIISOKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPrtblADBKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPrtblADBKbd, kKeyboardPortableADB));
		sKeyboardNameToIDTable[kKeyboardPortableADB] = gestaltPrtblADBKbd;
			// Portable ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPrtblISOKbd, kANSIISOKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPrtblISOKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPrtblISOKbd, kKeyboardPortableADB));
			// Standard ADB ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltStdISOADBKbd, kANSIISOKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltStdISOADBKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltStdISOADBKbd, kKeyboardStandardADB));
			// Extended ADB ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltExtISOADBKbd, kANSIISOKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltExtISOADBKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltExtISOADBKbd, kKeyboardExtendedADB));
			// ADB II
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltADBKbdII, kANSIISOKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltADBKbdII, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltADBKbdII, kKeyboardADBII));
		sKeyboardNameToIDTable[kKeyboardADBII] = gestaltADBKbdII;
			// ADB II ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltADBISOKbdII, kANSIISOKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltADBISOKbdII, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltADBISOKbdII, kKeyboardADBII));
			// PowerBook ADB ANSI
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBookADBKbd, kANSIISOKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBookADBKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPwrBookADBKbd, kKeyboardPowerBookADB));
		sKeyboardNameToIDTable[kKeyboardPowerBookADB] = gestaltPwrBookADBKbd;
			// PowerBook ADB ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBookISOADBKbd, kANSIISOKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBookISOADBKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPwrBookISOADBKbd, kKeyboardPowerBookADB));
			// Apple Adjustable keypad
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltAppleAdjustKeypad, kSingleCodeKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltAppleAdjustKeypad, kKeyboardTypeUniversal));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltAppleAdjustKeypad, kKeyboardAdjustablePad));
		sKeyboardNameToIDTable[kKeyboardAdjustablePad] = gestaltAppleAdjustKeypad;
			// Apple Adjustable keyboard ANSI
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltAppleAdjustADBKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltAppleAdjustADBKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltAppleAdjustADBKbd, kKeyboardAdjustable));
		sKeyboardNameToIDTable[kKeyboardAdjustable] = gestaltAppleAdjustADBKbd;
			// Apple Adjustable keyboard ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltAppleAdjustISOKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltAppleAdjustISOKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltAppleAdjustISOKbd, kKeyboardAdjustable));
			// Japanese adjustable keyboard ADB
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltJapanAdjustADBKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltJapanAdjustADBKbd, kKeyboardTypeJIS));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltJapanAdjustADBKbd, kKeyboardAdjustable));
			// Apple Adjustable keyboard JIS
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(kAdjustableJISkbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(kAdjustableJISkbd, kKeyboardTypeJIS));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(kAdjustableJISkbd, kKeyboardAdjustable));
			// PowerBook Extended ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkExtISOKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkExtISOKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPwrBkExtISOKbd, kKeyboardPowerBookExtended));
		sKeyboardNameToIDTable[kKeyboardPowerBookExtended] = gestaltPwrBkExtISOKbd;
			// PowerBook Extended JIS
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkExtJISKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkExtJISKbd, kKeyboardTypeJIS));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPwrBkExtJISKbd, kKeyboardPowerBookExtended));
			// PowerBook Extended ADB
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkExtADBKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkExtADBKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPwrBkExtADBKbd, kKeyboardPowerBookExtended));
			// PS2
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPS2Keyboard, kANSIOnlyKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPS2Keyboard, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPS2Keyboard, kKeyboardPS2));
		sKeyboardNameToIDTable[kKeyboardPS2] = gestaltPS2Keyboard;
			// PowerBook Subnotebook ANSI
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkSubDomKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkSubDomKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPwrBkSubDomKbd, kKeyboardSubnote));
		sKeyboardNameToIDTable[kKeyboardSubnote] = gestaltPwrBkSubDomKbd;
			// PowerBook Subnotebook ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkSubISOKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkSubISOKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPwrBkSubISOKbd, kKeyboardSubnote));
			// PowerBook Subnotebook JIS
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkSubJISKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkSubJISKbd, kKeyboardTypeJIS));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPwrBkSubJISKbd, kKeyboardSubnote));
			// PowerBook Embedded Keypad ANSI
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkEKDomKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkEKDomKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPwrBkEKDomKbd, kKeyboardPowerBookKeypad));
		sKeyboardNameToIDTable[kKeyboardPowerBookKeypad] = gestaltPwrBkEKDomKbd;
			// PowerBook Embedded Keypad ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkEKISOKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkEKISOKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPwrBkEKISOKbd, kKeyboardPowerBookKeypad));
			// PowerBook Embedded Keypad JIS
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkEKJISKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBkEKJISKbd, kKeyboardTypeJIS));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPwrBkEKJISKbd, kKeyboardPowerBookKeypad));
			// USB Cosmo ANSI
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBCosmoANSIKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBCosmoANSIKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltUSBCosmoANSIKbd, kKeyboardCosmo));
		sKeyboardNameToIDTable[kKeyboardCosmo] = gestaltUSBCosmoANSIKbd;
			// USB Cosmo ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBCosmoISOKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBCosmoISOKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltUSBCosmoISOKbd, kKeyboardCosmo));
			// USB Cosmo JIS
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBCosmoJISKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBCosmoJISKbd, kKeyboardTypeJIS));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltUSBCosmoJISKbd, kKeyboardCosmo));
			// PowerBook 1999 JIS
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBk99JISKbd, kJISOnlyKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPwrBk99JISKbd, kKeyboardTypeJIS));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPwrBk99JISKbd, kKeyboard1999Japanese));
		sKeyboardNameToIDTable[kKeyboard1999Japanese] = gestaltPwrBk99JISKbd;
			// USB Pro Keyboard ANSI
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBAndyANSIKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBAndyANSIKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltUSBAndyANSIKbd, kKeyboardUSBPro));
		sKeyboardNameToIDTable[kKeyboardUSBPro] = gestaltUSBAndyANSIKbd;
			// USB Pro Keyboard ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBAndyISOKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBAndyISOKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltUSBAndyISOKbd, kKeyboardUSBPro));
			// USB Pro Keyboard JIS
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBAndyJISKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBAndyJISKbd, kKeyboardTypeJIS));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltUSBAndyJISKbd, kKeyboardUSBPro));
			// PowerBook 2nd Command key ANSI
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPortable2001ANSIKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPortable2001ANSIKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPortable2001ANSIKbd, kKeyboardPowerBook2ndCmd));
		sKeyboardNameToIDTable[kKeyboardPowerBook2ndCmd] = gestaltPortable2001ANSIKbd;
			// PowerBook 2nd Command key ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPortable2001ISOKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPortable2001ISOKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPortable2001ISOKbd, kKeyboardPowerBook2ndCmd));
			// PowerBook 2nd Command key JIS
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPortable2001JISKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPortable2001JISKbd, kKeyboardTypeJIS));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPortable2001JISKbd, kKeyboardPowerBook2ndCmd));
			// USB Pro with F16 ANSI
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBProF16ANSIKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBProF16ANSIKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltUSBProF16ANSIKbd, kKeyboardUSBProF16));
		sKeyboardNameToIDTable[kKeyboardUSBProF16] = gestaltUSBProF16ANSIKbd;
			// USB Pro with F16 ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBProF16ISOKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBProF16ISOKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltUSBProF16ISOKbd, kKeyboardUSBProF16));
			// USB Pro with F16 JIS
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBProF16JISKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltUSBProF16JISKbd, kKeyboardTypeJIS));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltUSBProF16JISKbd, kKeyboardUSBProF16));
			// Pro with F16 ANSI
		sKeyboardLayoutTable[gestaltProF16ANSIKbd] =kANSIISOJISKeyboard ;
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltProF16ANSIKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltProF16ANSIKbd, kKeyboardProF16));
		sKeyboardNameToIDTable[kKeyboardProF16] = gestaltProF16ANSIKbd;
			// Pro with F16 ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltProF16ISOKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltProF16ISOKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltProF16ISOKbd, kKeyboardProF16));
			// Pro with F16 JIS
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltProF16JISKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltProF16JISKbd, kKeyboardTypeJIS));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltProF16JISKbd, kKeyboardProF16));
			// PowerBook USB-based Internal ANSI
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPortableUSBANSIKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPortableUSBANSIKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPortableUSBANSIKbd, kKeyboardPowerBookUSB));
		sKeyboardNameToIDTable[kKeyboardPowerBookUSB] = gestaltPortableUSBANSIKbd;
			// PowerBook USB-based Internal ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPortableUSBISOKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPortableUSBISOKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPortableUSBISOKbd, kKeyboardPowerBookUSB));
			// PowerBook USB-based Internal JIS
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltPortableUSBJISKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltPortableUSBJISKbd, kKeyboardTypeJIS));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltPortableUSBJISKbd, kKeyboardPowerBookUSB));
			// Third Party Keyboard ANSI
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltThirdPartyANSIKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltThirdPartyANSIKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltThirdPartyANSIKbd, kKeyboardThirdParty));
		sKeyboardNameToIDTable[kKeyboardThirdParty] = gestaltThirdPartyANSIKbd;
			// Third Party Keyboard ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltThirdPartyISOKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltThirdPartyISOKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltThirdPartyISOKbd, kKeyboardThirdParty));
			// Third Party Keyboard 
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(gestaltThirdPartyJISKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(gestaltThirdPartyJISKbd, kKeyboardTypeJIS));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(gestaltThirdPartyJISKbd, kKeyboardThirdParty));
			// Apple Wireless Keyboard ANSI
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(kGestaltAppleWirelessANSIKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(kGestaltAppleWirelessANSIKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(kGestaltAppleWirelessANSIKbd, kKeyboardWirelessAluminium));
		sKeyboardNameToIDTable[kKeyboardWirelessAluminium] = kGestaltAppleWirelessANSIKbd;
			// Apple Wireless Keyboard ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(kGestaltAppleWirelessISOKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(kGestaltAppleWirelessISOKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(kGestaltAppleWirelessISOKbd, kKeyboardWirelessAluminium));
			// Apple Wireless Keyboard JIS
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(kGestaltAppleWirelessJISKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(kGestaltAppleWirelessJISKbd, kKeyboardTypeJIS));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(kGestaltAppleWirelessJISKbd, kKeyboardWirelessAluminium));
			// Apple Keyboard ANSI
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(kGestaltAppleANSIKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(kGestaltAppleANSIKbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(kGestaltAppleANSIKbd, kKeyboardAluminium));
		sKeyboardNameToIDTable[kKeyboardAluminium] = kGestaltAppleANSIKbd;
			// Apple Keyboard ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(kGestaltAppleISOKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(kGestaltAppleISOKbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(kGestaltAppleISOKbd, kKeyboardAluminium));
			// Apple Keyboard JIS
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(kGestaltAppleJISKbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(kGestaltAppleJISKbd, kKeyboardTypeJIS));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(kGestaltAppleJISKbd, kKeyboardAluminium));
			// MacBook (Late 2007) Keyboard ANSI
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(kGestaltMacBookLate2007ANSIkbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(kGestaltMacBookLate2007ANSIkbd, kKeyboardTypeANSI));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(kGestaltMacBookLate2007ANSIkbd, kKeyboardMacBookLate2007));
		sKeyboardNameToIDTable[kKeyboardMacBookLate2007] = kGestaltMacBookLate2007ANSIkbd;
			// MacBook (Late 2007) Keyboard ISO
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(kGestaltMacBookLate2007ISOkbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(kGestaltMacBookLate2007ISOkbd, kKeyboardTypeISO));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(kGestaltMacBookLate2007ISOkbd, kKeyboardMacBookLate2007));
			// MacBook (Late 2007) Keyboard JIS
		sKeyboardLayoutTable.insert(std::make_pair<UInt32, UInt16>(kGestaltMacBookLate2007JISkbd, kANSIISOJISKeyboard));
		sKeyboardTypeTable.insert(std::make_pair<UInt32, UInt16>(kGestaltMacBookLate2007JISkbd, kKeyboardTypeJIS));
		sKeyboardNameIndexTable.insert(std::make_pair<SInt16, SInt16>(kGestaltMacBookLate2007JISkbd, kKeyboardMacBookLate2007));
		
		KeyboardListType keyboardList, nullKeyboardList = { 0, 0, 0, 0 };
		sKeyboardListTable.resize(kKeyboardLayoutCount + 1, nullKeyboardList);
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltMacKbd;
		sKeyboardListTable[kKeyboardOriginalMac] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltMacAndPad;
		sKeyboardListTable[kKeyboardOriginalMacPad] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltMacPlusKbd;
		sKeyboardListTable[kKeyboardMacPlus] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltStdADBKbd;
		keyboardList.ISO = gestaltStdISOADBKbd;
		sKeyboardListTable[kKeyboardStandardADB] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltExtADBKbd;
		keyboardList.ISO = gestaltExtISOADBKbd;
		sKeyboardListTable[kKeyboardExtendedADB] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltPrtblADBKbd;
		keyboardList.ISO = gestaltPrtblISOKbd;
		sKeyboardListTable[kKeyboardPortableADB] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltADBKbdII;
		keyboardList.ISO = gestaltADBISOKbdII;
		sKeyboardListTable[kKeyboardADBII] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltPwrBookADBKbd;
		keyboardList.ISO = gestaltPwrBookISOADBKbd;
		sKeyboardListTable[kKeyboardPowerBookADB] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltPwrBkExtADBKbd;
		keyboardList.ISO = gestaltPwrBkExtISOKbd;
		keyboardList.JIS = gestaltPwrBkExtJISKbd;
		sKeyboardListTable[kKeyboardPowerBookExtended] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltAppleAdjustISOKbd;
		keyboardList.ISO = gestaltJapanAdjustADBKbd;
		keyboardList.JIS = kAdjustableJISkbd;
		sKeyboardListTable[kKeyboardAdjustable] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.all = gestaltAppleAdjustKeypad;
		sKeyboardListTable[kKeyboardAdjustablePad] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltPwrBkSubDomKbd;
		keyboardList.ISO = gestaltPwrBkSubISOKbd;
		keyboardList.JIS = gestaltPwrBkSubJISKbd;
		sKeyboardListTable[kKeyboardSubnote] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltPS2Keyboard;
		sKeyboardListTable[kKeyboardPS2] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltPwrBkEKDomKbd;
		keyboardList.ISO = gestaltPwrBkEKISOKbd;
		keyboardList.JIS = gestaltPwrBkEKJISKbd;
		sKeyboardListTable[kKeyboardPowerBookKeypad] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltUSBCosmoANSIKbd;
		keyboardList.ISO = gestaltUSBCosmoISOKbd;
		keyboardList.JIS = gestaltUSBCosmoJISKbd;
		sKeyboardListTable[kKeyboardCosmo] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.JIS = gestaltPwrBk99JISKbd;
		sKeyboardListTable[kKeyboard1999Japanese] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltUSBAndyANSIKbd;
		keyboardList.ISO = gestaltUSBAndyISOKbd;
		keyboardList.JIS = gestaltUSBAndyJISKbd;
		sKeyboardListTable[kKeyboardUSBPro] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltPortable2001ANSIKbd;
		keyboardList.ISO = gestaltPortable2001ISOKbd;
		keyboardList.JIS = gestaltPortable2001JISKbd;
		sKeyboardListTable[kKeyboardPowerBook2ndCmd] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltUSBProF16ANSIKbd;
		keyboardList.ISO = gestaltUSBProF16ISOKbd;
		keyboardList.JIS = gestaltUSBProF16JISKbd;
		sKeyboardListTable[kKeyboardUSBProF16] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltProF16ANSIKbd;
		keyboardList.ISO = gestaltProF16ISOKbd;
		keyboardList.JIS = gestaltProF16JISKbd;
		sKeyboardListTable[kKeyboardProF16] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltPortableUSBANSIKbd;
		keyboardList.ISO = gestaltPortableUSBISOKbd;
		keyboardList.JIS = gestaltPortableUSBJISKbd;
		sKeyboardListTable[kKeyboardPowerBookUSB] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = gestaltThirdPartyANSIKbd;
		keyboardList.ISO = gestaltThirdPartyISOKbd;
		keyboardList.JIS = gestaltThirdPartyJISKbd;
		sKeyboardListTable[kKeyboardThirdParty] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = kGestaltAppleWirelessANSIKbd;
		keyboardList.ISO = kGestaltAppleWirelessISOKbd;
		keyboardList.JIS = kGestaltAppleWirelessJISKbd;
		sKeyboardListTable[kKeyboardWirelessAluminium] = keyboardList;
		keyboardList = nullKeyboardList;
		keyboardList.ANSI = kGestaltAppleANSIKbd;
		keyboardList.ISO = kGestaltAppleISOKbd;
		keyboardList.JIS = kGestaltAppleJISKbd;
		sKeyboardListTable[kKeyboardAluminium] = keyboardList;
		
		sSpecialKeyList.insert(std::make_pair(kKeyReturn,		 0x000d));
		sSpecialKeyList.insert(std::make_pair(kKeyTab,			 0x0009));
		sSpecialKeyList.insert(std::make_pair(kKeyEnter,		 0x0003));
			//		sSpecialKeyList.insert(std::make_pair(kKeyPadEnter,		 0x0003));
		sSpecialKeyList.insert(std::make_pair(kKeyEscape,		 0x001b));
		sSpecialKeyList.insert(std::make_pair(kKeyPadClear,		 0x001b));
		sSpecialKeyList.insert(std::make_pair(kKeyDelete,		 0x0008));
		sSpecialKeyList.insert(std::make_pair(kKeyF1,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF2,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF3,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF4,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF5,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF6,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF7,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF8,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF9,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF10,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF11,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF12,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF13,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF14,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF15,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF16,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF17,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF18,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyF19,			 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyHelp,			 0x0005));
		sSpecialKeyList.insert(std::make_pair(kKeyHome,			 0x0001));
		sSpecialKeyList.insert(std::make_pair(kKeyEnd,			 0x0004));
		sSpecialKeyList.insert(std::make_pair(kKeyPageUp,		 0x000b));
		sSpecialKeyList.insert(std::make_pair(kKeyPageDown,		 0x000c));
		sSpecialKeyList.insert(std::make_pair(kKeyForwardDelete, 0x007f));
		sSpecialKeyList.insert(std::make_pair(kKeyLeftArrow,	 0x001c));
		sSpecialKeyList.insert(std::make_pair(kKeyRightArrow,	 0x001d));
		sSpecialKeyList.insert(std::make_pair(kKeyDownArrow,	 0x001f));
		sSpecialKeyList.insert(std::make_pair(kKeyUpArrow,		 0x001e));
		sSpecialKeyList.insert(std::make_pair(66,				 0x001d));
		sSpecialKeyList.insert(std::make_pair(70,				 0x001c));
		sSpecialKeyList.insert(std::make_pair(72,				 0x001f));
		sSpecialKeyList.insert(std::make_pair(77,				 0x001e));
		sSpecialKeyList.insert(std::make_pair(kKeyJapaneseConversionLeft, 0x0010));
		sSpecialKeyList.insert(std::make_pair(kKeyJapaneseConversionRight, 0x0010));
		
		sSymbolList.insert(std::make_pair(0x0001, kKeyHome));
		sSymbolList.insert(std::make_pair(0x0003, kKeyEnter));
			//		sSymbolList.insert(std::make_pair(0x0003, kKeyPadEnter));
		sSymbolList.insert(std::make_pair(0x0004, kKeyEnd));
		sSymbolList.insert(std::make_pair(0x0005, kKeyHelp));
		sSymbolList.insert(std::make_pair(0x0008, kKeyDelete));
		sSymbolList.insert(std::make_pair(0x0009, kKeyTab));
		sSymbolList.insert(std::make_pair(0x000b, kKeyPageUp));
		sSymbolList.insert(std::make_pair(0x000c, kKeyPageDown));
		sSymbolList.insert(std::make_pair(0x000d, kKeyReturn));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF1));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF2));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF3));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF4));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF5));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF6));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF7));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF8));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF9));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF10));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF11));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF12));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF13));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF14));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF15));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF16));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF17));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF18));
		sSymbolList.insert(std::make_pair(0x0010, kKeyF19));
		sSymbolList.insert(std::make_pair(0x001b, kKeyEscape));
		sSymbolList.insert(std::make_pair(0x001b, kKeyPadClear));
		sSymbolList.insert(std::make_pair(0x001c, kKeyLeftArrow));
		sSymbolList.insert(std::make_pair(0x001c, 70));
		sSymbolList.insert(std::make_pair(0x001d, kKeyRightArrow));
		sSymbolList.insert(std::make_pair(0x001d, 66));
		sSymbolList.insert(std::make_pair(0x001e, kKeyUpArrow));
		sSymbolList.insert(std::make_pair(0x001e, 77));
		sSymbolList.insert(std::make_pair(0x001f, kKeyDownArrow));
		sSymbolList.insert(std::make_pair(0x001f, 72));
		sSymbolList.insert(std::make_pair(0x007f, kKeyForwardDelete));
		
		std::map<UInt32, NString> emptyList;
		std::map<UInt32, NString> QWERTYLowerCaseList;
		QWERTYLowerCaseList.insert(std::make_pair(kKeyA, "a"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyB, "b"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyC, "c"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyD, "d"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyE, "e"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyF, "f"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyG, "g"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyH, "h"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyI, "i"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyJ, "j"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyK, "k"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyL, "l"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyM, "m"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyN, "n"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyO, "o"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyP, "p"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyQ, "q"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyR, "r"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyS, "s"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyT, "t"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyU, "u"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyV, "v"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyW, "w"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyX, "x"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyY, "y"));
		QWERTYLowerCaseList.insert(std::make_pair(kKeyZ, "z"));
		std::map<UInt32, NString> QWERTYUpperCaseList;
		QWERTYUpperCaseList.insert(std::make_pair(kKeyA, "A"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyB, "B"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyC, "C"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyD, "D"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyE, "E"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyF, "F"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyG, "G"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyH, "H"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyI, "I"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyJ, "J"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyK, "K"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyL, "L"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyM, "M"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyN, "N"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyO, "O"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyP, "P"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyQ, "Q"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyR, "R"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyS, "S"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyT, "T"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyU, "U"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyV, "V"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyW, "W"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyX, "X"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyY, "Y"));
		QWERTYUpperCaseList.insert(std::make_pair(kKeyZ, "Z"));
		std::map<UInt32, NString> DvorakLowerCaseList;
		DvorakLowerCaseList.insert(std::make_pair(kKeyA, "a"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyB, "x"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyC, "j"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyD, "e"));
		DvorakLowerCaseList.insert(std::make_pair(kKeySemicolon, "s"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyF, "u"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyG, "i"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyH, "d"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyI, "c"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyJ, "h"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyK, "t"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyL, "n"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyM, "m"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyN, "b"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyO, "r"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyP, "l"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyComma, "w"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyR, "p"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyS, "o"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyT, "y"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyU, "g"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyV, "k"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyDot, "v"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyX, "q"));
		DvorakLowerCaseList.insert(std::make_pair(kKeyY, "f"));
		DvorakLowerCaseList.insert(std::make_pair(kKeySlash, "z"));
		std::map<UInt32, NString> DvorakUpperCaseList;
		DvorakUpperCaseList.insert(std::make_pair(kKeyA, "A"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyB, "X"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyC, "J"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyD, "E"));
		DvorakUpperCaseList.insert(std::make_pair(kKeySemicolon, "S"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyF, "U"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyG, "I"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyH, "D"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyI, "C"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyJ, "H"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyK, "T"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyL, "N"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyM, "M"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyN, "B"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyO, "R"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyP, "L"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyComma, "W"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyR, "P"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyS, "O"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyT, "Y"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyU, "G"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyV, "K"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyDot, "V"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyX, "Q"));
		DvorakUpperCaseList.insert(std::make_pair(kKeyY, "F"));
		DvorakUpperCaseList.insert(std::make_pair(kKeySlash, "Z"));
		std::map<UInt32, NString> AZERTYLowerCaseList;
		AZERTYLowerCaseList.insert(std::make_pair(kKeyA, "q"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyB, "b"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyC, "c"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyD, "d"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyE, "e"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyF, "f"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyG, "g"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyH, "h"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyI, "i"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyJ, "j"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyK, "k"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyL, "l"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeySemicolon, "m"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyN, "n"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyO, "o"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyP, "p"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyQ, "a"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyR, "r"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyS, "s"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyT, "t"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyU, "u"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyV, "v"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyW, "z"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyX, "x"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyY, "y"));
		AZERTYLowerCaseList.insert(std::make_pair(kKeyZ, "w"));
		std::map<UInt32, NString> AZERTYUpperCaseList;
		AZERTYUpperCaseList.insert(std::make_pair(kKeyA, "Q"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyB, "B"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyC, "C"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyD, "D"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyE, "E"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyF, "F"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyG, "G"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyH, "H"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyI, "I"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyJ, "J"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyK, "K"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyL, "L"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeySemicolon, "M"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyN, "N"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyO, "O"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyP, "P"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyQ, "A"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyR, "R"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyS, "S"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyT, "T"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyU, "U"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyV, "V"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyW, "Z"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyX, "X"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyY, "Y"));
		AZERTYUpperCaseList.insert(std::make_pair(kKeyZ, "W"));
		std::map<UInt32, NString> QWERTZLowerCaseList;
		QWERTZLowerCaseList.insert(std::make_pair(kKeyA, "a"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyB, "b"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyC, "c"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyD, "d"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyE, "e"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyF, "f"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyG, "g"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyH, "h"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyI, "i"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyJ, "j"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyK, "k"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyL, "l"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyM, "m"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyN, "n"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyO, "o"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyP, "p"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyQ, "q"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyR, "r"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyS, "s"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyT, "t"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyU, "u"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyV, "v"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyW, "w"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyX, "x"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyY, "z"));
		QWERTZLowerCaseList.insert(std::make_pair(kKeyZ, "y"));
		std::map<UInt32, NString> QWERTZUpperCaseList;
		QWERTZUpperCaseList.insert(std::make_pair(kKeyA, "A"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyB, "B"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyC, "C"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyD, "D"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyE, "E"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyF, "F"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyG, "G"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyH, "H"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyI, "I"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyJ, "J"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyK, "K"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyL, "L"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyM, "M"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyN, "N"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyO, "O"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyP, "P"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyQ, "Q"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyR, "R"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyS, "S"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyT, "T"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyU, "U"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyV, "V"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyW, "W"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyX, "X"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyY, "Z"));
		QWERTZUpperCaseList.insert(std::make_pair(kKeyZ, "Y"));
		sStandardKeyList[0] = emptyList;
		sStandardKeyList[kStandardKeyboardEmpty] = emptyList;
		sStandardKeyList[kStandardKeyboardQWERTYLowerCase] = QWERTYLowerCaseList;
		sStandardKeyList[kStandardKeyboardQWERTYUpperCase] = QWERTYUpperCaseList;
		sStandardKeyList[kStandardKeyboardDvorakLowerCase] = DvorakLowerCaseList;
		sStandardKeyList[kStandardKeyboardDvorakUpperCase] = DvorakUpperCaseList;
		sStandardKeyList[kStandardKeyboardAZERTYLowerCase] = AZERTYLowerCaseList;
		sStandardKeyList[kStandardKeyboardAZERTYUpperCase] = AZERTYUpperCaseList;
		sStandardKeyList[kStandardKeyboardQWERTZLowerCase] = QWERTZLowerCaseList;
		sStandardKeyList[kStandardKeyboardQWERTZUpperCase] = QWERTZUpperCaseList;
		
		layoutInfoInitialised = YES;
	}
}

#pragma mark Class methods

+ (unsigned int)getKeyType:(unsigned int)keyCode
{
	[LayoutInfo checkForInit];
	if (keyCode < kKeyCodeTableSize) {
		return sKeyCodeTable[keyCode];
	}
	else {
		return kOrdinaryKeyType;
	}
}

+ (NSString *)getSpecialKeyOutput:(unsigned int)keyCode
{
	[LayoutInfo checkForInit];
	NString result = "";
	boost::unordered_map<UInt16, UniChar>::iterator pos = sSpecialKeyList.find(keyCode);
	if (pos != sSpecialKeyList.end()) {
		BOOL codeNonAscii = [[NSUserDefaults standardUserDefaults] boolForKey:UKCodeNonAscii];
		result = XMLUtilities::MakeXMLString(&(pos->second), 1, codeNonAscii);
	}
	return ToNS(result);
}

+ (NSString *)getKeySymbol:(unsigned int)keyCode withString:(NSString *)string
{
	[LayoutInfo checkForInit];
		// We may have a special key if the string is length 1
	bool isStandardSymbol = false;
	NString myString = ToNN(string);
	if (myString.GetSize() == 1) {
			// Is the key a special key? If so, check whether the string is the
			// standard output for that special key
		boost::unordered_map<UInt16, UniChar>::iterator pos = sSpecialKeyList.find(keyCode);
		const UniChar *stringChars = myString.GetUTF16();
		UniChar symbol = stringChars[0];
		if (pos != sSpecialKeyList.end() && symbol == pos->second) {
			isStandardSymbol = true;
		}
		if (!isStandardSymbol) {
				// If it's not the standard output for the key, is it
				// standard output for another special key?
			boost::unordered_map<UniChar, UInt16>::iterator symbolPos = sSymbolList.find(symbol);
			if (symbolPos != sSymbolList.end() && [LayoutInfo getKeyType:symbolPos->second] == kSpecialKeyType) {
				return [LayoutInfo getKeySymbol:symbolPos->second withString:@""];
			}
		}
	}
	boost::scoped_array<UniChar> symbolStr;
	UInt16 symbolLength = 0;
	switch (keyCode) {
		case kKeyShift:
		case kKeyRightShift:
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kShiftUnicode;
			symbolLength = 1;
			break;
			
		case kKeyControl:
		case kKeyRightControl:
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kControlUnicode;
			symbolLength = 1;
			break;
			
		case kKeyOption:
		case kKeyRightOption:
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kOptionUnicode;
			symbolLength = 1;
			break;
			
		case kKeyCommand:
		case kKeyRightCommand:
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kCommandUnicode;
			symbolLength = 1;
			break;
			
		case kKeyLeftArrow:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kLeftArrowUnicode;
			symbolLength = 1;
			break;
			
		case kKeyUpArrow:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kDashedUpArrowUnicode;
			symbolLength = 1;
			break;
			
		case kKeyRightArrow:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kRightArrowUnicode;
			symbolLength = 1;
			break;
			
		case kKeyDownArrow:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kDashedDownArrowUnicode;
			symbolLength = 1;
			break;
			
		case kKeyCapsLock:
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kCapsLockUnicode;
			symbolLength = 1;
			break;
			
		case kKeyReturn:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kReturnUnicode;
			symbolLength = 1;
			break;
			
		case kKeyEnter:
				//		case kKeyPadEnter:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kEnterUnicode;
			symbolLength = 1;
			break;
			
		case kKeyTab:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kTabUnicode;
			symbolLength = 1;
			break;
			
		case kKeyDelete:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kDeleteUnicode;
			symbolLength = 1;
			break;
			
		case kKeyPageUp:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kPageUpUnicode;
			symbolLength = 1;
			break;
			
		case kKeyPageDown:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kPageDownUnicode;
			symbolLength = 1;
			break;
			
		case kKeyHome:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kNorthWestArrowUnicode;
			symbolLength = 1;
			break;
			
		case kKeyEnd:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kSouthEastArrowUnicode;
			symbolLength = 1;
			break;
			
		case kKeyForwardDelete:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kForwardDeleteUnicode;
			symbolLength = 1;
			break;
			
		case kKeyPadClear:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			symbolStr.reset(new UniChar[1]);
			symbolStr[0] = kClearUnicode;
			symbolLength = 1;
			break;
			
		case kKeyHelp:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			symbolStr.reset(new UniChar[2]);
			symbolStr[0] = 0xfe56;
			symbolStr[1] = 0x20dd;
			symbolLength = 1;
			break;
			
		case kKeyEscape:
			return @"esc";
			
		case kKeyF1:
			return @"F1";
			
		case kKeyF2:
			return @"F2";
			
		case kKeyF3:
			return @"F3";
			
		case kKeyF4:
			return @"F4";
			
		case kKeyF5:
			return @"F5";
			
		case kKeyF6:
			return @"F6";
			
		case kKeyF7:
			return @"F7";
			
		case kKeyF8:
			return @"F8";
			
		case kKeyF9:
			return @"F9";
			
		case kKeyF10:
			return @"F10";
			
		case kKeyF11:
			return @"F11";
			
		case kKeyF12:
			return @"F12";
			
		case kKeyF13:
			return @"F13";
			
		case kKeyF14:
			return @"F14";
			
		case kKeyF15:
			return @"F15";
			
		case kKeyF16:
			return @"F16";
			
		case kKeyF17:
			return @"F17";
			
		case kKeyF18:
			return @"F18";
			
		case kKeyF19:
			return @"F19";
			
		case kKeyFn:
			return @"Fn";
			
		case kKeyJapaneseConversionLeft:
			symbolStr.reset(new UniChar[2]);
			symbolStr[0] = kJapaneseLeft1Unicode;
			symbolStr[1] = kJapaneseLeft2Unicode;
			symbolLength = 2;
			break;
			
		case kKeyJapaneseConversionRight:
			symbolStr.reset(new UniChar[2]);
			symbolStr[0] = kKatakanaKaUnicode;
			symbolStr[1] = kKatakanaNaUnicode;
			symbolLength = 2;
			break;
			
		default:
			if (myString.GetSize() == 1) {
					// The key code is not a special key. Check if the string is the
					// standard output for a special key.
				const UniChar *stringChars = myString.GetUTF16();
				UniChar outStr = stringChars[0];
				boost::unordered_map<UniChar, UInt16>::iterator pos = sSymbolList.find(outStr);
				if (pos != sSymbolList.end() && [LayoutInfo getKeyType:keyCode] == kSpecialKeyType) {
					return [LayoutInfo getKeySymbol:pos->second withString:@""];
				}
			}
			break;
	}
	if (symbolLength > 0) {
		return [NSString stringWithCharacters:symbolStr.get() length:symbolLength];
	}
	return @"";
}

+ (NSMutableAttributedString *)getKeySymbolString:(unsigned int)keyCode withString:(NSString *)string
{
	[LayoutInfo checkForInit];
		// We may have a special key if the string is length 1
	bool isStandardSymbol = false;
	NString myString = ToNN(string);
	if (myString.GetSize() == 1) {
			// Is the key a special key? If so, check whether the string is the
			// standard output for that special key
		boost::unordered_map<UInt16, UniChar>::iterator pos = sSpecialKeyList.find(keyCode);
		const UniChar *stringChars = myString.GetUTF16();
		UniChar symbol = stringChars[0];
		if (pos != sSpecialKeyList.end() && symbol == pos->second) {
			isStandardSymbol = true;
		}
		if (!isStandardSymbol) {
				// If it's not the standard output for the key, is it
				// standard output for another special key?
			boost::unordered_map<UniChar, UInt16>::iterator symbolPos = sSymbolList.find(symbol);
			if (symbolPos != sSymbolList.end() && [LayoutInfo getKeyType:symbolPos->second] == kSpecialKeyType) {
				return [LayoutInfo getKeySymbolString:symbolPos->second withString:@""];
			}
		}
	}
//	NSFont *keyboardFont = [NSFont fontWithName:@".Keyboard" size:20.0];    // Stub: Hard-coded size!
	NSMutableAttributedString *resultString = [[NSMutableAttributedString alloc] initWithString:@""];
//	NSGlyphInfo *glyphInfo = nil;
//	NSDictionary *attributeDictionary = nil;
	NSString *tempString = nil;
	boost::scoped_array<unichar> stringStorage;
	switch (keyCode) {
		case kKeyShift:
		case kKeyRightShift:
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kShiftUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyControl:
		case kKeyRightControl:
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kControlUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyOption:
		case kKeyRightOption:
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kOptionUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyCommand:
		case kKeyRightCommand:
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kCommandUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyCapsLock:
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kCapsLockUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyLeftArrow:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kLeftArrowUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyRightArrow:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kRightArrowUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyUpArrow:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kDashedUpArrowUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyDownArrow:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kDashedDownArrowUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyReturn:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kReturnUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyEnter:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kEnterUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeEnter forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			break;
			
		case kKeyTab:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kTabUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyDelete:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kDeleteUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyForwardDelete:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kForwardDeleteUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyPageUp:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kPageUpUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyPageDown:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kPageDownUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyHome:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kNorthWestArrowUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyEnd:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kSouthEastArrowUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyPadClear:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kClearUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyHelp:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[2]);
			stringStorage[0] = 0xfe56;
			stringStorage[1] = 0x20dd;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:2];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeHelp forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			break;
			
		case kKeyEscape:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[1]);
			stringStorage[0] = kEscapeUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:1];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF1:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F1";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF1 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF2:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F2";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF2 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF3:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F3";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF3 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF4:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F4";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF4 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF5:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F5";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF5 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF6:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F6";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF6 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF7:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F7";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF7 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF8:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F8";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF8 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF9:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F9";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF9 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF10:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F10";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF10 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF11:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F11";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF11 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF12:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F12";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF12 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF13:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F13";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF13 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF14:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F14";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF14 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF15:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F15";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF15 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF16:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F16";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF16 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF17:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F17";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF17 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF18:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F18";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF18 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyF19:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"F19";
//			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
//			glyphInfo = [NSGlyphInfo glyphInfoWithGlyph:kGlyphCodeF19 forFont:keyboardFont baseString:tempString];
//			attributeDictionary = [NSDictionary dictionaryWithObject:glyphInfo forKey:NSGlyphInfoAttributeName];
//			[resultString setAttributes:attributeDictionary range:NSMakeRange(0, [resultString length])];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyFn:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			tempString = @"Fn";
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;
			
		case kKeyJapaneseConversionLeft:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[2]);
			stringStorage[0] = kJapaneseLeft1Unicode;
			stringStorage[1] = kJapaneseLeft2Unicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:2];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;			
			
		case kKeyJapaneseConversionRight:
			if (myString.GetSize() > 0 && !isStandardSymbol) {
				break;
			}
			stringStorage.reset(new unichar[2]);
			stringStorage[0] = kKatakanaKaUnicode;
			stringStorage[1] = kKatakanaNaUnicode;
			tempString = [NSString stringWithCharacters:stringStorage.get() length:2];
			[resultString replaceCharactersInRange:NSMakeRange(0, 0) withString:tempString];
			break;			
			
		default:
			break;
	}
	if ([resultString length] > 0) {
		return resultString;
	}
	return [[NSMutableAttributedString alloc] initWithString:@""];
}

+ (unsigned int)getKeyboardLayoutType:(int)keyboardID
{
	[LayoutInfo checkForInit];
	boost::unordered_map<UInt32, UInt16>::iterator pos = sKeyboardLayoutTable.find(keyboardID);
	if (pos != sKeyboardLayoutTable.end()) {
		return pos->second;
	}
	return kSingleCodeKeyboard;
}

+ (unsigned int)getKeyboardType:(int)keyboardID
{
	[LayoutInfo checkForInit];
	boost::unordered_map<UInt32, UInt16>::iterator pos = sKeyboardTypeTable.find(keyboardID);
	if (pos != sKeyboardTypeTable.end()) {
		return pos->second;
	}
	return kKeyboardTypeUniversal;
}

+ (int)getKeyboardNameIndex:(int)keyboardID
{
	[LayoutInfo checkForInit];
	boost::unordered_map<SInt16, SInt16>::iterator pos = sKeyboardNameIndexTable.find(keyboardID);
	if (pos != sKeyboardNameIndexTable.end()) {
		return pos->second;
	}
	return 0;
}

+ (NSDictionary *)getKeyboardList:(unsigned int)keyboardID
{
	return @{kKeyANSIType: @((int)sKeyboardListTable[keyboardID].ANSI),
			kKeyISOType: @((int)sKeyboardListTable[keyboardID].ISO),
			kKeyJISType: @((int)sKeyboardListTable[keyboardID].JIS),
			kKeyAllTypes: @((int)sKeyboardListTable[keyboardID].all)};
}

+ (unsigned int)getKeyboardID:(unsigned int)keyboardName
{
	return sKeyboardNameToIDTable[keyboardName];
}

+ (NSString *)getStandardKeyOutputForKeyboard:(int)keyboardID forKeyCode:(unsigned int)keyCode
{
	[LayoutInfo checkForInit];
	NN_ASSERT(keyboardID < sStandardKeyList.size());
	NString result;
	if (keyboardID != kStandardKeyboardEmpty) {
		std::map<UInt32, NString> keyMap = sStandardKeyList[keyboardID];
		std::map<UInt32, NString>::iterator keyMapPos = keyMap.find(keyCode);
		if (keyMapPos != keyMap.end()) {
			result = keyMapPos->second;
		}
	}
	return ToNS(result);
}

+ (NSString *)getKeyboardName:(int)keyboardID
{
	[LayoutInfo checkForInit];
	NString keyboardName = "";
	switch (keyboardID) {
		case kKeyboardOriginalMac:
			keyboardName = kOriginalMacName;
			break;
			
		case kKeyboardOriginalMacPad:
			keyboardName = kOriginalMacKeypadName;
			break;
			
		case kKeyboardMacPlus:
			keyboardName = kMacPlusName;
			break;
			
		case kKeyboardStandardADB:
			keyboardName = kStandardADBName;
			break;
			
		case kKeyboardExtendedADB:
			keyboardName = kExtendedADBName;
			break;
			
		case kKeyboardPortableADB:
			keyboardName = kPortableADBName;
			break;
			
		case kKeyboardADBII:
			keyboardName = kADBIIName;
			break;
			
		case kKeyboardPowerBookADB:
			keyboardName = kPowerBookADBName;
			break;
			
		case kKeyboardAdjustablePad:
			keyboardName = kAdjustableKeypadName;
			break;
			
		case kKeyboardAdjustable:
			keyboardName = kAdjustableKeyboardName;
			break;
			
		case kKeyboardPowerBookExtended:
			keyboardName = kPowerBookExtendedName;
			break;
			
		case kKeyboardSubnote:
			keyboardName = kPowerBookSubnotebookName;
			break;
			
		case kKeyboardPowerBookKeypad:
			keyboardName = kPowerBookEmbeddedKeypadName;
			break;
			
		case kKeyboardCosmo:
			keyboardName = kOriginalUSBName;
			break;
			
		case kKeyboard1999Japanese:
			keyboardName = kJapanese1999PowerBookName;
			break;
			
		case kKeyboardUSBPro:
			keyboardName = kUSBProName;
			break;
			
		case kKeyboardPowerBook2ndCmd:
			keyboardName = kPowerBook2ndCmdKeyName;
			break;
			
		case kKeyboardUSBProF16:
	 		keyboardName = kUSBProF16Name;
			break;
			
		case kKeyboardProF16:
	 		keyboardName = kProF16Name;
			break;
			
		case kKeyboardPS2:
	 		keyboardName = kPS2KeyboardName;
			break;
			
		case kKeyboardPowerBookUSB:
	 		keyboardName = kPowerBookUSBInternalName;
			break;
			
		case kKeyboardThirdParty:
	 		keyboardName = kThirdPartyName;
			break;
			
		case kKeyboardWirelessAluminium:
	 		keyboardName = kAluminiumWirelessName;
			break;
			
		case kKeyboardAluminium:
	 		keyboardName = kAluminiumAppleName;
			break;
			
		case kKeyboardMacBookLate2007:
			keyboardName = kMacBookLate2007Name;
			break;
	}
	if (keyboardName != "") {
		return NSLocalizedStringFromTable(ToNS(keyboardName), @"keyboards", @"");
	}
	return @"";
}

+ (NSString *)getKeyboardDescription:(int)keyboardID
{
	[LayoutInfo checkForInit];
	NString keyboardDesc = "";
	switch (keyboardID) {
		case kKeyboardOriginalMac:
			keyboardDesc = kOriginalMacDescription;
			break;
			
		case kKeyboardOriginalMacPad:
			keyboardDesc = kOriginalMacKeypadDescription;
			break;
			
		case kKeyboardMacPlus:
			keyboardDesc = kMacPlusDescription;
			break;
			
		case kKeyboardStandardADB:
			keyboardDesc = kExtendedADBDescription;
			break;
			
		case kKeyboardExtendedADB:
			keyboardDesc = kStandardADBDescription;
			break;
			
		case kKeyboardPortableADB:
			keyboardDesc = kPortableADBDescription;
			break;
			
		case kKeyboardADBII:
			keyboardDesc = kADBIIDescription;
			break;
			
		case kKeyboardPowerBookADB:
			keyboardDesc = kPowerBookADBDescription;
			break;
			
		case kKeyboardAdjustablePad:
			keyboardDesc = kAdjustableKeypadDescription;
			break;
			
		case kKeyboardAdjustable:
			keyboardDesc = kAdjustableKeyboardDescription;
			break;
			
		case kKeyboardPowerBookExtended:
			keyboardDesc = kPowerBookExtendedDescription;
			break;
			
		case kKeyboardSubnote:
			keyboardDesc = kPowerBookSubnotebookDescription;
			break;
			
		case kKeyboardPowerBookKeypad:
			keyboardDesc = kPowerBookEmbeddedKeypadDescription;
			break;
			
		case kKeyboardCosmo:
			keyboardDesc = kOriginalUSBDescription;
			break;
			
		case kKeyboard1999Japanese:
			keyboardDesc = kJapanese1999PowerBookDescription;
			break;
			
		case kKeyboardUSBPro:
			keyboardDesc = kUSBProDescription;
			break;
			
		case kKeyboardPowerBook2ndCmd:
			keyboardDesc = kPowerBook2ndCmdKeyDescription;
			break;
			
		case kKeyboardUSBProF16:
	 		keyboardDesc = kUSBProF16Description;
			break;
			
		case kKeyboardProF16:
	 		keyboardDesc = kProF16Description;
			break;
			
		case kKeyboardPS2:
	 		keyboardDesc = kPS2KeyboardDescription;
			break;
			
		case kKeyboardPowerBookUSB:
	 		keyboardDesc = kPowerBookUSBInternalDescription;
			break;
			
		case kKeyboardThirdParty:
	 		keyboardDesc = kThirdPartyDescription;
			break;
			
		case kKeyboardWirelessAluminium:
	 		keyboardDesc = kAluminiumWirelessDescription;
			break;
			
		case kKeyboardAluminium:
	 		keyboardDesc = kAluminiumAppleDescription;
			break;
			
		case kKeyboardMacBookLate2007:
			keyboardDesc = kMacBookLate2007Description;
			break;
	}
	if (keyboardDesc != "") {
		return NSLocalizedStringFromTable(ToNS(keyboardDesc), @"keyboards", @"");
	}
	return @"";
}

+ (NSUInteger)getModifierFromKeyCode:(NSUInteger)keyCode
{
	NSUInteger result = 0;
	switch (keyCode) {
		case kKeyCapsLock:
			result = NSAlphaShiftKeyMask;
			break;
			
		case kKeyShift:
		case kKeyRightShift:
			result = NSShiftKeyMask;
			break;
			
		case kKeyOption:
		case kKeyRightOption:
			result = NSAlternateKeyMask;
			break;
			
		case kKeyCommand:
		case kKeyRightCommand:
			result = NSCommandKeyMask;
			break;
		
		case kKeyControl:
		case kKeyRightControl:
			result = NSControlKeyMask;
			break;
	}
	return result;
}

#pragma mark Instance methods

- (BOOL)hasFnKey
{
	return flags & kHasFnKey;
}

- (BOOL)hasSeparateRightKeys
{
	return flags & kHasSeparateRightKeys;
}

- (unsigned int)getFnKeyCodeForKey:(unsigned int)keyCode
{
	unsigned int fnKeyCode;
	if ((flags & kHasFnKey) && (flags & kHasEmbeddedKeypad)) {
		switch (keyCode) {
			case kKey6:
				fnKeyCode = kKeyPadClear;
				break;
				
			case kKey7:
				fnKeyCode = kKeyPad7;
				break;
				
			case kKey8:
				fnKeyCode = kKeyPad8;
				break;
				
			case kKey9:
				fnKeyCode = kKeyPad9;
				break;
				
			case kKey0:
				fnKeyCode = kKeyPadSlash;
				break;
				
			case kKeyMinus:
				fnKeyCode = kKeyPadEquals;
				break;
				
			case kKeyU:
				fnKeyCode = kKeyPad4;
				break;
				
			case kKeyI:
				fnKeyCode = kKeyPad5;
				break;
				
			case kKeyO:
				fnKeyCode = kKeyPad6;
				break;
				
			case kKeyP:
				fnKeyCode = kKeyPadStar;
				break;
				
			case kKeyJ:
				fnKeyCode = kKeyPad1;
				break;
				
			case kKeyK:
				fnKeyCode = kKeyPad2;
				break;
				
			case kKeyL:
				fnKeyCode = kKeyPad3;
				break;
				
			case kKeySemicolon:
				fnKeyCode = kKeyPadMinus;
				break;
				
			case kKeyM:
				fnKeyCode = kKeyPad0;
				break;
				
			case kKeyDot:
				fnKeyCode = kKeyPadDot;
				break;
				
			case kKeySlash:
				fnKeyCode = kKeyPadPlus;
				break;
				
			case kKeyReturn:
				fnKeyCode = kKeyEnter;
				break;
				
			case kKeyUpArrow:
				fnKeyCode = kKeyPageUp;
				break;
				
			case kKeyDownArrow:
				fnKeyCode = kKeyPageDown;
				break;
				
			case kKeyLeftArrow:
				fnKeyCode = kKeyHome;
				break;
				
			case kKeyRightArrow:
				fnKeyCode = kKeyEnd;
				break;
				
			case kKeyDelete:
				fnKeyCode = kKeyForwardDelete;
				break;
				
			default:
				fnKeyCode = keyCode;
				break;
		}
	}
	else if (flags & kHasFnKey) {
		switch (keyCode) {
			case kKeyReturn:
				fnKeyCode = kKeyEnter;
				break;
				
			case kKeyUpArrow:
				fnKeyCode = kKeyPageUp;
				break;
				
			case kKeyDownArrow:
				fnKeyCode = kKeyPageDown;
				break;
				
			case kKeyLeftArrow:
				fnKeyCode = kKeyHome;
				break;
				
			case kKeyRightArrow:
				fnKeyCode = kKeyEnd;
				break;
				
			case kKeyDelete:
				fnKeyCode = kKeyForwardDelete;
				break;
				
			default:
				fnKeyCode = keyCode;
				break;
		}
	}
	else {
		fnKeyCode = keyCode;
	}
	return fnKeyCode;
}

- (unsigned int)getLeftModifierKey:(unsigned int)rightModifierKey
{
	unsigned int leftModifierKey = rightModifierKey;
	switch (rightModifierKey) {
		case kKeyRightShift:
			leftModifierKey = kKeyShift;
			break;
			
		case kKeyRightControl:
			leftModifierKey = kKeyControl;
			break;
			
		case kKeyRightCommand:
			leftModifierKey = kKeyCommand;
			break;
			
		case kKeyRightOption:
			leftModifierKey = kKeyOption;
			break;
	}
	return leftModifierKey;
}

- (unsigned int)getRightModifierKey:(unsigned int)leftModifierKey
{
	unsigned int rightModifierKey = leftModifierKey;
	switch (leftModifierKey) {
		case kKeyShift:
			rightModifierKey = kKeyRightShift;
			break;
			
		case kKeyControl:
			rightModifierKey = kKeyRightControl;
			break;
			
		case kKeyCommand:
			rightModifierKey = kKeyRightCommand;
			break;
			
		case kKeyOption:
			rightModifierKey = kKeyRightOption;
			break;
	}
	return rightModifierKey;
}

- (unsigned int)getCarbonModifierFromKeyCode:(unsigned int)keyCode
{
	unsigned int modifierMask = 0;
	switch (keyCode) {
		case kKeyCapsLock:
			modifierMask = alphaLock;
			break;
			
		case kKeyShift:
			modifierMask = shiftKey;
			break;
			
		case kKeyControl:
			modifierMask = controlKey;
			break;
			
		case kKeyOption:
			modifierMask = optionKey;
			break;
			
		case kKeyCommand:
		case kKeyRightCommand:
			modifierMask = cmdKey;
			break;
			
		case kKeyRightOption:
			if ([self hasSeparateRightKeys]) {
				modifierMask = rightOptionKey;
			}
			else {
				modifierMask = optionKey;
			}
			break;
			
		case kKeyRightControl:
			if ([self hasSeparateRightKeys]) {
				modifierMask = rightControlKey;
			}
			else {
				modifierMask = controlKey;
			}
			break;
			
		case kKeyRightShift:
			if ([self hasSeparateRightKeys]) {
				modifierMask = rightShiftKey;
			}
			else {
				modifierMask = shiftKey;
			}
			break;
			
		case kKeyFn:
			modifierMask = kEventKeyModifierFnMask;
			break;
	}
	return modifierMask;
}

@end

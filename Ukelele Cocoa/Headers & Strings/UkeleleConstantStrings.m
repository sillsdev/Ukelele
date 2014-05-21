/*
 *  UkeleleConstantStrings.m
 *  Ukelele 3
 *
 *  Created by John Brownie on 15/05/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#include "UkeleleConstantStrings.h"

NSString *kLabelIndex = @"Index";
NSString *kLabelShift = @"Shift";
NSString *kLabelOption = @"Option";
NSString *kLabelCommand = @"Command";
NSString *kLabelCapsLock = @"Caps Lock";
NSString *kLabelControl = @"Control";
NSString *kLabelSubindex = @"Subindex";

NSString *kStateNameNone = @"none";

NSString *kCodeStringANSI = @"ANSI";
NSString *kCodeStringISO = @"ISO";
NSString *kCodeStringJIS = @"JIS";

// Keys for data dictionaries
NSString *kKeyDocument = @"Document";
NSString *kKeyKeyboardID = @"KeyboardID";
NSString *kKeyKeyCode = @"KeyCode";
NSString *kKeyModifiers = @"Modifiers";
NSString *kKeyState = @"State";
NSString *kKeyANSIType = @"ANSI";
NSString *kKeyISOType = @"ISO";
NSString *kKeyJISType = @"JIS";
NSString *kKeyAllTypes = @"All";
NSString *kKeyKeyboardObject = @"KeyboardObject";
NSString *kKeyKeyType = @"KeyType";
NSString *kKeyKeyOutput = @"KeyOutput";
NSString *kKeyNextState = @"NextState";
NSString *kKeyTerminator = @"Terminator";

	// Keys for state variables

NSString *kStateCurrentState = @"CurrentState";         // NSString, current dead key state
NSString *kStateCurrentKeyboard = @"CurrentKeyboard";   // NSUInteger, current keyboard ID
NSString *kStateCurrentScale = @"CurrentScale";         // double, current view scale
NSString *kStateCurrentModifiers = @"CurrentModifiers"; // NSUInteger, current modifier combination
NSString *kStateTargetKeyCode = @"TargetKeyCode";       // NSInteger, key code for current key
NSString *kStateModifiersInfo = @"ModifiersInfo";       // ModifiersInfo, modifiers currently being edited/added

	// Names for tabs
NSString *kTabNameKeyboard = @"Keyboard";
NSString *kTabNameModifiers = @"Modifiers";
NSString *kTabNameComments = @"Comments";

// Common strings
NSString *kDomainUkelele = @"org.sil.ukelele";

	// Messages
NSString *kMessageNameKey = @"MessageName";
NSString *kMessageArgumentKey = @"MessageArgument";
NSString *kMessageClick = @"Click";
NSString *kMessageKeyDown = @"KeyDown";

	// Bundle strings
NSString *kFileTypeKeyboardLayout = @"org.sil.ukelele.keyboardlayout";
NSString *kStringBundleExtension = @".bundle";
NSString *kStringContentsName = @"Contents";
NSString *kStringResourcesName = @"Resources";
NSString *kStringEnglishLocalisationName = @"English.lproj";
NSString *kStringInfoPlistStringsName = @"InfoPlist.strings";
NSString *kStringIcnsExtension = @"icns";
NSString *kStringKeyboardLayoutExtension = @"keylayout";
NSString *kStringAppleKeyboardLayoutBundleID = @"com.apple.keyboardlayout.";
NSString *kStringUkeleleKeyboardLayoutBundleID = @"org.sil.ukelele.keyboardlayout.";
NSString *kStringInfoPlistFileName = @"Info.plist";
NSString *kStringVersionPlistFileName = @"version.plist";
NSString *kStringBuildVersionKey = @"BuildVersion";
NSString *kStringProjectNameKey = @"ProjectName";
NSString *kStringSourceVersionKey = @"SourceVersion";
NSString *kStringInfoPlistKLInfoPrefix = @"KLInfo_";
NSString *kStringInfoPlistInputSourceID = @"TISInputSourceID";
NSString *kStringInfoPlistIntendedLanguageKey = @"TISIntendedLanguage";

	// Preference keys
NSString *UKScaleFactor = @"ScaleFactor";
NSString *UKTextSize = @"TextSize";
NSString *UKTextFont = @"TextFont";
NSString *UKUsesSingleClickToEdit = @"UsesSingleClickToEdit";
NSString *UKDefaultLayoutID = @"DefaultLayoutID";
NSString *UKAlwaysUsesDefaultLayout = @"AlwaysUsesDefaultLayout";
NSString *UKColourThemes = @"ColourThemes";
NSString *UKColourTheme = @"ColourTheme";
NSString *UKAskStateName = @"AskStateName";
NSString *UKStateNameBase = @"StateNameBase";
NSString *UKDiacriticDisplayCharacter = @"DiacriticDisplayCharacter";
NSString *UKUsesPopover = @"UsesPopover";
NSString *UKTigerCompatibleBundles = @"TigerCompatibleBundles";
NSString *UKCodeNonAscii = @"CodeNonAscii";

/*
 *  UkeleleStrings.h
 *  Ukelele 3
 *
 *  Created by John Brownie on 9/02/11.
 *  Copyright 2011 SIL. All rights reserved.
 *
 */

#ifndef _UKELELESTRINGS_H_
#define _UKELELESTRINGS_H_

#include "NString.h"

	// When element
const NString kWhenElement("when");
const NString kStateAttribute("state");
const NString kOutputAttribute("output");
const NString kNextAttribute("next");
const NString kThroughAttribute("through");
const NString kMultiplierAttribute("multiplier");

	// Action element
const NString kActionElement("action");
const NString kIDAttribute("id");

	// Terminators element
const NString kTerminatorsElement("terminators");

	// Layout element
const NString kLayoutElement("layout");
const NString kFirstAttribute("first");
const NString kLastAttribute("last");
const NString kModifiersAttribute("modifiers");
const NString kMapSetAttribute("mapSet");

	// Layouts element
const NString kLayoutsElement("layouts");

	// Modifier element
const NString kModifierElement("modifier");
const NString kKeysAttribute("keys");

	// KeyMapSelect element
const NString kKeyMapSelectElement("keyMapSelect");
const NString kMapIndexAttribute("mapIndex");

	// ModifierMap element
const NString kModifierMapElement("modifierMap");
const NString kDefaultIndexAttribute("defaultIndex");

	// Key element
const NString kKeyElement("key");
const NString kCodeAttribute("code");
const NString kActionAttribute("action");

	// KeyMap element
const NString kKeyMapElement("keyMap");
const NString kIndexAttribute("index");
const NString kBaseMapSetAttribute("baseMapSet");
const NString kBaseIndexAttribute("baseIndex");

	// KeyMapSet element
const NString kKeyMapSetElement("keyMapSet");

	// Actions element
const NString kActionsElement("actions");

	// Keyboard element
const NString kKeyboardElement("keyboard");
const NString kGroupAttribute("group");
const NString kNameAttribute("name");
const NString kMaxoutAttribute("maxout");

	// Assorted default names
const NString kANSIKeyMapName("ANSI");
const NString kISOKeyMapName("ISO");
const NString kJISKeyMapName("JIS");
const NString kDefaultModifiersName("Modifiers");
const NString kStateNone("none");
const NString kStringANSI("ANSI");
const NString kStringISO("ISO");
const NString kStringJIS("JIS");

	// Modifier key strings
const NString kShiftKey("shift");
const NString kRightShiftKey("rightShift");
const NString kAnyShiftKey("anyShift");
const NString kOptionKey("option");
const NString kRightOptionKey("rightOption");
const NString kAnyOptionKey("anyOption");
const NString kControlKey("control");
const NString kRightControlKey("rightControl");
const NString kAnyControlKey("anyControl");
const NString kCommandKey("command");
const NString kCapsLockKey("caps");
const NString kShiftKeyOpt("shift?");
const NString kRightShiftKeyOpt("rightShift?");
const NString kAnyShiftKeyOpt("anyShift?");
const NString kOptionKeyOpt("option?");
const NString kRightOptionKeyOpt("rightOption?");
const NString kAnyOptionKeyOpt("anyOption?");
const NString kControlKeyOpt("control?");
const NString kRightControlKeyOpt("rightControl?");
const NString kAnyControlKeyOpt("anyControl?");
const NString kCommandKeyOpt("command?");
const NString kCapsLockKeyOpt("caps?");

	// Basic set of modifier maps
const NString kNoModifiers("");
const NString kShiftOnly("anyShift caps?");
const NString kOptionOnly("anyOption");
const NString kCapsLockOnly("caps");
const NString kShiftOption("anyShift anyOption caps?");

	// XML strings
const NString kDefaultXMLHeader("version=\"1.1\" encoding=\"UTF-8\"");
const NString kDefaultDTD("file://localhost/System/Library/DTDs/KeyboardLayout.dtd");
const NString kDefaultXMLTarget("XML");
const NString kDefaultXMLName("keyboard");
const NString kDefaultKeyboardName("untitled");

	// Date stamp comments in XML file
const NString kCreationComment("Created by Ukelele version ");
const NString kEditComment("Last edited by Ukelele version ");
const NString kDateStamp(" on %4d-%02d-%02d at %02d:%02d (%@)");

	// Bundle strings
const NString kBundleExtension(".bundle");
const NString kContentsName("Contents");
const NString kResourcesName("Resources");
const NString kEnglishLocalisationName("English.lproj");
const NString kInfoPlistStringsFileName("InfoPlist.strings");
const NString kIcnsExtension(".icns");
const NString kKeyboardLayoutExtension(".keylayout");
const NString kAppleKeyboardLayoutBundleID("com.apple.keyboardlayout.");
const NString kInfoPlistFileName("Info.plist");
const NString kVersionPlistFileName("version.plist");
const NString kBuildVersionKey("BuildVersion");
const NString kProjectNameKey("ProjectName");
const NString kSourceVersionKey("SourceVersion");

	// Theme file
const NString kColourThemePlistFileName("ColourThemes.plist");

	// Miscellaneous string
const NString kWhitespaceSet(" \t\r\n");

#endif /* _UKELELESTRINGS_H_ */

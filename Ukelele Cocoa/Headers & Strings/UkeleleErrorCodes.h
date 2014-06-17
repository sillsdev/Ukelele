//
//  UkeleleErrorCodes.h
//  Ukelele 3
//
//  Created by John Brownie on 26/08/11.
//  Copyright 2011 SIL. All rights reserved.
//

#ifndef Ukelele_3_UkeleleErrorCodes_h
#define Ukelele_3_UkeleleErrorCodes_h

enum UkeleleErrors {
    kUkeleleErrorNone = 0,
    kUkeleleErrorMalformedXML = -10,				// kNErrMalformed
	kUkeleleErrorNotKeyboardLayoutBundle = -11,		// Not a valid bundle format
	kUkeleleErrorCouldNotCreateFromFile = -12,		// Generic error that we couldn't create the keyboard layout
	kUkeleleErrorKeyboardLayoutsFileExists = -13,	// Can't create the Keyboard Layouts folder because a file of that name already exists
	kUkeleleErrorCouldNotCreateKeyboardLayouts = -14,	// Could not create the Keyboard Layouts folder
	kUkeleleErrorCouldNotSaveInInstallDirectory = -15,	// Could not copy the file to the Keyboard Layouts folder
	kUkeleleErrorAuthenticationFailed = -16,		// Authentication failed for install
	kUkeleleErrorNotPlainFile = -17,				// Not a plain file for a keyboard layout
	kUkeleleErrorInvalidFileType = -18				// Invalid UTI given
};

#endif

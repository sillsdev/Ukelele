//
//  UKKeyboardDocument.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 13/06/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import "UKKeyboardDocument.h"
#import "UKKeyboardWindow.h"
#import "LanguageCode.h"
#import "UkeleleBundleVersionSheet.h"
#import "IntendedLanguageSheet.h"
#import "AskFromList.h"
#import "KeyboardLayoutInformation.h"
#import "UkeleleConstantStrings.h"
#import "UkeleleErrorCodes.h"
#import "ScriptInfo.h"
#import "InspectorWindowController.h"
#import <Carbon/Carbon.h>

#define UKKeyboardWindowNibName @"UkeleleDocument"

	// Dictionary keys
NSString *kIconFileKey = @"IconFile";
NSString *kKeyboardObjectKey = @"KeyboardObject";
NSString *kKeyboardNameKey = @"KeyboardName";
NSString *kKeyboardWindowKey = @"KeyboardWindow";
NSString *kKeyboardFileNameKey = @"KeyboardFileName";

@implementation UKKeyboardDocument {
	NSMutableArray *keyboardLayouts;
	UkeleleBundleVersionSheet *bundleVersionSheet;
	IntendedLanguageSheet *intendedLanguageSheet;
	AskFromList *askFromListSheet;
	NSMutableDictionary *languageList;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
		_isBundle = NO;
		_keyboardLayout = nil;
		keyboardLayouts = [NSMutableArray array];
		bundleVersionSheet = nil;
		intendedLanguageSheet = nil;
		askFromListSheet = nil;
		languageList = [NSMutableDictionary dictionary];
		_buildVersion = @"";
		_bundleVersion = @"";
		_sourceVersion = @"";
		_bundleName = @"";
		_bundleIdentifier = @"";
    }
    return self;
}

/*
- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return <#nibName#>;
}
*/

- (void)makeWindowControllers {
	if (!self.isBundle) {
			// Stand-alone keyboard layout
		UKKeyboardWindow *keyboardWindow = [[UKKeyboardWindow alloc] initWithWindowNibName:UKKeyboardWindowNibName];
		[self addWindowController:keyboardWindow];
	}
	else {
		NSWindowController *windowController = [[NSWindowController alloc] initWithWindowNibName:@"UKKeyboardLayoutBundle" owner:self];
		[self addWindowController:windowController];
	}
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
	if ([aController isKindOfClass:[UKKeyboardDocument class]]) {
		[keyboardLayoutsTable registerForDraggedTypes:@[NSURLPboardType]];
	}
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
	if ([typeName isEqualToString:kFileTypeKeyboardLayout]) {
			// This is an unbundled keyboard layout document
		self.isBundle = NO;
		return [self parseKeyboardFileWrapper:fileWrapper withError:outError];
	}
	else if ([typeName isEqualToString:(NSString *)kUTTypeBundle] || [typeName isEqualToString:@"com.apple.generic-bundle"]) {
			// This is a bundle, hopefully a keyboard layout bundle;
		BOOL success = [self parseBundleFileWrapper:fileWrapper withError:outError];
		if (success) {
			self.isBundle = YES;
		}
		return success;
	}
		// Not a valid type
	if (outError != nil) {
		NSDictionary *errorDict = @{NSLocalizedDescriptionKey: @"Invalid type for read operation"};
		*outError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorInvalidFileType userInfo:errorDict];
	}
	return NO;
}

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError *__autoreleasing *)outError {
	if ([typeName isEqualToString:kFileTypeKeyboardLayout]) {
			// This is an unbundled keyboard layout document
		return [self saveKeyboardLayoutToURL:url error:outError];
	}
	else if ([typeName isEqualToString:(NSString *)kUTTypeBundle] || [typeName isEqualToString:@"com.apple.generic-bundle"]) {
			// A bundle
		if (absoluteOriginalContentsURL != nil) {
				// Try to save only what has changed
		}
		NSFileWrapper *keyboardWrapper = [self createFileWrapper];
		return [keyboardWrapper writeToURL:url options:0 originalContentsURL:nil error:outError];
	}
		// Not a valid type
	if (outError != nil) {
		NSDictionary *errorDict = @{NSLocalizedDescriptionKey: @"Invalid type for save operation"};
		*outError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorInvalidFileType userInfo:errorDict];
	}
	return NO;
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

#pragma mark Capturing input source

- (UkeleleKeyboardObject *)keyboardFromCurrentInputSourceWithError:(NSError **)outError {
		// Create a temporary file
	NSString *tempFilePath = [NSString stringWithFormat:@"%@UkeleleDataXXXXX.rsrc", NSTemporaryDirectory()];
	char tempFileTemplate[1025];
	[tempFilePath getCString:tempFileTemplate maxLength:1024 encoding:NSUTF8StringEncoding];
	int tempFileDescriptor = mkstemps(tempFileTemplate, 5);
	if (tempFileDescriptor == -1) {
			// Could not create temporary file
		return nil;
	}
	tempFilePath = @(tempFileTemplate);
	NSFileHandle *tempFileHandle = [[NSFileHandle alloc] initWithFileDescriptor:tempFileDescriptor closeOnDealloc:YES];
	NSURL *tempFileURL = [NSURL fileURLWithPath:tempFilePath];
		// Capture the current keyboard layout as uchr data
	TISInputSourceRef currentInputSource = TISCopyCurrentKeyboardLayoutInputSource();
	CFDataRef uchrData = TISGetInputSourceProperty(currentInputSource, kTISPropertyUnicodeKeyLayoutData);
	if (NULL == uchrData) {
			// Could not get the current input source as uchr data
		return nil;
	}
		// Get the keyboard's name
	CFStringRef keyboardName = TISGetInputSourceProperty(currentInputSource, kTISPropertyLocalizedName);
		// We now have to muck around in old code to create a resource file
	Str255 resourceName;
	CFStringGetPascalString(keyboardName, resourceName, 256, kCFStringEncodingMacRoman);
	CFURLRef parentURL = CFURLCreateCopyDeletingLastPathComponent(kCFAllocatorDefault, (CFURLRef)tempFileURL);
	FSRef parentRef;
	Boolean gotFSRef = CFURLGetFSRef(parentURL, &parentRef);
	if (!gotFSRef) {
		CFRelease(parentURL);
		return nil;
	}
	CFStringRef tempFileName = CFURLCopyLastPathComponent((CFURLRef)tempFileURL);
	FSRef tempFileRef;
	HFSUniStr255 forkName;
	OSStatus theErr = FSGetResourceForkName(&forkName);
	NSAssert(theErr == noErr, @"Could not get resource fork");
	UniChar tempFileBuffer[1024];
	CFStringGetCharacters(tempFileName, CFRangeMake(0, CFStringGetLength(tempFileName)), tempFileBuffer);
	theErr = FSCreateResourceFile(&parentRef, CFStringGetLength(tempFileName), tempFileBuffer, kFSCatInfoNone, NULL, forkName.length, forkName.unicode, &tempFileRef, NULL);
	NSAssert(theErr == noErr, @"Could not create resource file");
	ResFileRefNum resFile;
	theErr = FSOpenResourceFile(&tempFileRef, forkName.length, forkName.unicode, fsWrPerm, &resFile);
	NSAssert(theErr == noErr, @"Could not open resource file");
	Handle theHandle = NewHandle(CFDataGetLength(uchrData));
	memcpy(*theHandle, CFDataGetBytePtr(uchrData), CFDataGetLength(uchrData));
	AddResource(theHandle, 'uchr', UniqueID('uchr'), resourceName);
	UpdateResFile(CurResFile());
	FSCloseFork(resFile);
		// Get the conversion tool
	NSURL *toolURL = [[NSBundle mainBundle] URLForAuxiliaryExecutable:@"kluchrtoxml"];
		// Set up and run the tool
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *currentDirectory = [fileManager currentDirectoryPath];
	[fileManager changeCurrentDirectoryPath:[(__bridge NSURL *)parentURL path]];
	NSTask *conversionTask = [NSTask launchedTaskWithLaunchPath:[toolURL path] arguments:@[[tempFileURL path]]];
	[conversionTask waitUntilExit];
	int returnStatus = [conversionTask terminationStatus];
	NSAssert(returnStatus == 0 || returnStatus == EINTR, @"Could not run conversion tool");
	CFRelease(tempFileName);
	CFRelease(parentURL);
	tempFileHandle = nil;
	[fileManager changeCurrentDirectoryPath:currentDirectory];
		// Finally, read the resulting file
	NSURL *outputFileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@.keylayout", NSTemporaryDirectory(), keyboardName]];
	NSError *theError;
	NSData *myData = [NSData dataWithContentsOfURL:outputFileURL options:0 error:&theError];
	if (myData == nil || [myData length] == 0) {
		if (*outError != nil) {
			*outError = theError;
		}
		return nil;
	}
	return [[UkeleleKeyboardObject alloc] initWithData:myData withError:outError];
}

#pragma mark File wrapper methods

- (BOOL)saveKeyboardLayoutToURL:(NSURL *)fileURL error:(NSError **)outError {
	NSAssert(!self.isBundle, @"Attempt to save a bundle as a plain file");
	NSData *keyboardData = [self.keyboardLayout convertToData];
	return [keyboardData writeToURL:fileURL options:0 error:outError];
}

- (NSFileWrapper *)createFileWrapper {
	NSLog(@"Creating file wrapper");
		// Start at the bottom, the InfoPlist.strings file, which contains all the names
	NSMutableString *infoPlistString = [NSMutableString stringWithString:@""];
	for (KeyboardLayoutInformation *keyboardEntry in keyboardLayouts) {
		NSString *keyboardName = [keyboardEntry keyboardName];
		if (keyboardName != nil && ![keyboardName isEqualToString:@""]) {
			[infoPlistString appendString:[NSString stringWithFormat:@"\"%@\" = \"%@\";\n", keyboardName, keyboardName]];
		}
	}
	NSData *infoPlistData = [infoPlistString dataUsingEncoding:NSUTF16StringEncoding];
	NSFileWrapper *infoPlistStringsFile = [[NSFileWrapper alloc] initRegularFileWithContents:infoPlistData];
	[infoPlistStringsFile setPreferredFilename:kStringInfoPlistStringsName];
		// Put the InfoPlist.strings file into an English.lproj directory
	NSFileWrapper *englishLprojDirectory = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
	[englishLprojDirectory setPreferredFilename:kStringEnglishLocalisationName];
	[englishLprojDirectory addFileWrapper:infoPlistStringsFile];
		// Create the version.plist file
	NSMutableDictionary *versionPlistDictionary = [NSMutableDictionary dictionary];
	versionPlistDictionary[kStringBuildVersionKey] = _buildVersion;
	versionPlistDictionary[kStringSourceVersionKey] = _sourceVersion;
	versionPlistDictionary[kStringProjectNameKey] = _bundleName;
	NSString *error;
	NSFileWrapper *versionPlistFile = [[NSFileWrapper alloc] initRegularFileWithContents:
									   [NSPropertyListSerialization dataFromPropertyList:versionPlistDictionary
																				  format:NSPropertyListXMLFormat_v1_0
																		errorDescription:&error]];
	[versionPlistFile setPreferredFilename:kStringVersionPlistFileName];
		// Create the Resources directory
	NSFileWrapper *resourcesDirectory = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
	[resourcesDirectory setPreferredFilename:kStringResourcesName];
	[resourcesDirectory addFileWrapper:englishLprojDirectory];
	dispatch_queue_t mainQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		// Add all the keyboard layout and icon files
	for (KeyboardLayoutInformation *keyboardEntry in keyboardLayouts) {
		NSString *keyboardName = [keyboardEntry fileName];
		if (nil == keyboardName || [keyboardName isEqualToString:@""]) {
			keyboardName = [keyboardEntry keyboardName];
		}
		NSLog(@"Saving keyboard layout %@", keyboardName);
		NSString *keyboardFileName = [NSString stringWithFormat:@"%@.%@", keyboardName, kStringKeyboardLayoutExtension];
		NSLog(@"Write file");
		NSData *fileData = [[keyboardEntry keyboardObject] convertToData];
		dispatch_async(mainQueue, ^void(void) {
			[resourcesDirectory addRegularFileWithContents:fileData
										 preferredFilename:keyboardFileName];
		});
		NSLog(@"End write file");
//		if ([[keyboardEntry fileName] isEqualToString:@""] && [self fileURL] != nil) {
//			NSLog(@"New file to be noted");
//				// The keyboard has not yet been saved
//			NSURL *bundleURL = [self fileURL];
//			NSURL *keyboardURL = [[[bundleURL URLByAppendingPathComponent:kStringContentsName isDirectory:YES]
//								   URLByAppendingPathComponent:kStringResourcesName isDirectory:YES]
//								  URLByAppendingPathComponent:keyboardFileName isDirectory:NO];
//			[[keyboardEntry document] setFileURL:keyboardURL];
//			[[keyboardEntry document] setDisplayName:keyboardName];
//		}
		if ([keyboardEntry hasIcon]) {
			NSLog(@"Writing icon file");
			NSString *iconFileName = [NSString stringWithFormat:@"%@.%@", keyboardName, kStringIcnsExtension];
			[resourcesDirectory addRegularFileWithContents:[keyboardEntry iconData] preferredFilename:iconFileName];
		}
		NSLog(@"Finished saving keyboard layout");
	}
		// Create the Info.plist file
	NSDictionary *infoPlist = [self createInfoPlist];
	NSFileWrapper *infoPlistFile = [[NSFileWrapper alloc] initRegularFileWithContents:
									[NSPropertyListSerialization dataFromPropertyList:infoPlist
																			   format:NSPropertyListXMLFormat_v1_0
																	 errorDescription:&error]];
	[infoPlistFile setPreferredFilename:kStringInfoPlistFileName];
		// Create the Contents directory
	NSFileWrapper *contentsDirectory = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
	[contentsDirectory setPreferredFilename:kStringContentsName];
	[contentsDirectory addFileWrapper:infoPlistFile];
	[contentsDirectory addFileWrapper:versionPlistFile];
	[contentsDirectory addFileWrapper:resourcesDirectory];
		// Create the top level directory
	NSFileWrapper *topFileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
	[topFileWrapper addFileWrapper:contentsDirectory];
	NSString *bundleName = [NSString stringWithFormat:@"%@.bundle", _bundleName];
	[topFileWrapper setPreferredFilename:bundleName];
	NSLog(@"Finished creating file wrapper");
	return topFileWrapper;
}

- (NSDictionary *)createInfoPlist {
	NSMutableDictionary *infoPlist = [NSMutableDictionary dictionary];
	if ([_bundleIdentifier isEqualToString:@""]) {
			// Create the bundle identifier
		BOOL tigerCompatibleBundleIdentifier = [[NSUserDefaults standardUserDefaults] boolForKey:UKTigerCompatibleBundles];
		NSString *baseString = tigerCompatibleBundleIdentifier ? kStringAppleKeyboardLayoutBundleID : kStringUkeleleKeyboardLayoutBundleID;
		NSString *extensionString = [[_bundleName lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
		_bundleIdentifier = [baseString stringByAppendingString:extensionString];
	}
	infoPlist[@"CFBundleIdentifier"] = _bundleIdentifier;
		// Set the bundle name
	infoPlist[@"CFBundleName"] = _bundleName;
		// Set the version number
	infoPlist[(NSString *)kCFBundleVersionKey] = _bundleVersion;
		// Get the intended languages for each keyboard layout in the bundle
	for (KeyboardLayoutInformation *keyboardEntry in keyboardLayouts) {
		NSString *languageIdentifier = [keyboardEntry intendedLanguage];
		if (nil != languageIdentifier) {
				// Add this language identifier
			NSString *keyboardName = [keyboardEntry keyboardName];
			NSString *KLInfoIdentifier = [NSString stringWithFormat:@"%@%@", kStringInfoPlistKLInfoPrefix, [keyboardEntry fileName]];
			NSString *keyboardIdentifier = [NSString stringWithFormat:@"%@.%@", _bundleIdentifier, [[keyboardName lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""]];
			NSDictionary *languageDictionary = @{kStringInfoPlistInputSourceID: keyboardIdentifier,
												 kStringInfoPlistIntendedLanguageKey: languageIdentifier};
			infoPlist[KLInfoIdentifier] = languageDictionary;
		}
	}
	return infoPlist;
}

- (BOOL)parseKeyboardFileWrapper:(NSFileWrapper *)theFileWrapper withError:(NSError **)outError {
	NSDictionary *errorDictionary;
	if (![theFileWrapper isRegularFile]) {
			// Not a plain file
		if (outError != nil) {
			errorDictionary = @{NSLocalizedDescriptionKey: @"Keyboard layout is not an ordinary file"};
			*outError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorNotPlainFile userInfo:errorDictionary];
		}
		return NO;
	}
	NSData *fileData = [theFileWrapper regularFileContents];
	if (fileData == nil || [fileData length] == 0) {
			// No valid data
		if (outError != nil) {
			errorDictionary = @{NSLocalizedDescriptionKey: @"Could not read the file"};
			*outError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorCouldNotCreateFromFile userInfo:errorDictionary];
		}
		return NO;
	}
	UkeleleKeyboardObject *theKeyboard = [[UkeleleKeyboardObject alloc] initWithData:fileData withError:outError];
	if (theKeyboard != nil) {
		self.keyboardLayout = theKeyboard;
		[theKeyboard setParentDocument:self];
		return YES;
	}
		// No valid keyboard layout created, outError is already set
	return NO;
}

- (BOOL)parseBundleFileWrapper:(NSFileWrapper *)theFileWrapper withError:(NSError **)error {
	NSLog(@"Reading file wrapper %@", theFileWrapper);
	NSDictionary *errorDictionary = nil;
		// Check that it is actually a directory
	if (![theFileWrapper isDirectory]) {
		errorDictionary = @{NSLocalizedDescriptionKey: @"The selected bundle is not a valid bundle"};
		*error = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorNotKeyboardLayoutBundle userInfo:errorDictionary];
		return NO;
	}
	self.bundleName = [[theFileWrapper filename] stringByDeletingPathExtension];
	[self setDisplayName:self.bundleName];
	NSDictionary *directoryContents = [theFileWrapper fileWrappers];
	NSEnumerator *directoryEnumerator = [directoryContents objectEnumerator];
	NSFileWrapper *directoryEntry;
	while ((directoryEntry = [directoryEnumerator nextObject])) {
			// Check that it's the Contents directory
		if ([[directoryEntry preferredFilename] isEqualToString:kStringContentsName]) {
				// Got the right directory
			break;
		}
	}
	if (directoryEntry == nil) {
			// Failed to get the Contents directory
		errorDictionary = @{NSLocalizedDescriptionKey: @"The selected bundle is not a valid bundle"};
		if (error != NULL) {
			*error = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorNotKeyboardLayoutBundle userInfo:errorDictionary];
		}
		return NO;
	}
		// Now get the Info.plist file and the Resources directory
	directoryContents = [directoryEntry fileWrappers];
	directoryEnumerator = [directoryContents objectEnumerator];
	NSFileWrapper *infoPlistFile = nil;
	NSFileWrapper *resourcesDirectory = nil;
	NSFileWrapper *versionPlist = nil;
	while ((directoryEntry = [directoryEnumerator nextObject])) {
		if ([[directoryEntry preferredFilename] isEqualToString:kStringInfoPlistFileName]) {
				// Got the Info.plist file
			infoPlistFile = directoryEntry;
			[self parseInfoPlist:infoPlistFile];
		}
		else if ([[directoryEntry preferredFilename] isEqualToString:kStringResourcesName]) {
				// Got the Resources directory
			resourcesDirectory = directoryEntry;
		}
		else if ([[directoryEntry preferredFilename] isEqualToString:kStringVersionPlistFileName]) {
				// Got the version.plist file
			versionPlist = directoryEntry;
		}
	}
	if (versionPlist != nil) {
			// Handle the version.plist file
		NSDictionary *versionPlistDictionary = [NSPropertyListSerialization propertyListWithData:[versionPlist regularFileContents]
																						 options:NSPropertyListImmutable
																						  format:nil
																						   error:error];
		if (versionPlistDictionary != nil) {
			self.buildVersion = versionPlistDictionary[kStringBuildVersionKey];
			self.sourceVersion = versionPlistDictionary[kStringSourceVersionKey];
		}
	}
		// Now scan the Resources directory for keyboard layouts and icons
	directoryContents = [resourcesDirectory fileWrappers];
	directoryEnumerator = [directoryContents objectEnumerator];
	NSMutableDictionary *fileNameDictionary = [NSMutableDictionary dictionary];
	NSFileWrapper *infoPlistStringsFile = nil;
	while ((directoryEntry = [directoryEnumerator nextObject])) {
		NSString *fileName = [directoryEntry preferredFilename];
		BOOL isKeyboardLayout = [fileName hasSuffix:[NSString stringWithFormat:@".%@", kStringKeyboardLayoutExtension]];
		BOOL isIconFile = [fileName hasSuffix:[NSString stringWithFormat:@".%@", kStringIcnsExtension]];
		if ([fileName isEqualToString:kStringEnglishLocalisationName]) {
				// It's the English.lproj folder, so we check into it for infoPlist.strings and version.plist
			NSDictionary *englishContents = [directoryEntry fileWrappers];
			NSEnumerator *englishEnumerator = [englishContents objectEnumerator];
			NSFileWrapper *englishEntry;
			while ((englishEntry = [englishEnumerator nextObject])) {
				if ([[englishEntry preferredFilename] isEqualToString:kStringInfoPlistStringsName]) {
					infoPlistStringsFile = englishEntry;
				}
			}
		}
		else if (isKeyboardLayout || isIconFile) {
			NSString *fileBaseName = [fileName stringByDeletingPathExtension];
			NSMutableDictionary *baseNameDictionary = fileNameDictionary[fileBaseName];
			if (nil == baseNameDictionary) {
				baseNameDictionary = [NSMutableDictionary dictionary];
				fileNameDictionary[fileBaseName] = baseNameDictionary;
			}
			if (isKeyboardLayout) {
					// It's a keyboard layout file
				NSData *keyboardData = [directoryEntry regularFileContents];
				NSError *readError;
				UkeleleKeyboardObject *keyboardObject = [[UkeleleKeyboardObject alloc] initWithData:keyboardData withError:&readError];
				if (keyboardObject == nil) {
					// We've failed to read the document
					[self presentError:readError];
					return NO;
				}
				baseNameDictionary[kKeyboardObjectKey] = keyboardObject;
					// Get the name
				NSString *keyboardName = [keyboardObject keyboardName];
				baseNameDictionary[kKeyboardNameKey] = keyboardName;
					// Save the file name
				NSString *fileName = [directoryEntry filename];
				baseNameDictionary[kKeyboardFileNameKey] = [fileName stringByDeletingPathExtension];
			}
			else if (isIconFile) {
					// It's an icon file
				baseNameDictionary[kIconFileKey] = directoryEntry;
			}
		}
	}
		// We have the keyboard layouts and icons, plus the preferred names, so populate the keyboard layouts array
	for (NSString *keyboardName in fileNameDictionary) {
		NSDictionary *keyboardData = fileNameDictionary[keyboardName];
		UkeleleKeyboardObject *keyboardObject = keyboardData[kKeyboardObjectKey];
		KeyboardLayoutInformation *keyboardInfo = [[KeyboardLayoutInformation alloc] initWithObject:keyboardObject fileName:keyboardData[kKeyboardFileNameKey]];
		NSFileWrapper *keyboardIconFile = keyboardData[kIconFileKey];
		[keyboardInfo setHasIcon:nil != keyboardIconFile];
		if (nil != keyboardIconFile) {
			[keyboardInfo setIconData:[keyboardIconFile regularFileContents]];
		}
		NSString *languageIdentifier = languageList[keyboardName];
		if (nil != languageIdentifier) {
			[keyboardInfo setIntendedLanguage:languageIdentifier];
		}
		[keyboardInfo setFileName:keyboardName];
		[keyboardLayouts addObject:keyboardInfo];
	}
	NSLog(@"Finished reading file wrapper");
	return YES;
}

- (void)parseInfoPlist:(NSFileWrapper *)infoPlistFile {
	NSData *infoPlistData = [infoPlistFile regularFileContents];
	NSError *theError;
	NSDictionary *infoPlistDictionary = [NSPropertyListSerialization propertyListWithData:infoPlistData
																				  options:NSPropertyListImmutable
																				   format:nil
																					error:&theError];
	if (nil == infoPlistDictionary) {
			// Failed to read
		return;
	}
	for (NSString *plistKey in infoPlistDictionary) {
		if ([plistKey hasPrefix:@"KLInfo_"]) {
				// It's a keyboard language
			NSString *keyboardName = [plistKey substringFromIndex:[kStringInfoPlistKLInfoPrefix length]];
			NSDictionary *languageDictionary = infoPlistDictionary[plistKey];
			NSString *languageIdentifier = languageDictionary[kStringInfoPlistIntendedLanguageKey];
			languageList[keyboardName] = languageIdentifier;
		}
		else if ([plistKey isEqualToString:(NSString *)kCFBundleIdentifierKey]) {
			_bundleIdentifier = infoPlistDictionary[plistKey];
		}
		else if ([plistKey isEqualToString:(NSString *)kCFBundleVersionKey]) {
			_bundleVersion = infoPlistDictionary[plistKey];
		}
	}
}

#pragma mark Table data source and delegate methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [keyboardLayouts count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	KeyboardLayoutInformation *keyboardEntry = keyboardLayouts[row];
	NSString *columnID = [tableColumn identifier];
	if ([columnID isEqualToString:@"Keyboard"]) {
			// Keyboard column
		NSString *keyboardName = [keyboardEntry keyboardName];
		if (nil == keyboardName || [keyboardName isEqualToString:@""]) {
			keyboardName = [keyboardEntry fileName];
		}
		return keyboardName;
	}
	else if ([columnID isEqualToString:@"Icon"]) {
			// Icon column
		NSImage *iconImage = [[NSImage alloc] initWithData:[keyboardEntry iconData]];
		return iconImage;
	}
	else if ([columnID isEqualToString:@"Language"]) {
			// Language column
		NSString *languageIdentifier = [keyboardEntry intendedLanguage];
		return languageIdentifier;
	}
	else {
		return nil;
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
		// Both the remove and Language buttons should only be available when there is a selection
	BOOL hasSelection = [keyboardLayoutsTable selectedRow] != -1;
	[removeKeyboardButton setEnabled:hasSelection];
	[languageButton setEnabled:hasSelection];
	[self inspectorSetKeyboardSection];
}

#pragma mark Drag and Drop

- (NSDragOperation)tableView:(NSTableView *)tableView
				validateDrop:(id<NSDraggingInfo>)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)dropOperation {
	NSPasteboard *pasteBoard = [info draggingPasteboard];
	if ([[pasteBoard types] containsObject:NSURLPboardType]) {
		NSURL *dragURL = [NSURL URLFromPasteboard:pasteBoard];
		NSString *fileExtension = [dragURL pathExtension];
		BOOL isKeyboardLayout = [fileExtension isEqualToString:kStringKeyboardLayoutExtension];
		BOOL isIconFile = [fileExtension isEqualToString:kStringIcnsExtension];
		if (isIconFile && dropOperation == NSTableViewDropOn) {
			return NSDragOperationCopy;
		}
		else if (isKeyboardLayout && dropOperation == NSTableViewDropAbove) {
			return NSDragOperationCopy;
		}
	}
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)tableView
	   acceptDrop:(id<NSDraggingInfo>)info
			  row:(NSInteger)row
	dropOperation:(NSTableViewDropOperation)dropOperation {
	NSPasteboard *pasteBoard = [info draggingPasteboard];
	if ([[pasteBoard types] containsObject:NSURLPboardType]) {
		NSURL *dragURL = [NSURL URLFromPasteboard:pasteBoard];
		NSString *fileExtension = [dragURL pathExtension];
		BOOL isKeyboardLayout = [fileExtension isEqualToString:kStringKeyboardLayoutExtension];
		BOOL isIconFile = [fileExtension isEqualToString:kStringIcnsExtension];
		if (isKeyboardLayout) {
				// Dropping a keyboard layout file
			NSError *theError;
			NSData *fileData = [NSData dataWithContentsOfURL:dragURL options:0 error:&theError];
			if (fileData == nil || [fileData length] == 0) {
					// Failed to read the document
				[NSApp presentError:theError];
				return NO;
			}
			UkeleleKeyboardObject *keyboardObject = [[UkeleleKeyboardObject alloc] initWithData:fileData withError:&theError];
			if (nil == keyboardObject) {
					// Failed to read the document!
				[NSApp presentError:theError];
				return NO;
			}
				// We don't want it in the same file, so we make it unspecified
//			[keyboardDocument setFileURL:nil];
			[self insertDocument:keyboardObject atIndex:row];
			NSString *fileName = [[dragURL lastPathComponent] stringByDeletingPathExtension];
			KeyboardLayoutInformation *keyboardInfo = keyboardLayouts[row];
			[keyboardInfo setFileName:fileName];
			return YES;
		}
		else if (isIconFile && dropOperation == NSTableViewDropOn) {
				// Dropping an icon file
			NSError *readError;
			NSFileWrapper *iconFile = [[NSFileWrapper alloc] initWithURL:dragURL options:NSFileWrapperReadingImmediate error:&readError];
			NSData *iconData = [iconFile regularFileContents];
			KeyboardLayoutInformation *keyboardEntry = keyboardLayouts[row];
			if ([keyboardEntry hasIcon]) {
					// Replace an existing icon file
				[self replaceIconAtIndex:row withIcon:iconData];
			}
			else {
					// No existing icon file
				[self addIcon:iconData atIndex:row];
			}
			return YES;
		}
	}
	return NO;
}

#pragma mark Accessors

- (void)setBundleName:(NSString *)bundleName {
	if (![bundleName isEqualToString:_bundleName]) {
		[self changeBundleName:bundleName bundleVersion:_bundleVersion buildVersion:_buildVersion sourceVersion:_sourceVersion];
		[self setDisplayName:bundleName];
	}
}

- (void)setBundleVersion:(NSString *)bundleVersion {
	if (![bundleVersion isEqualToString:_bundleVersion]) {
		[self changeBundleName:_bundleName bundleVersion:bundleVersion buildVersion:_buildVersion sourceVersion:_sourceVersion];
	}
}

- (void)setBuildVersion:(NSString *)buildVersion {
	if (![buildVersion isEqualToString:_buildVersion]) {
		[self changeBundleName:_bundleName bundleVersion:_bundleVersion buildVersion:buildVersion sourceVersion:_sourceVersion];
	}
}

- (void)setSourceVersion:(NSString *)sourceVersion {
	if (![sourceVersion isEqualToString:_sourceVersion]) {
		[self changeBundleName:_bundleName bundleVersion:_bundleVersion buildVersion:_buildVersion sourceVersion:sourceVersion];
	}
}

- (NSArray *)keyboardLayouts {
	return keyboardLayouts;
}

#pragma mark User actions

- (IBAction)addOpenDocument:(id)sender {
	NSDocumentController *theController = [NSDocumentController sharedDocumentController];
	NSArray *theDocumentList = [theController documents];
	NSMutableArray *candidateKeyboardLayouts = [NSMutableArray array];
	for (NSDocument *theDocument in theDocumentList) {
		if ([theDocument isKindOfClass:[UKKeyboardDocument class]] && ![(UKKeyboardDocument *)theDocument isBundle] && theDocument != self) {
				// This is the kind of document we want
			[candidateKeyboardLayouts addObject:theDocument];
		}
	}
	if ([candidateKeyboardLayouts count] == 0) {
			// There are no potential keyboard layouts (shouldn't get here!)
		return;
	}
	NSMutableArray *documentNames = [NSMutableArray array];
	for (UKKeyboardDocument *myDocument in candidateKeyboardLayouts) {
		NSString *documentName = [[myDocument keyboardLayout] keyboardName];
		[documentNames addObject:documentName];
	}
	if (nil == askFromListSheet) {
		askFromListSheet = [AskFromList askFromList];
	}
	NSArray *windowControllers = [self windowControllers];
	NSWindowController *windowController = windowControllers[0];
	NSWindow *myWindow = [windowController window];
	[askFromListSheet beginAskFromListWithText:@"Select the keyboard layout currently open in Ukelele from the following list"
									  withMenu:documentNames
									 forWindow:myWindow
									  callBack:^(NSString *theName) {
										  [self acceptChooseOpenDocument:theName];
									  }];
}

- (IBAction)showVersionInfo:(id)sender {
	if (nil == bundleVersionSheet) {
		bundleVersionSheet = [UkeleleBundleVersionSheet bundleVersionSheet];
	}
	NSArray *windowControllers = [self windowControllers];
	NSWindowController *windowController = windowControllers[0];
	NSWindow *myWindow = [windowController window];
	[bundleVersionSheet beginSheetWithBundleName:_bundleName
								   bundleVersion:_bundleVersion
									buildVersion:_buildVersion
								   sourceVersion:_sourceVersion
									   forWindow:myWindow
										callBack:^(UkeleleBundleVersionSheet *sheet) {
											if (nil == sheet) {
													// User cancelled
												bundleVersionSheet = nil;
												return;
											}
											[self changeBundleName:[[sheet bundleNameField] stringValue]
													 bundleVersion:[[sheet bundleVersionField] stringValue]
													  buildVersion:[[sheet buildVersionField] stringValue]
													 sourceVersion:[[sheet sourceVersionField] stringValue]];
											bundleVersionSheet = nil;
										}];
}

- (IBAction)addKeyboardLayout:(id)sender {
		// Create an empty keyboard layout
	UkeleleKeyboardObject *keyboardObject = [[UkeleleKeyboardObject alloc] initWithName:@"Untitled"];
	[self addNewDocument:keyboardObject];
}

- (IBAction)removeKeyboardLayout:(id)sender {
	NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	KeyboardLayoutInformation *selectedRowInfo = keyboardLayouts[selectedRowNumber];
	NSString *documentName = [selectedRowInfo keyboardName];
	if (nil == documentName || [documentName isEqualToString:@""]) {
		documentName = [selectedRowInfo fileName];
	}
		// Ask confirmation of deletion
	NSString *confirmationMessage = [NSString stringWithFormat:@"Are you sure you want to delete the keyboard layout \"%@?\"", documentName];
	NSAlert *confirmationDialog = [NSAlert alertWithMessageText:confirmationMessage
												  defaultButton:@"Delete"
												alternateButton:@"Cancel"
													otherButton:nil
									  informativeTextWithFormat:@"The keyboard layout will be permanently removed from the keyboard layout bundle."];
	[confirmationDialog setAlertStyle:NSWarningAlertStyle];
	NSArray *windowControllers = [self windowControllers];
	NSWindowController *windowController = windowControllers[0];
	NSWindow *myWindow = [windowController window];
	[confirmationDialog beginSheetModalForWindow:myWindow
								   modalDelegate:self
								  didEndSelector:@selector(confirmDelete:returnCode:contextInfo:)
									 contextInfo:(__bridge void *)(@(selectedRowNumber))];
}

- (IBAction)openKeyboardLayout:(id)sender {
	NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	KeyboardLayoutInformation *selectedRowInfo = keyboardLayouts[selectedRowNumber];
	UkeleleKeyboardObject *selectedKeyboard = [selectedRowInfo keyboardObject];
	UKKeyboardWindow *keyboardWindow = [selectedRowInfo keyboardWindow];
	if (keyboardWindow == nil) {
		keyboardWindow = [[UKKeyboardWindow alloc] initWithWindowNibName:UKKeyboardWindowNibName];
		[keyboardWindow setKeyboardLayout:selectedKeyboard];
		[selectedRowInfo setKeyboardWindow:keyboardWindow];
	}
	[keyboardWindow showWindow:self];
}

- (IBAction)chooseIntendedLanguage:(id)sender {
	NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	if (intendedLanguageSheet == nil) {
		intendedLanguageSheet = [IntendedLanguageSheet intendedLanguageSheet];
	}
	KeyboardLayoutInformation *keyboardEntry = keyboardLayouts[selectedRowNumber];
	NSString *keyboardLanguage = [keyboardEntry intendedLanguage];
	LanguageCode *keyboardLanguageCode = [LanguageCode languageCodeFromString:keyboardLanguage];
	NSArray *windowControllers = [self windowControllers];
	NSWindowController *windowController = windowControllers[0];
	NSWindow *myWindow = [windowController window];
	[intendedLanguageSheet beginIntendedLanguageSheet:keyboardLanguageCode
											forWindow:myWindow
											 callBack:^(LanguageCode *newLanguage) {
												 if (newLanguage == nil) {
														 // User cancelled
													 intendedLanguageSheet = nil;
													 return;
												 }
												 NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
												 NSAssert(selectedRowNumber >= 0, @"There must be a selected row");
												 [self replaceIntendedLanguageAtIndex:selectedRowNumber withLanguage:newLanguage];
												 intendedLanguageSheet = nil;
											 }];
}

- (IBAction)captureInputSource:(id)sender {
	NSError *createError;
	UkeleleKeyboardObject *newKeyboard = [self keyboardFromCurrentInputSourceWithError:&createError];
	if (newKeyboard == nil) {
			// Failed to create it
		[NSApp presentError:createError];
		return;
	}
	TISInputSourceRef currentInputSource = TISCopyCurrentKeyboardLayoutInputSource();
	CFURLRef keyboardIconURL = TISGetInputSourceProperty(currentInputSource, kTISPropertyIconImageURL);
	NSMutableData *iconData = nil;
	if (keyboardIconURL != NULL) {
		iconData = [NSData dataWithContentsOfURL:(__bridge NSURL *)keyboardIconURL];
	}
	if (nil == iconData) {
			// Try for an IconRef
		IconRef keyboardIcon = TISGetInputSourceProperty(currentInputSource, kTISPropertyIconRef);
		if (keyboardIcon != NULL) {
			NSImage *iconImage = [[NSImage alloc] initWithIconRef:keyboardIcon];
			NSArray *iconImageReps = [iconImage representations];
				// Create data to write with ImageIO
			iconData = [NSMutableData data];
			NSInteger iconCount = 0;
			for (NSImageRep *iconImage in iconImageReps) {
				if ([iconImage size].height < 128) {
					iconCount++;
				}
			}
			CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)iconData, kUTTypeAppleICNS, iconCount, nil);
			for (NSImageRep *imageRep in iconImageReps) {
				NSInteger imageHeight = [imageRep size].height;
					// Write only small sizes to avoid a hard limit
				if (imageHeight < 128) {
					NSRect imageRect = NSMakeRect(0, 0, imageHeight, imageHeight);
					CGImageRef imageRef = [imageRep CGImageForProposedRect:&imageRect context:nil hints:nil];
					CGImageDestinationAddImage(imageDestination, imageRef, nil);
				}
			}
			CGImageDestinationFinalize(imageDestination);
			if ([iconData length] == 0) {
				iconData = NULL;
			}
			CFRelease(imageDestination);
		}
	}
	CFArrayRef keyboardLanguages = TISGetInputSourceProperty(currentInputSource, kTISPropertyInputSourceLanguages);
	NSString *intendedLanguage = nil;
	if (CFArrayGetCount(keyboardLanguages) > 0) {
			// May have an intended language
		CFStringRef languageString = CFArrayGetValueAtIndex(keyboardLanguages, 0);
		if (CFStringGetLength(languageString) > 0) {
				// We do have a language now
			intendedLanguage = (__bridge NSString *)languageString;
		}
	}
//	NSArray *windowControllers = [newDocument windowControllers];
//	if ([windowControllers count] == 0) {
//		[newDocument makeWindowControllers];
//	}
		// Add the document with icon and language, if any
	[self addNewDocument:newKeyboard withIcon:iconData withLanguage:intendedLanguage];
}

#pragma mark Notifications

//- (void)notifyNewName:(NSString *)newName forDocument:(id)keyboardDocument {
//	NSAssert([keyboardDocument isKindOfClass:[UKKeyboardDocument class]], @"Document must be a Ukelele document");
//		// Find the document in the list
//	KeyboardLayoutInformation *keyboardInfo;
//	NSInteger keyboardCount = [keyboardLayouts count];
//	for (NSInteger i = 0; i < keyboardCount; i++) {
//		keyboardInfo = keyboardLayouts[i];
//		if ([keyboardInfo document] == keyboardDocument) {
//			[keyboardInfo setKeyboardName:[keyboardDocument keyboardDisplayName]];
//			break;
//		}
//	}
//		// Notify the list that it's been updated
//	[keyboardLayoutsTable reloadData];
//}

- (void)inspectorDidActivateTab:(NSString *)tabIdentifier {
	if ([tabIdentifier isEqualToString:kTabIdentifierDocument]) {
			// Activating the document tab
		[self inspectorSetKeyboardSection];
	}
	else if ([tabIdentifier isEqualToString:kTabIdentifierOutput]) {
			// Activating the output tab
	}
	else if ([tabIdentifier isEqualToString:kTabIdentifierState]) {
			// Activating the state tab
	}
}

- (void)inspectorSetKeyboardSection {
	InspectorWindowController *inspectorController = [InspectorWindowController getInstance];
	NSInteger selectedRow = [keyboardLayoutsTable selectedRow];
	if ([[keyboardLayoutsTable selectedRowIndexes] count] == 1) {
			// We have a single selected keyboard layout
		KeyboardLayoutInformation *selectedRowInfo = keyboardLayouts[selectedRow];
		UKKeyboardWindow *selectedWindow = [selectedRowInfo keyboardWindow];
		if (selectedRowInfo == nil) {
			selectedWindow = [[UKKeyboardWindow alloc] initWithWindowNibName:UKKeyboardWindowNibName];
			[selectedWindow setKeyboardLayout:[selectedRowInfo keyboardObject]];
			[selectedRowInfo setKeyboardWindow:selectedWindow];
		}
		[inspectorController setCurrentWindow:selectedWindow];
		[inspectorController setKeyboardSectionEnabled:YES];
	}
	else {
			// No or multiple selected keyboard layout
		[inspectorController setCurrentWindow:nil];
		[inspectorController setKeyboardSectionEnabled:NO];
	}
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
	InspectorWindowController *inspectorController = [InspectorWindowController getInstance];
	[self inspectorDidActivateTab:[[[inspectorController tabView] selectedTabViewItem] identifier]];
	[inspectorController setCurrentDocument:self];
}

- (void)windowDidResignMain:(NSNotification *)notification {
	InspectorWindowController *inspectorController = [InspectorWindowController getInstance];
	[inspectorController setCurrentDocument:nil];
}

#pragma mark Callbacks

- (void)acceptVersionInfo:(id)sender {
	if (nil == sender) {
			// User cancelled
		bundleVersionSheet = nil;
		return;
	}
	[self changeBundleName:[[bundleVersionSheet bundleNameField] stringValue]
			 bundleVersion:[[bundleVersionSheet bundleVersionField] stringValue]
			  buildVersion:[[bundleVersionSheet buildVersionField] stringValue]
			 sourceVersion:[[bundleVersionSheet sourceVersionField] stringValue]];
	bundleVersionSheet = nil;
}

- (void)confirmDelete:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSAlertAlternateReturn) {
			// User cancelled
		return;
	}
	NSInteger indexToDelete = [(__bridge NSNumber *)contextInfo integerValue];
	[self removeDocumentAtIndex:indexToDelete];
}

- (void)acceptIntendedLanguage:(LanguageCode *)newLanguage {
	if (newLanguage == nil) {
			// User cancelled
		intendedLanguageSheet = nil;
		return;
	}
	NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
	NSAssert(selectedRowNumber >= 0, @"There must be a selected row");
	[self replaceIntendedLanguageAtIndex:selectedRowNumber withLanguage:newLanguage];
	intendedLanguageSheet = nil;
}

- (void)acceptChooseOpenDocument:(NSString *)chosenItem {
	if (nil == chosenItem) {
			// User cancelled
		askFromListSheet = nil;
		return;
	}
	NSDocumentController *theController = [NSDocumentController sharedDocumentController];
	NSArray *theDocumentList = [theController documents];
	UKKeyboardDocument *chosenDocument = nil;
	for (NSDocument *theDocument in theDocumentList) {
		if ([theDocument isKindOfClass:[UKKeyboardDocument class]] && ![(UKKeyboardDocument *)theDocument isBundle] && theDocument != self) {
				// This is the kind of document we want
			if ([chosenItem isEqualToString:[[(UKKeyboardDocument *)theDocument keyboardLayout] keyboardName]]) {
				chosenDocument = (UKKeyboardDocument *)theDocument;
				break;
			}
		}
	}
	if (nil != chosenDocument) {
			// Is it not already saved?
		if ([chosenDocument fileURL] != nil) {
				// It already exists on disk, so make a copy
			NSURL *documentURL = [chosenDocument fileURL];
			NSError *readError;
			UkeleleKeyboardObject *newKeyboard = [[UkeleleKeyboardObject alloc] initWithData:[NSData dataWithContentsOfURL:documentURL] withError:&readError];
			NSAssert(newKeyboard != nil, @"Copied keyboard should not create an error in reading");
			[self addNewDocument:newKeyboard];
		}
		else {
				// It hasn't been saved, so just copy it
			UkeleleKeyboardObject *copiedKeyboard = [[chosenDocument keyboardLayout] copy];
			[self addNewDocument:copiedKeyboard];
		}
	}
	askFromListSheet = nil;
}

#pragma mark Action routines

- (void)changeBundleName:(NSString *)newBundleName
		   bundleVersion:(NSString *)newBundleVersion
			buildVersion:(NSString *)newBuildVersion
		   sourceVersion:(NSString *)newSourceVersion {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] changeBundleName:_bundleName
													   bundleVersion:_bundleVersion
														buildVersion:_buildVersion
													   sourceVersion:_sourceVersion];
	[undoManager setActionName:@"Set bundle information"];
	_bundleName = newBundleName;
	_bundleVersion = newBundleVersion;
	_buildVersion = newBuildVersion;
	_sourceVersion = newSourceVersion;
		//	InspectorWindowController *inspectorController = [InspectorWindowController getInstance];
		//	[[inspectorController bundleName] setStringValue:_bundleName];
		//	[[inspectorController bundleVersion] setStringValue:_bundleVersion];
		//	[[inspectorController buildVersion] setStringValue:_buildVersion];
		//	[[inspectorController sourceVersion] setStringValue:_sourceVersion];
}

- (void)addNewDocument:(UkeleleKeyboardObject *)newDocument {
	NSUInteger newIndex = [keyboardLayouts count];
	[self insertDocument:newDocument atIndex:newIndex];
	NSUndoManager *undoManager = [self undoManager];
	[undoManager setActionName:@"Add keyboard layout"];
		// Show the document
//	[newDocument showWindows];
}

- (void)removeDocumentAtIndex:(NSUInteger)indexToRemove {
	KeyboardLayoutInformation *keyboardInfo = keyboardLayouts[indexToRemove];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] replaceDocument:keyboardInfo atIndex:indexToRemove];
	[undoManager setActionName:@"Remove keyboard layout"];
	[keyboardLayouts removeObjectAtIndex:indexToRemove];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
		// Hide the document's windows, if they are shown
	UKKeyboardWindow *keyboardWindow = [keyboardInfo keyboardWindow];
	if (keyboardWindow != nil) {
		[keyboardWindow close];
	}
}

- (void)insertDocument:(UkeleleKeyboardObject *)newDocument atIndex:(NSInteger)newIndex {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeDocumentAtIndex:newIndex];
	[undoManager setActionName:@"Insert keyboard layout"];
		// Create dictionary with appropriate information
	KeyboardLayoutInformation *keyboardInfo = [[KeyboardLayoutInformation alloc] initWithObject:newDocument fileName:nil];
	[keyboardLayouts insertObject:keyboardInfo atIndex:newIndex];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
}

- (void)replaceDocument:(KeyboardLayoutInformation *)keyboardInfo atIndex:(NSUInteger)index {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeDocumentAtIndex:index];
	[undoManager setActionName:@"Insert keyboard layout"];
	[keyboardLayouts insertObject:keyboardInfo atIndex:index];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
}

- (void)addIcon:(NSData *)iconData atIndex:(NSUInteger)index {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeIconAtIndex:index];
	[undoManager setActionName:@"Add icon"];
	KeyboardLayoutInformation *keyboardInfo = keyboardLayouts[index];
	[keyboardInfo setIconData:iconData];
	[keyboardInfo setHasIcon:YES];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
}

- (void)removeIconAtIndex:(NSUInteger)index {
	KeyboardLayoutInformation *keyboardInfo = keyboardLayouts[index];
	NSData *iconData = [keyboardInfo iconData];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] addIcon:iconData atIndex:index];
	[undoManager setActionName:@"Add icon"];
	[keyboardInfo setIconData:nil];
	[keyboardInfo setHasIcon:NO];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
}

- (void)replaceIconAtIndex:(NSUInteger)index withIcon:(NSData *)iconData {
	KeyboardLayoutInformation *keyboardInfo = keyboardLayouts[index];
	NSData *oldIconData = [keyboardInfo iconData];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] replaceIconAtIndex:index withIcon:oldIconData];
	[undoManager setActionName:@"Change icon"];
	[keyboardInfo setIconData:iconData];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
}

- (void)replaceIntendedLanguageAtIndex:(NSUInteger)index withLanguage:(LanguageCode *)newLanguage {
	KeyboardLayoutInformation *keyboardInfo = keyboardLayouts[index];
	LanguageCode *oldLanguage = [LanguageCode languageCodeFromString:[keyboardInfo intendedLanguage]];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] replaceIntendedLanguageAtIndex:index withLanguage:oldLanguage];
	[undoManager setActionName:@"Change intended language"];
	[keyboardInfo setIntendedLanguage:[newLanguage stringRepresentation]];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
}

- (void)addNewDocument:(UkeleleKeyboardObject *)newDocument withIcon:(NSData *)iconData withLanguage:(NSString *)intendedLanguage {
	NSUndoManager *undoManager = [self undoManager];
	[undoManager beginUndoGrouping];
	[self addNewDocument:newDocument];
	if (iconData != nil) {
		[self addIcon:iconData atIndex:[keyboardLayouts count] - 1];
	}
	if (intendedLanguage != nil) {
		[self replaceIntendedLanguageAtIndex:[keyboardLayouts count] - 1 withLanguage:[LanguageCode languageCodeFromString:intendedLanguage]];
	}
	[undoManager setActionName:@"Capture current input source"];
	[undoManager endUndoGrouping];
}

@end

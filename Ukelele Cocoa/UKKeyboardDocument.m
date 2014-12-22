//
//  UKKeyboardDocument.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 13/06/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import "UKKeyboardDocument.h"
#import "UKKeyboardController.h"
#import "UKKeyboardController+Housekeeping.h"
#import "LanguageCode.h"
#import "UkeleleBundleVersionSheet.h"
#import "IntendedLanguageSheet.h"
#import "AskFromList.h"
#import "KeyboardLayoutInformation.h"
#import "UkeleleConstantStrings.h"
#import "UkeleleErrorCodes.h"
#import "ScriptInfo.h"
#import "InspectorWindowController.h"
#import "UkeleleKeyboardInstaller.h"
#import "UKNewKeyboardLayoutController.h"
#import <Carbon/Carbon.h>

#define UKKeyboardControllerNibName @"UkeleleDocument"

	// Dictionary keys
NSString *kIconFileKey = @"IconFile";
NSString *kKeyboardObjectKey = @"KeyboardObject";
NSString *kKeyboardNameKey = @"KeyboardName";
NSString *kKeyboardWindowKey = @"KeyboardWindow";
NSString *kKeyboardFileNameKey = @"KeyboardFileName";
NSString *kKeyboardFileWrapperKey = @"KeyboardFileWrapper";

@implementation IconImageTransformer

+ (Class)transformedValueClass {
	return [NSImage class];
}

+ (BOOL)allowsReverseTransformation {
	return NO;
}

- (id)transformedValue:(id)value {
	return [[NSImage alloc] initWithData:(NSData *)value];
}

@end

@implementation UKKeyboardDocument {
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
		_keyboardLayouts = [NSMutableArray array];
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
		UKKeyboardController *keyboardController = [[UKKeyboardController alloc] initWithWindowNibName:UKKeyboardControllerNibName];
		[self addWindowController:keyboardController];
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

- (BOOL)writeToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation originalContentsURL:(NSURL *)absoluteOriginalContentsURL error:(NSError *__autoreleasing *)outError		{
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
		// Start at the bottom, the InfoPlist.strings file, which contains all the names
	NSMutableString *infoPlistString = [NSMutableString stringWithString:@""];
	for (KeyboardLayoutInformation *keyboardEntry in self.keyboardLayouts) {
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
	for (KeyboardLayoutInformation *keyboardEntry in self.keyboardLayouts) {
		NSString *keyboardName = [keyboardEntry fileName];
		if (nil == keyboardName || [keyboardName isEqualToString:@""]) {
			keyboardName = [keyboardEntry keyboardName];
		}
		if ([keyboardEntry keyboardFileWrapper] != nil) {
				// Already have a file wrapper
			[resourcesDirectory addFileWrapper:[keyboardEntry keyboardFileWrapper]];
		}
		else {
			NSString *keyboardFileName = [NSString stringWithFormat:@"%@.%@", keyboardName, kStringKeyboardLayoutExtension];
			NSData *fileData = [[keyboardEntry keyboardObject] convertToData];
			NSFileWrapper *newFileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:fileData];
			[keyboardEntry setKeyboardFileWrapper:newFileWrapper];
			dispatch_async(mainQueue, ^void(void) {
				[resourcesDirectory addRegularFileWithContents:fileData
											 preferredFilename:keyboardFileName];
			});
		}
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
			NSString *iconFileName = [NSString stringWithFormat:@"%@.%@", keyboardName, kStringIcnsExtension];
			[resourcesDirectory addRegularFileWithContents:[keyboardEntry iconData] preferredFilename:iconFileName];
		}
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
	for (KeyboardLayoutInformation *keyboardEntry in self.keyboardLayouts) {
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
		UKKeyboardController *windowController = [[UKKeyboardController alloc] initWithWindowNibName:UKKeyboardControllerNibName];
		[windowController setKeyboardLayout:theKeyboard];
		[windowController setParentDocument:self];
		[self addWindowController:windowController];
		return YES;
	}
		// No valid keyboard layout created, outError is already set
	return NO;
}

- (BOOL)parseBundleFileWrapper:(NSFileWrapper *)theFileWrapper withError:(NSError **)error {
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
				baseNameDictionary[kKeyboardFileWrapperKey] = directoryEntry;
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
		NSFileWrapper *keyboardFileWrapper = keyboardData[kKeyboardFileWrapperKey];
		if (nil != keyboardFileWrapper) {
			[keyboardInfo setKeyboardFileWrapper:keyboardFileWrapper];
		}
		[self.keyboardLayouts addObject:keyboardInfo];
	}
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

- (void)keyboardLayoutDidChange:(UkeleleKeyboardObject *)keyboardObject {
		// The keyboard layout has changed, so pull it from the file wrapper
	for (KeyboardLayoutInformation *keyboardInfo in self.keyboardLayouts) {
		if ([keyboardInfo keyboardObject] == keyboardObject) {
				// Found the keyboard in the list
			if ([keyboardInfo keyboardFileWrapper]) {
					// Remove the keyboard file wrapper
				[keyboardInfo setKeyboardFileWrapper:nil];
			}
			break;
		}
	}
}

#pragma mark Table delegate methods

//- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
//	return [self.keyboardLayouts count];
//}
//
//- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//	KeyboardLayoutInformation *keyboardEntry = self.keyboardLayouts[row];
//	NSString *columnID = [tableColumn identifier];
//	if ([columnID isEqualToString:@"Keyboard"]) {
//			// Keyboard column
//		NSString *keyboardName = [keyboardEntry keyboardName];
//		if (nil == keyboardName || [keyboardName isEqualToString:@""]) {
//			keyboardName = [keyboardEntry fileName];
//		}
//		return keyboardName;
//	}
//	else if ([columnID isEqualToString:@"Icon"]) {
//			// Icon column
//		NSImage *iconImage = [[NSImage alloc] initWithData:[keyboardEntry iconData]];
//		return iconImage;
//	}
//	else if ([columnID isEqualToString:@"Language"]) {
//			// Language column
//		NSString *languageIdentifier = [keyboardEntry intendedLanguage];
//		return languageIdentifier;
//	}
//	else {
//		return nil;
//	}
//}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
		// Both the remove and Language buttons should only be available when there is a selection
	BOOL hasSelection = [keyboardLayoutsTable selectedRow] != -1;
	[removeKeyboardButton setEnabled:hasSelection];
	[languageButton setEnabled:hasSelection];
	[self inspectorSetKeyboardSection];
//	InspectorWindowController *inspectorController = [InspectorWindowController getInstance];
//	switch ([[keyboardLayoutsTable selectedRowIndexes] count]) {
//		case 0:
//				// No selected row
//			[inspectorController setCurrentKeyboard:nil];
//			break;
//			
//		case 1: {
//				// One selected row
//			KeyboardLayoutInformation *selectedRowInfo = keyboardLayouts[[keyboardLayoutsTable selectedRow]];
//			UkeleleKeyboardObject *selectedKeyboard = [selectedRowInfo keyboardObject];
//			[inspectorController setCurrentKeyboard:selectedKeyboard];
//			break;
//		}
//			
//		default:
//				// Multiple selected row
//			[inspectorController setCurrentKeyboard:nil];
//			break;
//	}
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
			KeyboardLayoutInformation *keyboardInfo = self.keyboardLayouts[row];
			[keyboardInfo setFileName:fileName];
			return YES;
		}
		else if (isIconFile && dropOperation == NSTableViewDropOn) {
				// Dropping an icon file
			NSError *readError;
			NSFileWrapper *iconFile = [[NSFileWrapper alloc] initWithURL:dragURL options:NSFileWrapperReadingImmediate error:&readError];
			NSData *iconData = [iconFile regularFileContents];
			KeyboardLayoutInformation *keyboardEntry = self.keyboardLayouts[row];
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

//- (NSArray *)keyboardLayouts {
//	return keyboardLayouts;
//}
//
#pragma mark Interface validation

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem {
	SEL theAction = [anItem action];
		// See which window is main
	for (NSWindowController *windowController in [self windowControllers]) {
		if ([[windowController window] isMainWindow]) {
				// Found the main window. Is it a keyboard window, and does it handle this selector?
			if ([windowController isKindOfClass:[UKKeyboardController class]] && [(UKKeyboardController *)windowController setsStatusForSelector:theAction]) {
				return [(UKKeyboardController *)windowController validateUserInterfaceItem:anItem];
			}
			break;
		}
	}
	if (theAction == @selector(removeKeyboardLayout:)) {
			// Only active if there's a selection in the table
		NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
		return (selectedRowNumber != -1);
	}
	else if (theAction == @selector(addOpenDocument:)) {
			// Only active if there are open keyboard layouts which aren't in bundles
		NSDocumentController *theController = [NSDocumentController sharedDocumentController];
		NSArray *theDocumentList = [theController documents];
		for (NSDocument *theDocument in theDocumentList) {
			if ([theDocument isKindOfClass:[UKKeyboardDocument class]] && ![(UKKeyboardDocument *)theDocument isBundle] && theDocument != self) {
					// This is the kind of document we want
				return YES;
			}
		}
		return NO;
	}
	else if (theAction == @selector(openKeyboardLayout:) || theAction == @selector(captureInputSource:) ||
			 theAction == @selector(installForCurrentUser:) || theAction == @selector(installForAllUsers:)) {
			// Always active
		return YES;
	}
	else if (theAction == @selector(chooseIntendedLanguage:) || theAction == @selector(attachIconFile:) ||
			 theAction == @selector(askKeyboardIdentifiers:)) {
			// Only active if there's a selection in the table
		NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
		return (selectedRowNumber != -1);
	}
	return [super validateUserInterfaceItem:anItem];
}

#pragma mark User actions

	// Add a current keyboard layout window

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

	// Show information about the version strings of the bundle

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

	// Add an empty keyboard layout

- (IBAction)addKeyboardLayout:(id)sender {
		// Run a dialog to define a keyboard layout
	__block UKNewKeyboardLayoutController *theController = [UKNewKeyboardLayoutController createController];
	NSArray *windowControllers = [self windowControllers];
	NSWindowController *windowController = windowControllers[0];
	NSWindow *myWindow = [windowController window];
	[theController runDialog:myWindow withCompletion:^(BaseLayoutTypes baseLayout, CommandLayoutTypes commandLayout, CapsLockLayoutTypes capsLockLayout) {
		[self addNewKeyboardLayoutWithBase:baseLayout command:commandLayout capsLock:capsLockLayout];
		theController = nil;
	}];
}

- (void)addNewKeyboardLayoutWithBase:(BaseLayoutTypes)baseLayout command:(CommandLayoutTypes)commandLayout capsLock:(CapsLockLayoutTypes)capsLockLayout {
		// Check whether we have a valid layout
	if (baseLayout != baseLayoutNone) {
			// Create a keyboard with the given layout types
		NSAssert(commandLayout != commandLayoutNone, @"Must have a command layout specified");
		NSAssert(capsLockLayout != capsLockLayoutNone, @"Must have a caps lock layout specified");
		NSUInteger base = kStandardLayoutEmpty;
		switch (baseLayout) {
			case baseLayoutEmpty:
				base = kStandardLayoutEmpty;
				break;
				
			case baseLayoutQWERTY:
				base = kStandardLayoutQWERTY;
				break;
				
			case baseLayoutQWERTZ:
				base = kStandardLayoutQWERTZ;
				break;
				
			case baseLayoutAZERTY:
				base = kStandardLayoutAZERTY;
				break;
				
			case baseLayoutDvorak:
				base = kStandardLayoutDvorak;
				break;
				
			case baseLayoutColemak:
				base = kStandardLayoutColemak;
				break;
				
			case baseLayoutNone:
					// Should never come here!
				break;
		}
		NSUInteger command = kStandardLayoutEmpty;
		switch (commandLayout) {
			case commandLayoutSame:
				command = base;
				break;
				
			case commandLayoutEmpty:
				command = kStandardLayoutEmpty;
				break;
				
			case commandLayoutQWERTY:
				command = kStandardLayoutQWERTY;
				break;
				
			case commandLayoutQWERTZ:
				command = kStandardLayoutQWERTZ;
				break;
				
			case commandLayoutAZERTY:
				command = kStandardLayoutAZERTY;
				break;
				
			case commandLayoutDvorak:
				command = kStandardLayoutDvorak;
				break;
				
			case commandLayoutColemak:
				command = kStandardLayoutColemak;
				break;
				
			case commandLayoutNone:
					// Should never come here!
				break;
		}
		NSUInteger capsLock = kStandardLayoutEmpty;
		switch (capsLockLayout) {
			case capsLockLayoutSame:
				capsLock = base;
				break;
				
			case capsLockLayoutEmpty:
				capsLock = kStandardLayoutEmpty;
				break;
				
			case capsLockLayoutQWERTY:
				capsLock = kStandardLayoutQWERTY;
				break;
				
			case capsLockLayoutQWERTZ:
				capsLock = kStandardLayoutQWERTZ;
				break;
				
			case capsLockLayoutAZERTY:
				capsLock = kStandardLayoutAZERTY;
				break;
				
			case capsLockLayoutDvorak:
				capsLock = kStandardLayoutDvorak;
				break;
				
			case capsLockLayoutColemak:
				capsLock = kStandardLayoutColemak;
				break;
				
			case capsLockLayoutNone:
					// Should never get here!
				break;
		}
		UkeleleKeyboardObject *keyboardObject = [[UkeleleKeyboardObject alloc] initWithName:@"Untitled" base:base command:command capsLock:capsLock];
		[self addNewDocument:keyboardObject];
	}
}

	// Remove the selected keyboard layout from the bundle

- (IBAction)removeKeyboardLayout:(id)sender {
	NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	KeyboardLayoutInformation *selectedRowInfo = self.keyboardLayouts[selectedRowNumber];
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

	// Open the selected keyboard layout's window

- (IBAction)openKeyboardLayout:(id)sender {
	NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	KeyboardLayoutInformation *selectedRowInfo = self.keyboardLayouts[selectedRowNumber];
	UkeleleKeyboardObject *selectedKeyboard = [selectedRowInfo keyboardObject];
	UKKeyboardController *keyboardController = [selectedRowInfo keyboardController];
	if (keyboardController == nil) {
		keyboardController = [[UKKeyboardController alloc] initWithWindowNibName:UKKeyboardControllerNibName];
		[keyboardController setKeyboardLayout:selectedKeyboard];
		[selectedRowInfo setKeyboardController:keyboardController];
	}
	[keyboardController showWindow:self];
}

	// Choose the intended language of the selected keyboard layout

- (IBAction)chooseIntendedLanguage:(id)sender {
	NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	if (intendedLanguageSheet == nil) {
		intendedLanguageSheet = [IntendedLanguageSheet intendedLanguageSheet];
	}
	KeyboardLayoutInformation *keyboardEntry = self.keyboardLayouts[selectedRowNumber];
	NSString *keyboardLanguage = [keyboardEntry intendedLanguage];
	LanguageCode *keyboardLanguageCode = [LanguageCode languageCodeFromString:keyboardLanguage];
	NSArray *windowControllers = [self windowControllers];
	NSWindowController *windowController = windowControllers[0];
	NSWindow *myWindow = [windowController window];
	[intendedLanguageSheet beginIntendedLanguageSheet:keyboardLanguageCode
											forWindow:myWindow
											 callBack:^(LanguageCode *newLanguage) {
												 if (newLanguage != nil) {
													 NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
													 NSAssert(selectedRowNumber >= 0, @"There must be a selected row");
													 [self replaceIntendedLanguageAtIndex:selectedRowNumber withLanguage:newLanguage];
												 }
											 }];
}

	// Create a new keyboard layout from the current keyboard input source

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
		// Add the document with icon and language, if any
	[self addNewDocument:newKeyboard withIcon:iconData withLanguage:intendedLanguage];
}

	// Open a keyboard layout from a file and add it to the bundle

- (IBAction)openKeyboardFile:(id)sender {
	__block NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		// These next four lines aren't necessary, it seems, but better to be safe...
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel setResolvesAliases:YES];
	[openPanel setAllowedFileTypes:@[kFileTypeKeyboardLayout]];
	NSWindow *docWindow = [keyboardLayoutsTable window];
	[openPanel beginSheetModalForWindow:docWindow completionHandler:^(NSModalResponse response) {
		if (response == NSModalResponseOK) {
				// User selected a file
			NSArray *selectedFiles = [openPanel URLs];
			NSURL *selectedFile = selectedFiles[0];	// Only one file
			NSError *readError = nil;
			UkeleleKeyboardObject *keyboardLayout = [[UkeleleKeyboardObject alloc] initWithData:[NSData dataWithContentsOfURL:selectedFile] withError:&readError];
			if (keyboardLayout == nil) {
					// Read failed
				[NSApp presentError:readError];
			}
			else {
				[self addNewDocument:keyboardLayout];
			}
		}
	}];
}

	// Attach an icon file to a keyboard layout

- (IBAction)attachIconFile:(id)sender {
	__block NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	__block NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		// These next four lines aren't necessary, it seems, but better to be safe...
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel setResolvesAliases:YES];
	[openPanel setAllowedFileTypes:@[(NSString *)kUTTypeAppleICNS]];
	NSWindow *docWindow = [keyboardLayoutsTable window];
	[openPanel beginSheetModalForWindow:docWindow completionHandler:^(NSModalResponse response) {
		if (response == NSModalResponseOK) {
				// User selected a file
			NSArray *selectedFiles = [openPanel URLs];
			NSURL *selectedFile = selectedFiles[0];	// Only one file
			NSData *iconData = [NSData dataWithContentsOfURL:selectedFile];
			[self addIcon:iconData atIndex:selectedRowNumber];
		}
	}];
}

	// Set the keyboard's name, script and/or id
- (IBAction)askKeyboardIdentifiers:(id)sender {
	NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	KeyboardLayoutInformation *keyboardEntry = self.keyboardLayouts[selectedRowNumber];
	UKKeyboardController *keyboardController = [keyboardEntry keyboardController];
	if (keyboardController == nil) {
			// Create the controller
		keyboardController = [[UKKeyboardController alloc] initWithWindowNibName:UKKeyboardControllerNibName];
		[keyboardController setKeyboardLayout:[keyboardEntry keyboardObject]];
		[keyboardEntry setKeyboardController:keyboardController];
	}
	NSWindow *docWindow = [keyboardLayoutsTable window];
	[keyboardController askKeyboardIdentifiers:docWindow];
}

	// Install the keyboard layout

- (IBAction)installForAllUsers:(id)sender {
	NSWindow *targetWindow;
	if ([sender isKindOfClass:[UKKeyboardController class]]) {
		targetWindow = [(UKKeyboardController *)sender window];
	}
	else {
		targetWindow = [keyboardLayoutsTable window];
	}
	UkeleleKeyboardInstaller *theInstaller = [UkeleleKeyboardInstaller defaultInstaller];
	NSError *theError;
	BOOL installOK = [theInstaller installForAllUsers:[self fileURL] error:&theError];
	if (!installOK) {
		[self presentError:theError modalForWindow:targetWindow delegate:nil didPresentSelector:nil contextInfo:nil];
	}
}

- (IBAction)installForCurrentUser:(id)sender {
	NSWindow *targetWindow;
	if ([sender isKindOfClass:[UKKeyboardController class]]) {
		targetWindow = [(UKKeyboardController *)sender window];
	}
	else {
		targetWindow = [keyboardLayoutsTable window];
	}
	UkeleleKeyboardInstaller *theInstaller = [UkeleleKeyboardInstaller defaultInstaller];
	NSError *theError;
	BOOL installOK = [theInstaller installForCurrentUser:[self fileURL] error:&theError];
	if (!installOK) {
		[self presentError:theError modalForWindow:targetWindow delegate:nil didPresentSelector:nil contextInfo:nil];
	}
}

#pragma mark Notifications

- (void)notifyNewName:(NSString *)newName forDocument:(id)keyboardDocument {
	NSAssert([keyboardDocument isKindOfClass:[UKKeyboardController class]], @"Document must be a Ukelele document");
		// Find the document in the list
	for (KeyboardLayoutInformation *keyboardInfo in self.keyboardLayouts) {
		if ([keyboardInfo keyboardController] == keyboardDocument) {
			[keyboardInfo setKeyboardName:[(UKKeyboardController *)keyboardDocument keyboardDisplayName]];
			break;
		}
	}
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
}

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
		KeyboardLayoutInformation *selectedRowInfo = self.keyboardLayouts[selectedRow];
		UKKeyboardController *selectedWindow = [selectedRowInfo keyboardController];
		if (selectedRowInfo == nil) {
			selectedWindow = [[UKKeyboardController alloc] initWithWindowNibName:UKKeyboardControllerNibName];
			[selectedWindow setKeyboardLayout:[selectedRowInfo keyboardObject]];
			[selectedRowInfo setKeyboardController:selectedWindow];
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
	static NSDictionary *bindingsDict;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		bindingsDict = @{NSConditionallySetsEditableBindingOption: @YES,
						 NSRaisesForNotApplicableKeysBindingOption: @YES
						 };
	});
	[inspectorController bind:@"currentKeyboard" toObject:self.keyboardLayoutsController withKeyPath:@"selection.keyboardObject" options:bindingsDict];
//	switch ([[keyboardLayoutsTable selectedRowIndexes] count]) {
//		case 0:
//				// No selected row
//			[inspectorController setCurrentKeyboard:nil];
//			break;
//			
//		case 1: {
//				// One selected row
//			KeyboardLayoutInformation *selectedRowInfo = keyboardLayouts[[keyboardLayoutsTable selectedRow]];
//			UkeleleKeyboardObject *selectedKeyboard = [selectedRowInfo keyboardObject];
//			[inspectorController setCurrentKeyboard:selectedKeyboard];
//			break;
//		}
//			
//		default:
//				// Multiple selected row
//			[inspectorController setCurrentKeyboard:nil];
//			break;
//	}
}

- (void)windowDidResignMain:(NSNotification *)notification {
	InspectorWindowController *inspectorController = [InspectorWindowController getInstance];
//	[inspectorController setCurrentKeyboard:nil];
	[inspectorController unbind:@"currentDocument"];
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
	NSUInteger newIndex = [self.keyboardLayouts count];
	[self insertDocument:newDocument atIndex:newIndex];
	NSUndoManager *undoManager = [self undoManager];
	[undoManager setActionName:@"Add keyboard layout"];
		// Show the document
//	[newDocument showWindows];
}

- (void)removeDocumentAtIndex:(NSUInteger)indexToRemove {
	KeyboardLayoutInformation *keyboardInfo = self.keyboardLayouts[indexToRemove];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] replaceDocument:keyboardInfo atIndex:indexToRemove];
	[undoManager setActionName:@"Remove keyboard layout"];
	[self.keyboardLayouts removeObjectAtIndex:indexToRemove];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
		// Hide the document's windows, if they are shown
	UKKeyboardController *keyboardController = [keyboardInfo keyboardController];
	if (keyboardController != nil) {
		[keyboardController close];
	}
}

- (void)insertDocument:(UkeleleKeyboardObject *)newDocument atIndex:(NSInteger)newIndex {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeDocumentAtIndex:newIndex];
	[undoManager setActionName:@"Insert keyboard layout"];
		// Create dictionary with appropriate information
	KeyboardLayoutInformation *keyboardInfo = [[KeyboardLayoutInformation alloc] initWithObject:newDocument fileName:nil];
	[self.keyboardLayouts insertObject:keyboardInfo atIndex:newIndex];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
}

- (void)replaceDocument:(KeyboardLayoutInformation *)keyboardInfo atIndex:(NSUInteger)index {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeDocumentAtIndex:index];
	[undoManager setActionName:@"Insert keyboard layout"];
	[self.keyboardLayouts insertObject:keyboardInfo atIndex:index];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
}

- (void)addIcon:(NSData *)iconData atIndex:(NSUInteger)index {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeIconAtIndex:index];
	[undoManager setActionName:@"Add icon"];
	KeyboardLayoutInformation *keyboardInfo = self.keyboardLayouts[index];
	[keyboardInfo setIconData:iconData];
	[keyboardInfo setHasIcon:YES];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
}

- (void)removeIconAtIndex:(NSUInteger)index {
	KeyboardLayoutInformation *keyboardInfo = self.keyboardLayouts[index];
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
	KeyboardLayoutInformation *keyboardInfo = self.keyboardLayouts[index];
	NSData *oldIconData = [keyboardInfo iconData];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] replaceIconAtIndex:index withIcon:oldIconData];
	[undoManager setActionName:@"Change icon"];
	[keyboardInfo setIconData:iconData];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
}

- (void)replaceIntendedLanguageAtIndex:(NSUInteger)index withLanguage:(LanguageCode *)newLanguage {
	KeyboardLayoutInformation *keyboardInfo = self.keyboardLayouts[index];
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
		[self addIcon:iconData atIndex:[self.keyboardLayouts count] - 1];
	}
	if (intendedLanguage != nil) {
		[self replaceIntendedLanguageAtIndex:[self.keyboardLayouts count] - 1 withLanguage:[LanguageCode languageCodeFromString:intendedLanguage]];
	}
	[undoManager setActionName:@"Capture current input source"];
	[undoManager endUndoGrouping];
}

@end

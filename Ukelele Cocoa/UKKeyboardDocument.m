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
#import "UKDocumentPrintViewController.h"
#import <Carbon/Carbon.h>

#define UKKeyboardControllerNibName @"UkeleleDocument"
#define UKKeyboardConverterTool	@"kluchrtoxml"

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

- (instancetype)initWithType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
	self = [self init];
	if (self) {
		self.fileType = typeName;
		if ([typeName isEqualToString:kFileTypeKeyboardLayout]) {
				// Unbundled keyboard layout
			_isBundle = NO;
		}
		else if ([typeName isEqualToString:(NSString *)kUTTypeBundle] || [typeName isEqualToString:kFileTypeGenericBundle]) {
				// Bundle
			_isBundle = YES;
		}
		else {
				// Unsupported type
			self = nil;
			if (outError != nil) {
				NSDictionary *errorDict = @{NSLocalizedDescriptionKey: @"Invalid type for document"};
				*outError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorInvalidFileType userInfo:errorDict];
			}
		}
	}
	return self;
}

- (void)makeWindowControllers {
	if (!self.isBundle) {
			// Stand-alone keyboard layout
		UKKeyboardController *keyboardController = [[UKKeyboardController alloc] initWithWindowNibName:UKKeyboardControllerNibName];
		NSAssert(keyboardController, @"Must be able to create a keyboard controller");
		[self addWindowController:keyboardController];
		[self setFileType:kFileTypeKeyboardLayout];
	}
	else {
		NSWindowController *windowController = [[NSWindowController alloc] initWithWindowNibName:@"UKKeyboardLayoutBundle" owner:self];
		NSAssert(windowController, @"Must be able to create a window controller");
		[self addWindowController:windowController];
		[self setFileType:kFileTypeGenericBundle];
	}
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
	if ([aController isKindOfClass:[UKKeyboardDocument class]]) {
		[keyboardLayoutsTable registerForDraggedTypes:@[NSURLPboardType]];
	}
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"keyboardName" ascending:YES selector:@selector(localizedCompare:)];
	[self.keyboardLayoutsController setSortDescriptors:@[sortDescriptor]];
	[self.keyboardLayouts sortUsingDescriptors:@[sortDescriptor]];
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError {
	if ([typeName isEqualToString:kFileTypeKeyboardLayout]) {
			// This is an unbundled keyboard layout document
		self.isBundle = NO;
		return [self parseKeyboardFileWrapper:fileWrapper withError:outError];
	}
	else if ([typeName isEqualToString:(NSString *)kUTTypeBundle] || [typeName isEqualToString:kFileTypeGenericBundle]) {
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

- (BOOL)writeToURL:(NSURL *)url
			ofType:(NSString *)typeName
  forSaveOperation:(NSSaveOperationType)saveOperation
originalContentsURL:(NSURL *)absoluteOriginalContentsURL
			 error:(NSError *__autoreleasing *)outError {
	if (self.isBundle) {
			// The document is a bundle
		if ([typeName isEqualToString:kFileTypeKeyboardLayout]) {
				// The user is trying to save a bundle as unbundled
			if ([[self.keyboardLayoutsController arrangedObjects] count] == 1) {
					// We only have one keyboard layout, so we can do it
				[self convertToUnbundled];
				return [self saveKeyboardLayoutToURL:url error:outError];
			}
			else {
					// Not a single keyboard layout, so throw an error
				if (outError != nil) {
					NSDictionary *errorDict = @{NSLocalizedDescriptionKey: @"Can only convert a bundle with a single keyboard layout to an unbundled file"};
					*outError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorCannotConvertToUnbundled userInfo:errorDict];
					return NO;
				}
			}
		}
		else if (self.isBundle && ([typeName isEqualToString:(NSString *)kUTTypeBundle] || [typeName isEqualToString:kFileTypeGenericBundle])) {
				// A bundle
			if (absoluteOriginalContentsURL != nil) {
					// Try to save only what has changed
					// NOT IMPLEMENTED!
			}
			NSFileWrapper *keyboardWrapper = [self createFileWrapper];
			return [keyboardWrapper writeToURL:url options:0 originalContentsURL:nil error:outError];
		}
	}
	else {
			// The document is an unbundled keyboard layout
		if ([typeName isEqualToString:kFileTypeKeyboardLayout]) {
				// Save as unbundled
			return [self saveKeyboardLayoutToURL:url error:outError];
		}
		else if ([typeName isEqualToString:(NSString *)kUTTypeBundle] || [typeName isEqualToString:kFileTypeGenericBundle]) {
				// Convert to bundled
			[self convertToBundle];
			NSFileWrapper *fileWrapper = [self createFileWrapper];
			return [fileWrapper writeToURL:url options:0 originalContentsURL:nil error:outError];
		}
	}
		// If we get here, we were given an invalid type
	if (outError != nil) {
		NSDictionary *errorDict = @{NSLocalizedDescriptionKey: @"Invalid type for save operation"};
		*outError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorInvalidFileType userInfo:errorDict];
	}
	return NO;
}

+ (BOOL)autosavesInPlace {
    return YES;
}

#pragma mark Convert file type

- (void)convertToBundle {
	NSAssert(!self.isBundle, @"Trying to convert a bundle to a bundle");
	[self setIsBundle:YES];
	UkeleleKeyboardObject *keyboardObject = self.keyboardLayout;
	[self setKeyboardLayout:nil];
	NSArray *controllers = [self windowControllers];
	if ([controllers count] > 0) {
		NSAssert([controllers count] == 1, @"More than one window controller");
		NSWindowController *theController = controllers[0];
		[theController close];
		[self removeWindowController:theController];
	}
	[self makeWindowControllers];
	[self addNewDocument:keyboardObject];
	[self showWindows];
}

- (void)convertToUnbundled {
	NSAssert(self.isBundle, @"Trying to convert a non-bundle to a non-bundle");
	NSAssert([[self.keyboardLayoutsController arrangedObjects] count] == 1, @"Cannot convert a bundle with more than one keyboard layout");
	[self setIsBundle:NO];
	KeyboardLayoutInformation *layoutInfo = [[self.keyboardLayoutsController arrangedObjects] objectAtIndex:0];
	NSArray *controllers = [self windowControllers];
	if ([controllers count] > 0) {
		NSAssert([controllers count] == 1, @"More than one window controller");
		NSWindowController *theController = controllers[0];
		[theController close];
		[self removeWindowController:theController];
	}
	[self setupKeyboard:[layoutInfo keyboardObject]];
	[self showWindows];
}

#pragma mark Capturing input source

- (UkeleleKeyboardObject *)keyboardFromCurrentInputSourceWithError:(NSError **)outError {
		// Create a temporary file
	NSString *tempDirectory = NSTemporaryDirectory();
	NSString *tempFilePath = [NSString stringWithFormat:@"%@UkeleleDataXXXXX.rsrc", tempDirectory];
	NSUInteger pathLength = [tempFilePath length];
	char *tempFileTemplate = malloc(pathLength * 3 + 1);
	[tempFilePath getCString:tempFileTemplate maxLength:pathLength * 3 encoding:NSUTF8StringEncoding];
	int tempFileDescriptor = mkstemps(tempFileTemplate, 5);
	if (tempFileDescriptor == -1) {
			// Could not create temporary file
		return nil;
	}
	tempFilePath = @(tempFileTemplate);
	free(tempFileTemplate);
	NSURL *tempFileURL = [NSURL fileURLWithPath:tempFilePath];
		// We don't need the temporary file any more, since we're going to create a resource fork
	int result = close(tempFileDescriptor);
	NSAssert(result == 0, @"Should be able to close the file");
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
	CFStringGetPascalString(keyboardName, resourceName, 256, kCFStringEncodingUTF8);
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
	NSAssert(CFStringGetLength(tempFileName) < 2048, @"File name is more than 2048 characters");
	UniChar tempFileBuffer[2048];
	CFStringGetCharacters(tempFileName, CFRangeMake(0, CFStringGetLength(tempFileName)), tempFileBuffer);
	theErr = FSCreateResourceFile(&parentRef, CFStringGetLength(tempFileName), tempFileBuffer, kFSCatInfoNone, NULL, forkName.length, forkName.unicode, &tempFileRef, NULL);
	NSAssert(theErr == noErr, @"Could not create resource file");
	ResFileRefNum resFile;
	theErr = FSOpenResourceFile(&tempFileRef, forkName.length, forkName.unicode, fsWrPerm, &resFile);
	NSAssert(theErr == noErr, @"Could not open resource file");
	Handle theHandle = NewHandle(CFDataGetLength(uchrData));
	memcpy(*theHandle, CFDataGetBytePtr(uchrData), CFDataGetLength(uchrData));
	AddResource(theHandle, kResType_uchr, UniqueID(kResType_uchr), resourceName);
	UpdateResFile(CurResFile());
	FSCloseFork(resFile);
		// Get the conversion tool
	NSURL *toolURL = [[NSBundle mainBundle] URLForAuxiliaryExecutable:UKKeyboardConverterTool];
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
	[fileManager changeCurrentDirectoryPath:currentDirectory];
		// Finally, read the resulting file
	NSURL *outputFileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@.keylayout", tempDirectory, keyboardName]];
	NSError *theError = nil;
	NSData *myData = [NSData dataWithContentsOfURL:outputFileURL options:0 error:&theError];
	if (myData == nil || [myData length] == 0) {
		if (outError != nil) {
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
		// Make a copy of the keyboard layouts array so that we don't have it change under us
	NSArray *keyboardLayouts = [self.keyboardLayouts copy];
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
	versionPlistDictionary[kStringBuildVersionKey] = self.buildVersion;
	versionPlistDictionary[kStringSourceVersionKey] = self.sourceVersion;
	versionPlistDictionary[kStringProjectNameKey] = self.bundleName;
	NSString *error;
	NSFileWrapper *versionPlistFile =
		[[NSFileWrapper alloc] initRegularFileWithContents:
		 [NSPropertyListSerialization dataFromPropertyList:versionPlistDictionary
													format:NSPropertyListXMLFormat_v1_0
										  errorDescription:&error]];
	[versionPlistFile setPreferredFilename:kStringVersionPlistFileName];
		// Create the Resources directory
	NSFileWrapper *resourcesDirectory = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
	[resourcesDirectory setPreferredFilename:kStringResourcesName];
	[resourcesDirectory addFileWrapper:englishLprojDirectory];
		// Add all the keyboard layout and icon files
	for (KeyboardLayoutInformation *keyboardEntry in keyboardLayouts) {
		NSString *keyboardName = [keyboardEntry fileName];
			// Test whether we have a null or untitled file name
		if (nil == keyboardName || [keyboardName isEqualToString:@""] ||
			[keyboardName compare:UKUntitledName options:(NSAnchoredSearch | NSCaseInsensitiveSearch)] == NSOrderedSame) {
			keyboardName = [keyboardEntry keyboardName];
		}
		if ([keyboardEntry keyboardFileWrapper] != nil) {
				// Already have a file wrapper
			[resourcesDirectory addFileWrapper:[keyboardEntry keyboardFileWrapper]];
		}
		else {
				// Create a file wrapper
			NSString *keyboardFileName = [NSString stringWithFormat:@"%@.%@", keyboardName, kStringKeyboardLayoutExtension];
			NSData *fileData = [[keyboardEntry keyboardObject] convertToData];
			NSFileWrapper *newFileWrapper = [[NSFileWrapper alloc] initRegularFileWithContents:fileData];
			[newFileWrapper setPreferredFilename:keyboardFileName];
			[keyboardEntry setKeyboardFileWrapper:newFileWrapper];
				// The actual name shouldn't change, but we should cover all bases
			NSString *actualFileName = [resourcesDirectory addFileWrapper:newFileWrapper];
			NSString *baseName = [actualFileName stringByDeletingPathExtension];
			[keyboardEntry setFileName:baseName];
		}
		if ([keyboardEntry hasIcon]) {
			NSString *iconFileName = [NSString stringWithFormat:@"%@.%@", keyboardName, kStringIcnsExtension];
			[resourcesDirectory addRegularFileWithContents:[keyboardEntry iconData] preferredFilename:iconFileName];
		}
	}
		// Create the Info.plist file
	NSDictionary *infoPlist = [self createInfoPlist];
	NSFileWrapper *infoPlistFile =
		[[NSFileWrapper alloc] initRegularFileWithContents:
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
		NSString *extensionString = [[self.bundleName lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
		self.bundleIdentifier = [baseString stringByAppendingString:extensionString];
	}
	infoPlist[@"CFBundleIdentifier"] = self.bundleIdentifier;
		// Set the bundle name
	infoPlist[@"CFBundleName"] = self.bundleName;
		// Set the version number
	infoPlist[(NSString *)kCFBundleVersionKey] = self.bundleVersion;
		// Get the intended languages for each keyboard layout in the bundle
	for (KeyboardLayoutInformation *keyboardEntry in self.keyboardLayouts) {
		NSString *languageIdentifier = [keyboardEntry intendedLanguage];
		if (nil != languageIdentifier) {
				// Add this language identifier
			NSString *keyboardName = [keyboardEntry keyboardName];
			NSString *fileName = [keyboardEntry fileName];
			if (fileName == nil) {
				fileName = keyboardName;
			}
			NSString *KLInfoIdentifier = [NSString stringWithFormat:@"%@%@", kStringInfoPlistKLInfoPrefix, fileName];
			NSString *keyboardIdentifier = [NSString stringWithFormat:@"%@.%@", self.bundleIdentifier, [[keyboardName lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""]];
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
		[self setupKeyboard:theKeyboard];
		return YES;
	}
		// No valid keyboard layout created, outError is already set
	return NO;
}

- (void)setupKeyboard:(UkeleleKeyboardObject *)theKeyboard {
		 // Set the new keyboard and create a window for it
	self.keyboardLayout = theKeyboard;
	UKKeyboardController *windowController = [[UKKeyboardController alloc] initWithWindowNibName:UKKeyboardControllerNibName];
	NSAssert(windowController, @"Must get a valid window controller");
	[windowController setKeyboardLayout:theKeyboard];
	[windowController setParentDocument:self];
	[self addWindowController:windowController];
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
		// Search for the Contents directory
	NSEnumerator *directoryEnumerator = [directoryContents objectEnumerator];
	NSFileWrapper *directoryEntry = nil;
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
		NSDictionary *versionPlistDictionary =
			[NSPropertyListSerialization propertyListWithData:[versionPlist regularFileContents]
													  options:NSPropertyListImmutable
													   format:nil
														error:error];
		if (versionPlistDictionary != nil) {
			self.buildVersion = versionPlistDictionary[kStringBuildVersionKey];
			self.sourceVersion = versionPlistDictionary[kStringSourceVersionKey];
		}
	}
	if (resourcesDirectory == nil) {
			// No resources directory!
		errorDictionary = @{NSLocalizedDescriptionKey: @"The selected bundle is not a valid bundle"};
		if (error != NULL) {
			*error = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorNotKeyboardLayoutBundle userInfo:errorDictionary];
		}
		return NO;
	}
		// Now scan the Resources directory for keyboard layouts and icons
	directoryContents = [resourcesDirectory fileWrappers];
	directoryEnumerator = [directoryContents objectEnumerator];
	NSMutableDictionary *fileNameDictionary = [NSMutableDictionary dictionary];
	while ((directoryEntry = [directoryEnumerator nextObject])) {
		NSString *fileName = [directoryEntry preferredFilename];
		BOOL isKeyboardLayout = [fileName hasSuffix:[NSString stringWithFormat:@".%@", kStringKeyboardLayoutExtension]];
		BOOL isIconFile = [fileName hasSuffix:[NSString stringWithFormat:@".%@", kStringIcnsExtension]];
		if (isKeyboardLayout || isIconFile) {
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
	if ([fileNameDictionary count] == 0) {
			// No keyboards
		errorDictionary = @{NSLocalizedDescriptionKey: @"The selected bundle has no keyboard layouts in it"};
		if (error != NULL) {
			*error = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorNoKeyboardLayoutsInBundle userInfo:errorDictionary];
		}
		return NO;
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
	NSDictionary *infoPlistDictionary =
		[NSPropertyListSerialization propertyListWithData:infoPlistData
												  options:NSPropertyListImmutable
												   format:nil
													error:&theError];
	if (nil == infoPlistDictionary) {
			// Failed to read
		return;
	}
	for (NSString *plistKey in infoPlistDictionary) {
		if ([plistKey hasPrefix:kStringInfoPlistKLInfoPrefix]) {
				// It's a keyboard language
			NSString *keyboardName = [plistKey substringFromIndex:[kStringInfoPlistKLInfoPrefix length]];
			NSDictionary *languageDictionary = infoPlistDictionary[plistKey];
			NSString *languageIdentifier = languageDictionary[kStringInfoPlistIntendedLanguageKey];
			languageList[keyboardName] = languageIdentifier;
		}
		else if ([plistKey isEqualToString:(NSString *)kCFBundleIdentifierKey]) {
			self.bundleIdentifier = infoPlistDictionary[plistKey];
		}
		else if ([plistKey isEqualToString:(NSString *)kCFBundleVersionKey]) {
			self.bundleVersion = infoPlistDictionary[plistKey];
		}
	}
}

- (UKKeyboardController *)createControllerForEntry:(KeyboardLayoutInformation *)keyboardEntry {
	UKKeyboardController *keyboardController = [[UKKeyboardController alloc] initWithWindowNibName:UKKeyboardControllerNibName];
	[keyboardController setKeyboardLayout:[keyboardEntry keyboardObject]];
	[keyboardEntry setKeyboardController:keyboardController];
	[keyboardController setParentDocument:self];
	return keyboardController;
}

- (UKKeyboardController *)controllerForCurrentEntry {
	NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
	NSAssert(selectedRowNumber >= 0, @"Must have a selected row");
	KeyboardLayoutInformation *selectedRowInfo = self.keyboardLayouts[selectedRowNumber];
	UKKeyboardController *theController = [selectedRowInfo keyboardController];
	if (theController == nil) {
		theController = [self createControllerForEntry:selectedRowInfo];
	}
	return theController;
}

#pragma mark Table delegate methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	[self inspectorSetKeyboardSection];
}

- (void)setTableSelectionForMenu {
	NSUInteger clickedRow = [keyboardLayoutsTable clickedRow];
	if (clickedRow != -1) {
		if ([keyboardLayoutsTable selectedRow] != clickedRow) {
			[keyboardLayoutsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:clickedRow] byExtendingSelection:NO];
		}
	}
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
	[self.keyboardLayoutsController setSortDescriptors:[keyboardLayoutsTable sortDescriptors]];
	[self.keyboardLayouts sortUsingDescriptors:[keyboardLayoutsTable sortDescriptors]];
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
	if (theAction == @selector(addOpenDocument:)) {
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
	else if (theAction == @selector(captureInputSource:) ||
			 theAction == @selector(installForCurrentUser:) || theAction == @selector(installForAllUsers:)) {
			// Always active
		return YES;
	}
	else if (theAction == @selector(chooseIntendedLanguage:) || theAction == @selector(attachIconFile:) ||
			 theAction == @selector(askKeyboardIdentifiers:) || theAction == @selector(removeKeyboardLayout:) ||
			 theAction == @selector(openKeyboardLayout:) || theAction == @selector(removeKeyboardLayout:) ||
			 theAction == @selector(duplicateKeyboardLayout:)) {
			// Only active if there's a selection in the table
		NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
		if (selectedRowNumber == -1) {
			selectedRowNumber = [keyboardLayoutsTable clickedRow];
		}
		return (selectedRowNumber != -1);
	}
	return [super validateUserInterfaceItem:anItem];
}

#pragma mark User actions

	// Add a current keyboard layout window

- (IBAction)addOpenDocument:(id)sender {
		// Search for unbundled keyboard layouts
	NSDocumentController *theController = [NSDocumentController sharedDocumentController];
	NSArray *theDocumentList = [theController documents];
	NSMutableArray *candidateKeyboardLayouts = [NSMutableArray array];
	NSAssert([theDocumentList count] > 0, @"Must have some open documents");
	for (NSDocument *theDocument in theDocumentList) {
		if ([theDocument isKindOfClass:[UKKeyboardDocument class]] && ![(UKKeyboardDocument *)theDocument isBundle] && theDocument != self) {
				// This is the kind of document we want
			[candidateKeyboardLayouts addObject:theDocument];
		}
	}
	NSAssert([candidateKeyboardLayouts count] > 0, @"Must have some candidate documents");
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
	NSAssert([windowControllers count] > 0, @"Must be at least one window controller");
	NSWindowController *windowController = windowControllers[0];
	NSWindow *myWindow = [windowController window];
	[bundleVersionSheet beginSheetWithBundleName:self.bundleName
								   bundleVersion:self.bundleVersion
									buildVersion:self.buildVersion
								   sourceVersion:self.sourceVersion
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
	[self setTableSelectionForMenu];
	__block UKNewKeyboardLayoutController *theController = [UKNewKeyboardLayoutController createController];
	NSArray *windowControllers = [self windowControllers];
	NSAssert([windowControllers count] > 0, @"Must be at least one window controller");
	NSWindowController *windowController = windowControllers[0];
	NSWindow *myWindow = [windowController window];
	[theController runDialog:myWindow withCompletion:^(NSString *keyboardName, BaseLayoutTypes baseLayout, CommandLayoutTypes commandLayout, CapsLockLayoutTypes capsLockLayout) {
		[self addNewKeyboardLayoutWithName:keyboardName base:baseLayout command:commandLayout capsLock:capsLockLayout];
		theController = nil;
	}];
}

- (void)addNewKeyboardLayoutWithName:(NSString *)keyboardName base:(BaseLayoutTypes)baseLayout command:(CommandLayoutTypes)commandLayout capsLock:(CapsLockLayoutTypes)capsLockLayout {
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
			// Get a valid name
		NSString *theName = keyboardName;
		if ([theName length] == 0) {
			theName = @"Untitled";
		}
		UkeleleKeyboardObject *keyboardObject = [[UkeleleKeyboardObject alloc] initWithName:theName base:base command:command capsLock:capsLock];
		[self addNewDocument:keyboardObject];
	}
}

	// Remove the selected keyboard layout from the bundle

- (IBAction)removeKeyboardLayout:(id)sender {
	[self setTableSelectionForMenu];
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
	[self setTableSelectionForMenu];
	NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	KeyboardLayoutInformation *selectedRowInfo = self.keyboardLayouts[selectedRowNumber];
	UKKeyboardController *keyboardController = [selectedRowInfo keyboardController];
	if (keyboardController == nil) {
		keyboardController = [self createControllerForEntry:selectedRowInfo];
	}
	NSAssert(keyboardController, @"Keyboard controller must exist");
	[keyboardController showWindow:self];
}

	// Choose the intended language of the selected keyboard layout

- (IBAction)chooseIntendedLanguage:(id)sender {
	[self setTableSelectionForMenu];
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
	NSAssert([windowControllers count] > 0, @"Must be at least one window controller");
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
		iconData = [NSMutableData dataWithContentsOfURL:(__bridge NSURL *)keyboardIconURL];
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
					// Work around a bug
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
	[self setTableSelectionForMenu];
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
	[self setTableSelectionForMenu];
	NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	KeyboardLayoutInformation *keyboardEntry = self.keyboardLayouts[selectedRowNumber];
	UKKeyboardController *keyboardController = [keyboardEntry keyboardController];
	if (keyboardController == nil) {
			// Create the controller
		keyboardController = [self createControllerForEntry:keyboardEntry];
	}
	NSAssert(keyboardController, @"Keyboard controller must exist");
	NSWindow *docWindow = [keyboardLayoutsTable window];
	NSAssert(docWindow, @"Must have a document window");
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
	NSAssert(targetWindow, @"Must have a valid window");
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
	NSAssert(targetWindow, @"Must have a valid window");
	UkeleleKeyboardInstaller *theInstaller = [UkeleleKeyboardInstaller defaultInstaller];
	NSError *theError;
	BOOL installOK = [theInstaller installForCurrentUser:[self fileURL] error:&theError];
	if (!installOK) {
		[self presentError:theError modalForWindow:targetWindow delegate:nil didPresentSelector:nil contextInfo:nil];
	}
}

- (IBAction)duplicateKeyboardLayout:(id)sender {
	[self setTableSelectionForMenu];
	NSInteger selectedRowNumber = [keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	KeyboardLayoutInformation *selectedRowInfo = self.keyboardLayouts[selectedRowNumber];
	UkeleleKeyboardObject *keyboardObject = [selectedRowInfo keyboardObject];
	NSDocumentController *theController = [NSDocumentController sharedDocumentController];
	NSError *theError;
	UKKeyboardDocument *newDocument = [theController makeUntitledDocumentOfType:kFileTypeKeyboardLayout error:&theError];
	if (newDocument != nil) {
			// Got the document
		[theController addDocument:newDocument];
		[newDocument setupKeyboard:[keyboardObject copy]];
		[newDocument showWindows];
	}
}

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError *__autoreleasing *)outError {
	UKDocumentPrintViewController *printViewController = [UKDocumentPrintViewController documentPrintViewController];
	NSAssert(printViewController, @"Must have a print view controller");
	[printViewController setCurrentDocument:self];
	return [NSPrintOperation printOperationWithView:[printViewController view]];
}

#pragma mark Notifications

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

- (void)notifyNewName:(NSString *)newName forDocument:(id)keyboardDocument {
	NSAssert([keyboardDocument isKindOfClass:[UKKeyboardController class]], @"Document must be a Ukelele document");
		// Find the document in the list
	for (KeyboardLayoutInformation *keyboardInfo in self.keyboardLayouts) {
		if ([keyboardInfo keyboardController] == keyboardDocument) {
			[keyboardInfo setKeyboardName:[(UKKeyboardController *)keyboardDocument keyboardDisplayName]];
			break;
		}
	}
	[self keyboardLayoutDidChange:[(UKKeyboardController *)keyboardDocument keyboardLayout]];
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

- (void)inspectorDidAppear {
	InspectorWindowController *inspectorController = [InspectorWindowController getInstance];
	[self inspectorDidActivateTab:[[[inspectorController tabView] selectedTabViewItem] identifier]];
	[inspectorController setCurrentBundle:self];
	[inspectorController setCurrentWindow:nil];
	static NSDictionary *bindingsDict;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		bindingsDict = @{NSConditionallySetsEditableBindingOption: @YES,
						 NSRaisesForNotApplicableKeysBindingOption: @YES
						 };
	});
	[inspectorController bind:@"currentKeyboard" toObject:self.keyboardLayoutsController withKeyPath:@"selection.keyboardObject" options:bindingsDict];
	if ([keyboardLayoutsTable selectedRow] == -1) {
		[inspectorController setCurrentKeyboard:NSNoSelectionMarker];
	}
	[self inspectorSetKeyboardSection];
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
	[self inspectorDidAppear];
}

- (void)windowDidResignMain:(NSNotification *)notification {
	InspectorWindowController *inspectorController = [InspectorWindowController getInstance];
	[inspectorController setCurrentBundle:nil];
	[inspectorController unbind:@"currentDocument"];
}

#pragma mark Callbacks

- (void)confirmDelete:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	if (returnCode == NSAlertAlternateReturn) {
			// User cancelled
		return;
	}
	NSInteger indexToDelete = [(__bridge NSNumber *)contextInfo integerValue];
	[self removeDocumentAtIndex:indexToDelete];
}

- (void)acceptChooseOpenDocument:(NSString *)chosenItem {
	if (nil == chosenItem) {
			// User cancelled
		askFromListSheet = nil;
		return;
	}
	NSDocumentController *theController = [NSDocumentController sharedDocumentController];
	NSArray *theDocumentList = [theController documents];
	NSAssert([theDocumentList count] > 0, @"Must have some documents");
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
}

- (void)addNewDocument:(UkeleleKeyboardObject *)newDocument {
	NSUInteger newIndex = [self.keyboardLayoutsController.arrangedObjects count];
	[self insertDocument:newDocument atIndex:newIndex];
	NSUndoManager *undoManager = [self undoManager];
	[undoManager setActionName:@"Add keyboard layout"];
}

- (void)removeDocumentAtIndex:(NSUInteger)indexToRemove {
	NSAssert(indexToRemove < [self.keyboardLayoutsController.arrangedObjects count], @"Index is invalid");
	KeyboardLayoutInformation *keyboardInfo = self.keyboardLayouts[indexToRemove];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] replaceDocument:keyboardInfo atIndex:indexToRemove];
	[undoManager setActionName:@"Remove keyboard layout"];
	[self.keyboardLayoutsController removeObjectAtArrangedObjectIndex:indexToRemove];
	[keyboardLayoutsTable deselectAll:self];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
		// Hide the document's windows, if they are shown
	UKKeyboardController *keyboardController = [keyboardInfo keyboardController];
	if (keyboardController != nil) {
		[keyboardController close];
	}
}

- (void)insertDocument:(UkeleleKeyboardObject *)newDocument atIndex:(NSInteger)newIndex {
	NSAssert(newIndex <= [self.keyboardLayoutsController.arrangedObjects count], @"Index is invalid");
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeDocumentAtIndex:newIndex];
	[undoManager setActionName:@"Insert keyboard layout"];
		// Create dictionary with appropriate information
	KeyboardLayoutInformation *keyboardInfo = [[KeyboardLayoutInformation alloc] initWithObject:newDocument fileName:nil];
	[self.keyboardLayoutsController insertObject:keyboardInfo atArrangedObjectIndex:newIndex];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
	[keyboardLayoutsTable scrollRowToVisible:newIndex];
}

- (void)replaceDocument:(KeyboardLayoutInformation *)keyboardInfo atIndex:(NSUInteger)index {
	NSAssert(index < [self.keyboardLayoutsController.arrangedObjects count], @"Index is invalid");
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeDocumentAtIndex:index];
	[undoManager setActionName:@"Insert keyboard layout"];
	[self.keyboardLayoutsController insertObject:keyboardInfo atArrangedObjectIndex:index];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
}

- (void)addIcon:(NSData *)iconData atIndex:(NSUInteger)index {
	NSAssert(index < [self.keyboardLayoutsController.arrangedObjects count], @"Index is invalid");
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeIconAtIndex:index];
	[undoManager setActionName:@"Add icon"];
	KeyboardLayoutInformation *keyboardInfo = self.keyboardLayoutsController.arrangedObjects[index];
	[keyboardInfo setIconData:iconData];
	[keyboardInfo setHasIcon:YES];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
}

- (void)removeIconAtIndex:(NSUInteger)index {
	NSAssert(index < [self.keyboardLayoutsController.arrangedObjects count], @"Index is invalid");
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
	NSAssert(index < [self.keyboardLayoutsController.arrangedObjects count], @"Index is invalid");
	KeyboardLayoutInformation *keyboardInfo = self.keyboardLayoutsController.arrangedObjects[index];
	NSData *oldIconData = [keyboardInfo iconData];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] replaceIconAtIndex:index withIcon:oldIconData];
	[undoManager setActionName:@"Change icon"];
	[keyboardInfo setIconData:iconData];
		// Notify the list that it's been updated
	[keyboardLayoutsTable reloadData];
}

- (void)replaceIntendedLanguageAtIndex:(NSUInteger)index withLanguage:(LanguageCode *)newLanguage {
	NSAssert(index < [self.keyboardLayoutsController.arrangedObjects count], @"Index is invalid");
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
		[self addIcon:iconData atIndex:[self.keyboardLayoutsController.arrangedObjects count] - 1];
	}
	if (intendedLanguage != nil) {
		[self replaceIntendedLanguageAtIndex:[self.keyboardLayoutsController.arrangedObjects count] - 1 withLanguage:[LanguageCode languageCodeFromString:intendedLanguage]];
	}
	[undoManager setActionName:@"Capture current input source"];
	[undoManager endUndoGrouping];
}

@end

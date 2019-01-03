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
#import "UKNewKeyboardLayoutController.h"
#import "UKDocumentPrintViewController.h"
#import "UKKeyboardPasteboardItem.h"
#import "UKProgressWindow.h"
#import "LocaleDialogController.h"
#import "LocalisationData.h"
#import "LocaliseKeyboardController.h"
#import "UKFileUtilities.h"
#import <Carbon/Carbon.h>

#define UKKeyboardControllerNibName @"UkeleleDocument"
#define UKKeyboardConverterTool	@"kluchrtoxml"
#define UKIconutilTool @"iconutil"
	
// Dictionary keys
NSString *kIconFileKey = @"IconFile";
NSString *kKeyboardObjectKey = @"KeyboardObject";
NSString *kKeyboardNameKey = @"KeyboardName";
NSString *kKeyboardWindowKey = @"KeyboardWindow";
NSString *kKeyboardFileNameKey = @"KeyboardFileName";
NSString *kKeyboardFileWrapperKey = @"KeyboardFileWrapper";

	// Key paths
NSString *kKeyboardName = @"keyboardName";
NSString *kIntendedLanguageName = @"intendedLanguage";
NSString *kLocaleString = @"localeString";
NSString *kLocaleDescription = @"localeDescription";

	// Column identifiers
NSString *kKeyboardColumn = @"KeyboardName";
NSString *kIconColumn = @"Icon";
NSString *kLanguageColumn = @"Language";
NSString *kLocaleColumn = @"Locale";
NSString *kLocaleDescriptionColumn = @"LocaleDescription";

	// Tab identifiers
NSString *kKeyboardLayoutsTab = @"KeyboardLayouts";
NSString *kLocalisationsTab = @"Localisations";

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
	LocaleDialogController *localeController;
}

- (instancetype)init
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
		_localisations = [NSMutableArray array];
		localeController = nil;
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
			_keyboardLayout = [[UkeleleKeyboardObject alloc] initWithName:@"Untitled"];
			[_keyboardLayout setParentDocument:self];
		}
		else if ([typeName isEqualToString:(NSString *)kUTTypeBundle] || [typeName isEqualToString:kFileTypeGenericBundle]) {
				// Bundle
			_isBundle = YES;
				// Add an English localisation so we have at least one
			LocalisationData *data = [[LocalisationData alloc] init];
			[data setLocaleCode:[LocaleCode localeCodeFromString:@"en"]];
			[self.localisations addObject:data];
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

- (instancetype)initWithKeyboardObject:(UkeleleKeyboardObject *)keyboardObject {
	self = [self init];
	if (self) {
		_isBundle = NO;
		_keyboardLayout = keyboardObject;
		[_keyboardLayout setParentDocument:self];
	}
	return self;
}

- (void)makeWindowControllers {
	if (!self.isBundle) {
			// Stand-alone keyboard layout
		NSArray *theControllers = [self windowControllers];
		if ([theControllers count] > 0) {
				// We already have a controller
			return;
		}
		UKKeyboardController *keyboardController = [[UKKeyboardController alloc] initWithWindowNibName:UKKeyboardControllerNibName];
		NSAssert(keyboardController, @"Must be able to create a keyboard controller");
		[self addWindowController:keyboardController];
		[keyboardController setParentDocument:self];
		[keyboardController setKeyboardLayout:self.keyboardLayout];
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
		// Register for our drag types
	[self.keyboardLayoutsTable registerForDraggedTypes:@[UKKeyboardPasteType, (NSString *)kUTTypeFileURL]];
		// Tell the Finder that it can copy files out
	[self.keyboardLayoutsTable setDraggingSourceOperationMask:NSDragOperationCopy forLocal:NO];
		// Set the sorting for the tables
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kKeyboardName ascending:YES selector:@selector(localizedStandardCompare:)];
	[self.keyboardLayoutsController setSortDescriptors:@[sortDescriptor]];
	[self.keyboardLayouts sortUsingDescriptors:@[sortDescriptor]];
	[self.keyboardLayoutsTable reloadData];
	sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kLocaleDescription ascending:YES selector:@selector(localizedStandardCompare:)];
	[self.localisationsController setSortDescriptors:@[sortDescriptor]];
	[self.localisations sortUsingDescriptors:@[sortDescriptor]];
	[self.localisationsTable reloadData];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError * _Nullable __autoreleasing *)outError {
		// See whether we have a file that is in an installation directory
	if ([UKFileUtilities isKeyboardLayoutsURL:url]) {
		NSDictionary *errorDict = @{NSLocalizedDescriptionKey: @"Ukelele cannot open a keyboard layout or collection that has been installed",
									NSLocalizedRecoverySuggestionErrorKey: @"Please open a copy and then install the new version"};
		*outError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorCannotOpenInstalledFile userInfo:errorDict];
		return NO;
	}
	NSFileWrapper *theWrapper = [[NSFileWrapper alloc] initWithURL:url options:0 error:outError];
	if (theWrapper == nil) {
			// Failed to create the file wrapper for some reason
		return NO;
	}
	return [self readFromFileWrapper:theWrapper ofType:typeName error:outError];
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
				}
				return NO;
			}
		}
		else if (self.isBundle && ([typeName isEqualToString:(NSString *)kUTTypeBundle] || [typeName isEqualToString:kFileTypeGenericBundle])) {
				// A bundle
			if ((saveOperation == NSSaveAsOperation || saveOperation == NSSaveToOperation) && [[self.keyboardLayoutsController arrangedObjects] count] == 0) {
					// Can't save a bundle with no keyboard layouts
				if (outError != nil) {
					NSDictionary *localError = @{NSLocalizedDescriptionKey: @"Cannot save a bundle containing no keyboard layouts"};
					*outError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorNoKeyboardLayoutsInBundle userInfo:localError];
				}
				return NO;
			}
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

- (NSString *)nameForCopyOf:(NSString *)baseName {
	NSString *result = [baseName stringByAppendingString:@" copy"];
	if ([baseName hasSuffix:@" copy"]) {
			// Already have " copy" at the end, so add " 2"
		result = [baseName stringByAppendingString:@" 2"];
	}
	else {
		NSPredicate *matchPredicate = [NSPredicate predicateWithFormat:@"SELF matches \".* copy [0-9]+$\""];
		if ([matchPredicate evaluateWithObject:baseName]) {
				// Have a name that ends with " copy [number]"
			NSRange spaceRange = [baseName rangeOfString:@" " options:NSBackwardsSearch];
				// We have the position of the last space, so the number will be
				// the rest of the string
			NSRange numberRange = NSMakeRange(spaceRange.location + 1, baseName.length - spaceRange.location - 1);
			NSString *numberString = [baseName substringWithRange:numberRange];
			NSInteger numberValue = [numberString integerValue];
			result = [baseName stringByReplacingOccurrencesOfString:numberString withString:[NSString stringWithFormat:@"%ld", numberValue + 1] options:0 range:numberRange];
		}
	}
	return result;
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
	KeyboardLayoutInformation *layoutInfo = [self.keyboardLayoutsController arrangedObjects][0];
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
		free(tempFileTemplate);
		return nil;
	}
	tempFilePath = @(tempFileTemplate);
	free(tempFileTemplate);
	NSURL *tempFileURL = [NSURL fileURLWithPath:tempFilePath];
		// We don't need the temporary file any more, since we're going to create a resource fork
	int result = close(tempFileDescriptor);
#pragma unused(result)
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
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
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfour-char-constants"
	AddResource(theHandle, kResType_uchr, UniqueID(kResType_uchr), resourceName);
#pragma clang diagnostic pop
	UpdateResFile(CurResFile());
	FSCloseFork(resFile);
#pragma clang diagnostic pop
		// Get the conversion tool
	NSURL *toolURL = [[NSBundle mainBundle] URLForAuxiliaryExecutable:UKKeyboardConverterTool];
		// Set up and run the tool
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *currentDirectory = [fileManager currentDirectoryPath];
	[fileManager changeCurrentDirectoryPath:[(__bridge NSURL *)parentURL path]];
	NSTask *conversionTask = [NSTask launchedTaskWithLaunchPath:[toolURL path] arguments:@[[tempFileURL path]]];
	[conversionTask waitUntilExit];
	int returnStatus = [conversionTask terminationStatus];
#pragma unused(returnStatus)
	NSAssert(returnStatus == 0 || returnStatus == EINTR, @"Could not run conversion tool");
	CFRelease(tempFileName);
	CFRelease(parentURL);
	[fileManager removeItemAtURL:tempFileURL error:nil];
	[fileManager changeCurrentDirectoryPath:currentDirectory];
		// Finally, read the resulting file
	NSURL *outputFileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@.keylayout", tempDirectory, keyboardName]];
	NSError *theError = nil;
	NSData *myData = [NSData dataWithContentsOfURL:outputFileURL options:0 error:&theError];
	[fileManager removeItemAtURL:outputFileURL error:nil];
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
	BOOL saveResult = [keyboardData writeToURL:fileURL options:0 error:outError];
	// Get the window controller
	NSArray *windowControllers = [self windowControllers];
	UKKeyboardController *keyboardController = (UKKeyboardController *)windowControllers[0];
	if (saveResult && keyboardController.iconFile != nil) {
		// Save the icns file too
		NSURL *parentDirectory = [fileURL URLByDeletingLastPathComponent];
		NSString *fileName = [self.fileURL lastPathComponent];
		NSString *iconFileName = [fileName stringByReplacingOccurrencesOfString:kStringKeyboardLayoutExtension withString:kStringIcnsExtension];
		NSURL *iconFileURL = [parentDirectory URLByAppendingPathComponent:iconFileName];
		NSData *iconData = [NSData dataWithContentsOfURL:keyboardController.iconFile];
		saveResult = [iconData writeToURL:iconFileURL options:0 error:outError];
	}
	return saveResult;
}

- (NSFileWrapper *)createFileWrapper {
		// Make a copy of the keyboard layouts array so that we don't have it change under us
	NSArray *keyboardLayouts = [self.keyboardLayouts copy];
		// Allow the user to interact while we save asynchronously
	[self unblockUserInteraction];
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
		// Create the InfoPlist.strings files, which contain all the names
	for (LocalisationData *localisationData in self.localisations) {
			// For each keyboard, look for a name localised to this language
		NSMutableString *infoPlistString = [NSMutableString stringWithString:@""];
		for (KeyboardLayoutInformation *keyboardEntry in keyboardLayouts) {
			NSString *keyboardName = [keyboardEntry keyboardName];
			if (keyboardName != nil && ![keyboardName isEqualToString:@""]) {
				NSString *localisedName = keyboardEntry.localisedNames[[localisationData localeString]];
				if (localisedName == nil) {
						// If no localised name, use the base name
					localisedName = keyboardName;
				}
				[infoPlistString appendString:[NSString stringWithFormat:@"\"%@\" = \"%@\";\n", keyboardName, localisedName]];
			}
		}
		NSData *infoPlistData = [infoPlistString dataUsingEncoding:NSUTF16StringEncoding];
		NSFileWrapper *infoPlistStringsFile = [[NSFileWrapper alloc] initRegularFileWithContents:infoPlistData];
		[infoPlistStringsFile setPreferredFilename:kStringInfoPlistStringsName];
			// Put the InfoPlist.strings file into an English.lproj directory
		NSFileWrapper *lprojDirectory = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:@{}];
		[lprojDirectory setPreferredFilename:[NSString stringWithFormat:@"%@.%@", [localisationData localeString], kStringLocalisationSuffix]];
		[lprojDirectory addFileWrapper:infoPlistStringsFile];
		[resourcesDirectory addFileWrapper:lprojDirectory];
	}
		// Add all the keyboard layout and icon files
	for (KeyboardLayoutInformation *keyboardEntry in keyboardLayouts) {
		NSString *keyboardName = [keyboardEntry fileName];
			// Test whether we have a null or untitled file name
		if (nil == keyboardName || [keyboardName isEqualToString:@""] ||
			[keyboardName compare:UKUntitledName options:(NSAnchoredSearch | NSCaseInsensitiveSearch)] == NSOrderedSame) {
			keyboardName = [keyboardEntry keyboardName];
		}
		if (![[keyboardEntry keyboardName] isEqualToString:[keyboardEntry fileName]]) {
				// The keyboard name doesn't match the file name
			keyboardName = [keyboardEntry keyboardName];
			[keyboardEntry setFileName:keyboardName];
			if ([keyboardEntry keyboardFileWrapper] != nil) {
					// We have to remove the file wrapper, since we're changing the name
				[keyboardEntry setKeyboardFileWrapper:nil];
			}
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
		// Check for no bundle ID or an old one with two dots
	if ([self.bundleIdentifier isEqualToString:@""] ||
		[self.bundleIdentifier hasPrefix:[NSString stringWithFormat:@"%@..", kStringAppleKeyboardLayoutBundleID]] ||
		[self.bundleIdentifier hasPrefix:[NSString stringWithFormat:@"%@..", kStringUkeleleKeyboardLayoutBundleID]] ||
		[self.bundleIdentifier hasSuffix:@"."]) {
			// Create the bundle identifier
		BOOL tigerCompatibleBundleIdentifier = [[NSUserDefaults standardUserDefaults] boolForKey:UKTigerCompatibleBundles];
		NSString *baseString = tigerCompatibleBundleIdentifier ? kStringAppleKeyboardLayoutBundleID : kStringUkeleleKeyboardLayoutBundleID;
		NSString *extensionString = [[self.bundleName lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
		self.bundleIdentifier = [NSString stringWithFormat:@"%@.%@", baseString, extensionString];
	}
	infoPlist[(NSString *)kCFBundleIdentifierKey] = self.bundleIdentifier;
		// Set the bundle name
	infoPlist[(NSString *)kCFBundleNameKey] = self.bundleName;
		// Set the version number
	infoPlist[(NSString *)kCFBundleVersionKey] = self.bundleVersion;
		// Get the intended languages for each keyboard layout in the bundle
	for (KeyboardLayoutInformation *keyboardEntry in self.keyboardLayouts) {
		NSString *languageIdentifier = [keyboardEntry intendedLanguage];
		if (nil != languageIdentifier && [languageIdentifier length] > 0) {
				// Add this language identifier
			NSString *keyboardName = [keyboardEntry keyboardName];
			NSString *fileName = [keyboardEntry fileName];
			if (fileName == nil) {
				fileName = keyboardName;
			}
			NSString *KLInfoIdentifier = [NSString stringWithFormat:@"%@%@", kStringInfoPlistKLInfoPrefix, fileName];
			NSString *keyboardIdentifier = [NSString stringWithFormat:@"%@.%@", self.bundleIdentifier, [[fileName lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""]];
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
		NSString *dirName = [directoryEntry preferredFilename];
		if ([dirName compare:kStringContentsName options:NSCaseInsensitiveSearch] == NSEqualToComparison) {
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
		if ([[directoryEntry preferredFilename] compare:kStringInfoPlistFileName options:NSCaseInsensitiveSearch] == NSEqualToComparison) {
				// Got the Info.plist file
			infoPlistFile = directoryEntry;
			[self parseInfoPlist:infoPlistFile];
		}
		else if ([[directoryEntry preferredFilename] compare:kStringResourcesName options:NSCaseInsensitiveSearch] == NSEqualToComparison) {
				// Got the Resources directory
			resourcesDirectory = directoryEntry;
		}
		else if ([[directoryEntry preferredFilename] compare:kStringVersionPlistFileName options:NSCaseInsensitiveSearch] == NSEqualToComparison) {
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
	NSMutableDictionary *localisationDictionary = [NSMutableDictionary dictionary];
	while ((directoryEntry = [directoryEnumerator nextObject])) {
		NSString *fileName = [[directoryEntry preferredFilename] decomposedStringWithCanonicalMapping];
		BOOL isKeyboardLayout = [fileName hasSuffix:[NSString stringWithFormat:@".%@", kStringKeyboardLayoutExtension]];
		BOOL isIconFile = [fileName hasSuffix:[NSString stringWithFormat:@".%@", kStringIcnsExtension]];
		BOOL islprojDirectory = [fileName hasSuffix:[NSString stringWithFormat:@".%@", kStringLocalisationSuffix]] && [directoryEntry isDirectory];
		if (isKeyboardLayout || isIconFile) {
			NSString *fileBaseName = [fileName stringByDeletingPathExtension];
			NSMutableDictionary *baseNameDictionary = fileNameDictionary[fileBaseName];
			if (nil == baseNameDictionary) {
				baseNameDictionary = [NSMutableDictionary dictionary];
				fileNameDictionary[fileBaseName] = baseNameDictionary;
			}
			if (isKeyboardLayout) {
					// It's a keyboard layout file
					// Save the file name
				fileName = [directoryEntry filename];
				baseNameDictionary[kKeyboardFileNameKey] = [fileName stringByDeletingPathExtension];
				baseNameDictionary[kKeyboardFileWrapperKey] = directoryEntry;
					// We don't have the keyboard name yet, so use the file name
				baseNameDictionary[kKeyboardNameKey] = baseNameDictionary[kKeyboardFileNameKey];
			}
			else if (isIconFile) {
					// It's an icon file
				baseNameDictionary[kIconFileKey] = directoryEntry;
			}
		}
		else if (islprojDirectory) {
			NSString *localisationName = [fileName stringByDeletingPathExtension];
				// Change special cases to standard
			if ([localisationName isEqualToString:@"English"]) {
				localisationName = @"en";
			}
			else if ([localisationName isEqualToString:@"French"]) {
				localisationName = @"fr";
			}
			else if ([localisationName isEqualToString:@"Spanish"]) {
				localisationName = @"es";
			}
			else if ([localisationName isEqualToString:@"German"]) {
				localisationName = @"de";
			}
				// Get the InfoPlist.strings file
			NSDictionary *localisationDirectory = [directoryEntry fileWrappers];
			NSFileWrapper *localisationStrings = localisationDirectory[kStringInfoPlistStringsName];
			if (localisationStrings != nil) {
					// We have a valid InfoPlist.strings file
				NSString *localisations = [[NSString alloc] initWithData:[localisationStrings regularFileContents] encoding:NSUTF16StringEncoding];
				NSDictionary *localisationList = [self parseStringsFile:localisations];
				localisationDictionary[localisationName] = localisationList;
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
			// Get the localised names
		for (NSString *localisationKey in [localisationDictionary allKeys]) {
			NSDictionary *localisationValues = localisationDictionary[localisationKey];
			if (localisationValues[keyboardName] != nil) {
					// Have a localisation in this language
				keyboardInfo.localisedNames[localisationKey] = localisationValues[keyboardName];
			}
			else {
				keyboardInfo.localisedNames[localisationKey] = keyboardName;
			}
		}
		[self.keyboardLayouts addObject:keyboardInfo];
	}
		// Now create the localisations data structure
	for (NSString *localisationKey in [[localisationDictionary allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
		return [obj1 localizedStandardCompare:obj2];
	}]) {
		LocaleCode *theLocale = [LocaleCode localeCodeFromString:localisationKey];
		if (theLocale != nil) {
				// Valid locale code
			LocalisationData *theData = [[LocalisationData alloc] init];
			[theData setLocaleCode:theLocale];
			[theData setLocalisationStrings:localisationDictionary[localisationKey]];
			[self.localisations addObject:theData];
		}
	}
	return YES;
}

- (NSDictionary *)parseStringsFile:(NSString *)fileData {
	NSMutableDictionary *theStrings = [NSMutableDictionary dictionary];
	NSPredicate *predicateString = [NSPredicate predicateWithFormat:@"SELF matches \"\\\".*\\\" += +\\\".*\\\";\""];
	[fileData enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
#pragma unused(stop)
			// Only operate on non-comment lines
		if (![line hasPrefix:@"/*"]) {
			if ([predicateString evaluateWithObject:line]) {
					// Have an appropriate line, so find the quotation marks
				NSUInteger stringLength = [line length];
				NSRange firstRange = [line rangeOfString:@"\"" options:0 range:NSMakeRange(0, stringLength)];
				NSRange secondRange = [line rangeOfString:@"\"" options:0 range:NSMakeRange(firstRange.location + 1, stringLength - firstRange.location - 1)];
				NSRange thirdRange = [line rangeOfString:@"\"" options:0 range:NSMakeRange(secondRange.location + 1, stringLength - secondRange.location - 1)];
				NSRange fourthRange = [line rangeOfString:@"\"" options:0 range:NSMakeRange(thirdRange.location + 1, stringLength - thirdRange.location - 1)];
				NSString *lhsString = [line substringWithRange:NSMakeRange(firstRange.location + 1, secondRange.location - firstRange.location - 1)];
				NSString *rhsString = [line substringWithRange:NSMakeRange(thirdRange.location + 1, fourthRange.location - thirdRange.location - 1)];
				theStrings[lhsString] = rhsString;
			}
		}
	}];
	return theStrings;
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
			NSString *keyboardName = [[plistKey substringFromIndex:[kStringInfoPlistKLInfoPrefix length]] decomposedStringWithCanonicalMapping];
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
	if ([keyboardEntry hasBadKeyboard]) {
			// The keyboard layout can't load successfully, so don't try it
		return nil;
	}
	UKKeyboardController *keyboardController = [[UKKeyboardController alloc] initWithWindowNibName:UKKeyboardControllerNibName];
	if ([keyboardEntry keyboardObject] == nil) {
			// Not loaded, so load it now
		NSError *readError;
		NSFileWrapper *fileWrapper = [keyboardEntry keyboardFileWrapper];
		NSData *fileData = [fileWrapper regularFileContents];
		UkeleleKeyboardObject *keyboardObject = [[UkeleleKeyboardObject alloc] initWithData:fileData withError:&readError];
		if (keyboardObject == nil) {
				// Couldn't read the file
			[self presentError:readError];
			[keyboardEntry setHasBadKeyboard:YES];
			return nil;
		}
		[keyboardEntry setKeyboardObject:keyboardObject];
		[keyboardEntry setKeyboardName:[keyboardObject keyboardName]];
	}
	[keyboardController setKeyboardLayout:[keyboardEntry keyboardObject]];
	[keyboardEntry setKeyboardController:keyboardController];
	[keyboardController setParentDocument:self];
	return keyboardController;
}

- (UKKeyboardController *)controllerForCurrentEntry {
	NSInteger selectedRowNumber = [self.keyboardLayoutsTable selectedRow];
	NSAssert(selectedRowNumber >= 0, @"Must have a selected row");
	KeyboardLayoutInformation *selectedRowInfo = [self.keyboardLayoutsController arrangedObjects][selectedRowNumber];
	UKKeyboardController *theController = [selectedRowInfo keyboardController];
	if (theController == nil) {
		theController = [self createControllerForEntry:selectedRowInfo];
	}
	return theController;
}

- (void)exportInstallerTo:(NSURL *)targetURL {
		// Make a progress reporter
	UKProgressWindow *progressWindow = [UKProgressWindow progressWindow];
	NSString *messageText;
	if (self.isBundle) {
		messageText = @"Saving keyboard layout collection to a disk image";
	}
	else {
		messageText = @"Saving keyboard layout to a disk image";
	}
	[progressWindow.mainText setStringValue:messageText];
	[progressWindow.secondaryText setStringValue:@"Assembling data"];
	NSWindow *myWindow = self.windowControllers[0].window;
	[[NSApplication sharedApplication] beginSheet:progressWindow.window modalForWindow:myWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
	[progressWindow showWindow:self];
	[progressWindow.progressIndicator startAnimation:nil];
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
		[self createInstallerDiskImage:targetURL withProgress:progressWindow];
	});
}

- (void)createInstallerDiskImage:(NSURL *)targetURL withProgress:(UKProgressWindow *)progressWindow {
		// Create a temporary directory
	NSString *tempDirectory = NSTemporaryDirectory();
	NSString *tempDirectoryPath = [NSString stringWithFormat:@"%@UkeleleExportXXXXX", tempDirectory];
	NSUInteger pathLength = [tempDirectoryPath length];
	char *tempDirectoryTemplate = malloc(pathLength * 3 + 1);
	[tempDirectoryPath getCString:tempDirectoryTemplate maxLength:pathLength * 3 encoding:NSUTF8StringEncoding];
	char *tempDirectoryName = mkdtemp(tempDirectoryTemplate);
	if (tempDirectoryName == NULL) {
			// Could not create temporary directory
		free(tempDirectoryTemplate);
		dispatch_async(dispatch_get_main_queue(), ^{
			[progressWindow.window orderOut:self];
			[[NSApplication sharedApplication] endSheet:progressWindow.window];
		});
		return;
	}
	tempDirectoryPath = @(tempDirectoryTemplate);
	free(tempDirectoryTemplate);
	NSURL *tempDirectoryURL = [NSURL fileURLWithPath:tempDirectoryPath isDirectory:YES];
		// Create the target directory
	NSString *targetDirectoryName = [[targetURL lastPathComponent] stringByDeletingPathExtension];
	NSURL *targetDirectoryURL = [tempDirectoryURL URLByAppendingPathComponent:targetDirectoryName isDirectory:YES];
	NSError *theError;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	BOOL success = [fileManager createDirectoryAtURL:targetDirectoryURL withIntermediateDirectories:YES attributes:nil error:&theError];
	if (!success) {
			// Failed to create the target directory
		dispatch_async(dispatch_get_main_queue(), ^{
			[progressWindow.window orderOut:self];
			[[NSApplication sharedApplication] endSheet:progressWindow.window];
			[self presentError:theError];
		});
		return;
	}
		// Add a copy of the document to the directory
	NSString *documentName;
	if (self.isBundle) {
		documentName = [NSString stringWithFormat:@"%@%@", self.bundleName, kStringBundleExtension];
	}
	else {
		documentName = [NSString stringWithFormat:@"%@.%@", [self.keyboardLayout keyboardName], kStringKeyboardLayoutExtension];
	}
	NSURL *saveURL = [targetDirectoryURL URLByAppendingPathComponent:documentName];
	NSString *saveType = self.isBundle ? kFileTypeGenericBundle : kFileTypeKeyboardLayout;
	success = [self writeToURL:saveURL ofType:saveType forSaveOperation:NSSaveToOperation originalContentsURL:nil error:&theError];
	if (!success) {
			// Failed to save
		dispatch_async(dispatch_get_main_queue(), ^{
			[progressWindow.window orderOut:self];
			[[NSApplication sharedApplication] endSheet:progressWindow.window];
			[self presentError:theError];
		});
		return;
	}
		// Copy the installer application
	NSURL *resourcesURL = [[NSBundle mainBundle] URLForResource:kStringInstallerApplication withExtension:@"app"];
	NSURL *dropletURL = [[targetDirectoryURL URLByAppendingPathComponent:kStringInstallerApplication] URLByAppendingPathExtension:@"app"];
	NSError *installerAppError;
	if (![fileManager copyItemAtURL:resourcesURL toURL:dropletURL error:&installerAppError]) {
			// Could not create the application
		dispatch_async(dispatch_get_main_queue(), ^{
			[progressWindow.window orderOut:self];
			[[NSApplication sharedApplication] endSheet:progressWindow.window];
			[self presentError:installerAppError];
		});
		return;
	}
		// Now create and run the task to turn the directory into a disk image
	dispatch_async(dispatch_get_main_queue(), ^{
		[progressWindow.secondaryText setStringValue:@"Creating the disk image…"];
	});
	NSString *taskPath = @"/usr/bin/hdiutil";
	NSArray *taskParameters = @[@"create", @"-srcfolder", [targetDirectoryURL path], @"-ov", @"-quiet", [targetURL path]];
	NSTask *createTask = [NSTask launchedTaskWithLaunchPath:taskPath arguments:taskParameters];
	[createTask waitUntilExit];
		// Clean up the temporary files
	[fileManager removeItemAtURL:tempDirectoryURL error:nil];
		// Check exit status
	if ([createTask terminationStatus] != 0) {
			// The disk image creation failed
		int errorCode = [createTask terminationStatus];
		NSString *errorMessage;
		switch (errorCode) {
			case EPERM:
			case EACCES:
				errorMessage = @"Could not save the disk image in that location. You do not have permission to create a file in that folder";
				break;
				
			default:
				errorMessage = [NSString stringWithFormat:@"Creating the disk image failed with error %d", errorCode];
				break;
		}
		NSDictionary *errorDict = @{NSLocalizedDescriptionKey: errorMessage};
		theError = [NSError errorWithDomain:NSPOSIXErrorDomain code:errorCode userInfo:errorDict];
		dispatch_async(dispatch_get_main_queue(), ^{
			[progressWindow.window orderOut:self];
			[[NSApplication sharedApplication] endSheet:progressWindow.window];
			[self presentError:theError];
		});
		return;
	}
	dispatch_async(dispatch_get_main_queue(), ^{
		[progressWindow.window orderOut:self];
		[[NSApplication sharedApplication] endSheet:progressWindow.window];
	});
}

- (void)addIconData:(NSData *)iconData forKeyboard:(UkeleleKeyboardObject *)keyboard {
	for (KeyboardLayoutInformation *info in [self.keyboardLayoutsController arrangedObjects]) {
		if ([info keyboardObject] == keyboard) {
			if (iconData != NULL) {
				[self addIcon:iconData toKeyboardInfo:info];
			}
			else {
				[self removeIconFromKeyboardInfo:info];
			}
			break;
		}
	}
}

#pragma mark Saving and restoring selection

- (NSString *)currentSelectedName {
	NSInteger selectedRow = [self.keyboardLayoutsTable selectedRow];
	if (selectedRow == -1) {
		return nil;
	}
	KeyboardLayoutInformation *selectedRowInfo = [self.keyboardLayoutsController arrangedObjects][selectedRow];
	return [selectedRowInfo keyboardName];
}

- (void)restoreSelectedName:(NSString *)selectedName {
	if (selectedName == nil) {
			// Nothing to do
		return;
	}
	for (NSUInteger row = 0; row < [self.keyboardLayouts count]; row++) {
		KeyboardLayoutInformation *rowInfo = [self.keyboardLayoutsController arrangedObjects][row];
		if ([rowInfo keyboardName] == selectedName) {
				// Found it
			[self.keyboardLayoutsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
			break;
		}
	}
}

- (UKKeyboardController *)currentSelectedController {
	NSInteger selectedRow = [self.keyboardLayoutsTable selectedRow];
	if (selectedRow == -1) {
		return nil;
	}
	KeyboardLayoutInformation *selectedRowInfo = [self.keyboardLayoutsController arrangedObjects][selectedRow];
	return [selectedRowInfo keyboardController];
}

- (void)restoreSelectedController:(UKKeyboardController *)selectedController {
	if (selectedController == nil) {
			// Nothing to do
		return;
	}
	for (NSUInteger row = 0; row < [self.keyboardLayouts count]; row++) {
		KeyboardLayoutInformation *rowInfo = [self.keyboardLayoutsController arrangedObjects][row];
		if ([rowInfo keyboardController] == selectedController) {
				// Found it
			[self.keyboardLayoutsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
			break;
		}
	}
}

#pragma mark Table data source methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	if (tableView == self.keyboardLayoutsTable) {
			// Number of rows in keyboard layouts table
		return [self.keyboardLayouts count];
	}
	else if (tableView == self.localisationsTable) {
		return [self.localisations count];
	}
	else {
		return 0;
	}
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSString *resultString = @"";
	if (tableView == self.keyboardLayoutsTable) {
			// Object for keyboard layouts table
		KeyboardLayoutInformation *layoutInfo = [self.keyboardLayoutsController arrangedObjects][row];
		if ([[tableColumn identifier] isEqualToString:kIconColumn]) {
				// The icon column, so we need to get the actual icon
			NSData *iconData = [layoutInfo iconData];
			return [[NSImage alloc] initWithData:iconData];
		}
		else if ([[tableColumn identifier] isEqualToString:kKeyboardColumn]) {
				// Keyboard name
			resultString = [layoutInfo keyboardName];
		}
		else if ([[tableColumn identifier] isEqualToString:kLanguageColumn]) {
				// Intended language column
			resultString = [layoutInfo intendedLanguage];
		}
	}
	else if (tableView == self.localisationsTable) {
		LocalisationData *theData = [self.localisationsController arrangedObjects][row];
		if ([[tableColumn identifier] isEqualToString:kLocaleColumn]) {
			resultString = [theData localeString];
		}
		else if ([[tableColumn identifier] isEqualToString:kLocaleDescriptionColumn]) {
			resultString = [theData localeDescription];
		}
	}
	if (resultString == nil) {
		resultString = @"";
	}
	return resultString;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
#pragma unused(tableView)
#pragma unused(oldDescriptors)
	NSInteger selectedRowNumber;
	if (tableView == self.keyboardLayoutsTable) {
		selectedRowNumber = [self.keyboardLayoutsTable selectedRow];
		NSString *selectedLayout = [self currentSelectedName];
		[self.keyboardLayoutsController setSortDescriptors:[self.keyboardLayoutsTable sortDescriptors]];
		[self.keyboardLayouts sortUsingDescriptors:[self.keyboardLayoutsTable sortDescriptors]];
		[self.keyboardLayoutsTable reloadData];
		[self restoreSelectedName:selectedLayout];
	}
	else if (tableView == self.localisationsTable) {
		selectedRowNumber = [self.localisationsTable selectedRow];
		NSString *selectedLocale = @"";
		if (selectedRowNumber != -1) {
			selectedLocale = [[self.localisationsController arrangedObjects][selectedRowNumber] localeString];
		}
		[self.localisationsController setSortDescriptors:[self.localisationsTable sortDescriptors]];
		[self.localisations sortUsingDescriptors:[self.localisationsTable sortDescriptors]];
		[self.localisationsTable reloadData];
		if (selectedRowNumber != -1) {
			for (NSUInteger row = 0; row < [self.localisations count]; row++) {
				if ([selectedLocale isEqualToString:[self.localisations[row] localeString]]) {
					[self.localisationsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
					break;
				}
			}
		}
	}
}

#pragma mark Table delegate methods

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
		// We don't need to special case this for the two tables, since they all use NSTableCellView
	NSTableCellView *view = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:self];
	if (view == nil) {
		view = [[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, [tableColumn width], 10)];
		[view setIdentifier:[tableColumn identifier]];
	}
	if ([[tableColumn identifier] isEqualToString:kIconColumn]) {
		[view.imageView setImage:[self tableView:tableView objectValueForTableColumn:tableColumn row:row]];
	}
	else {
		[view.textField setStringValue:[self tableView:tableView objectValueForTableColumn:tableColumn row:row]];
	}
	return view;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
		// Check which tab we're on
	if ([kKeyboardLayoutsTab isEqualToString:[[self.tabView selectedTabViewItem] identifier]]) {
			// Keyboard tab
		if ([notification object] != self.keyboardLayoutsTable) {
			return;
		}
		[self inspectorSetKeyboardSection];
	}
	else if ([kLocalisationsTab isEqualToString:[[self.tabView selectedTabViewItem] identifier]]) {
			// Localisations tab
		if ([notification object] != self.localisationsTable) {
			return;
		}
			// Set the availability of the remove button
		[self.removeLocaleButton setEnabled:[self removeLocaleButtonShouldBeEnabled]];
	}
}

- (void)setTableSelectionForMenu {
	NSInteger clickedRow = [self.keyboardLayoutsTable clickedRow];
	if (clickedRow != -1) {
		if ([self.keyboardLayoutsTable selectedRow] != clickedRow) {
			[self.keyboardLayoutsTable selectRowIndexes:[NSIndexSet indexSetWithIndex:clickedRow] byExtendingSelection:NO];
		}
	}
}

#pragma mark Drag and Drop

- (NSDragOperation)tableView:(NSTableView *)tableView
				validateDrop:(id<NSDraggingInfo>)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)dropOperation {
#pragma unused(row)
	NSPasteboard *pasteBoard = [info draggingPasteboard];
	if ([[pasteBoard types] containsObject:UKKeyboardPasteType]) {
		if ([info draggingSource] != tableView && dropOperation == NSTableViewDropAbove) {
				// Dragging into a different document
			return YES;
		}
		return NO;
	}
	if ([[pasteBoard types] containsObject:NSURLPboardType]) {
		NSURL *dragURL = [NSURL URLFromPasteboard:pasteBoard];
		NSString *fileExtension = [dragURL pathExtension];
		BOOL isKeyboardLayout = [fileExtension compare:kStringKeyboardLayoutExtension options:NSCaseInsensitiveSearch] == NSEqualToComparison;
		BOOL isIconFile = [fileExtension compare:kStringIcnsExtension options:NSCaseInsensitiveSearch] == NSEqualToComparison;
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
	NSError *theError;
	KeyboardLayoutInformation *keyboardInfo;
	if ([[pasteBoard types] containsObject:UKKeyboardPasteType]) {
		if ([info draggingSource] != tableView && dropOperation == NSTableViewDropAbove) {
				// Dragging into another document
			UKKeyboardPasteboardItem *pasteBoardData = [[UKKeyboardPasteboardItem alloc] initWithPasteboardPropertyList:[pasteBoard propertyListForType:UKKeyboardPasteType] ofType:UKKeyboardPasteType];
			NSData *keyboardData = [NSData dataWithContentsOfURL:[pasteBoardData keyboardLayoutFile]];
			if (keyboardData == nil || [keyboardData length] == 0) {
					// Failed to read the document
				theError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorCouldNotCreateFromFile userInfo:nil];
				[NSApp presentError:theError];
				return NO;
			}
			UkeleleKeyboardObject *theKeyboard = [[UkeleleKeyboardObject alloc] initWithData:keyboardData withError:&theError];
				// Create a new keyboard ID for the copied keyboard
			[theKeyboard assignRandomID];
			if (theKeyboard == nil) {
					// Failed to read the document
				[NSApp presentError:theError];
				return NO;
			}
			NSString *keyboardName = [[[pasteBoardData keyboardLayoutFile] lastPathComponent] stringByDeletingPathExtension];
			keyboardInfo = [[KeyboardLayoutInformation alloc] initWithObject:theKeyboard fileName:keyboardName];
			[keyboardInfo setFileName:keyboardName];
			if ([pasteBoardData iconFile] != nil) {
					// Have an icon
				NSData *iconData = [NSData dataWithContentsOfURL:[pasteBoardData iconFile] options:0 error:&theError];
				if (iconData == nil || [iconData length] == 0) {
						// Failed to read the icon file
					[NSApp presentError:theError];
					return NO;
				}
				if (![UKFileUtilities dataIsicns:iconData]) {
					// Not a valid icon file
					return NO;
				}
				[keyboardInfo setIconData:iconData];
			}
			if ([pasteBoardData languageCode] != nil) {
					// Have an intended language
				[keyboardInfo setIntendedLanguage:[pasteBoardData languageCode]];
			}
			[self insertDocumentWithInfo:keyboardInfo];
			return YES;
		}
		return NO;
	}
	if ([[pasteBoard types] containsObject:(NSString *)kUTTypeFileURL]) {
		NSURL *dragURL = [NSURL URLFromPasteboard:pasteBoard];
		NSString *fileExtension = [dragURL pathExtension];
		BOOL isKeyboardLayout = [fileExtension compare:kStringKeyboardLayoutExtension options:NSCaseInsensitiveSearch] == NSEqualToComparison;
		BOOL isIconFile = [fileExtension compare:kStringIcnsExtension options:NSCaseInsensitiveSearch] == NSEqualToComparison;
		if (isKeyboardLayout) {
				// Dropping a keyboard layout file
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
			NSString *fileName = [[dragURL lastPathComponent] stringByDeletingPathExtension];
			keyboardInfo = [[KeyboardLayoutInformation alloc] initWithObject:keyboardObject fileName:fileName];
			[self insertDocumentWithInfo:keyboardInfo];
			return YES;
		}
		else if (isIconFile && dropOperation == NSTableViewDropOn) {
				// Dropping an icon file
			NSError *readError;
			NSFileWrapper *iconFile = [[NSFileWrapper alloc] initWithURL:dragURL options:NSFileWrapperReadingImmediate error:&readError];
			NSData *iconData = [iconFile regularFileContents];
			if (![UKFileUtilities dataIsicns:iconData]) {
				// Not valid icon data
				return NO;
			}
			KeyboardLayoutInformation *keyboardEntry = self.keyboardLayouts[row];
			if ([keyboardEntry hasIcon]) {
					// Replace an existing icon file
				[self replaceIconForKeyboardInfo:keyboardEntry withIcon:iconData];
			}
			else {
					// No existing icon file
				[self addIcon:iconData toKeyboardInfo:keyboardEntry];
			}
			return YES;
		}
	}
	return NO;
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
#pragma unused(tableView)
	if ([rowIndexes count] != 1) {
		return NO;
	}
		// Have exactly one row
	NSUInteger selectedRow = [rowIndexes firstIndex];
	NSAssert(selectedRow != NSNotFound, @"Must have an index");
	KeyboardLayoutInformation *layoutInfo = self.keyboardLayouts[selectedRow];
	NSURL *baseURL = [self.fileURL URLByAppendingPathComponent:kStringContentsName isDirectory:YES];
	baseURL = [baseURL URLByAppendingPathComponent:kStringResourcesName isDirectory:YES];
	NSURL *keyboardURL = [[baseURL URLByAppendingPathComponent:[layoutInfo fileName]] URLByAppendingPathExtension:kStringKeyboardLayoutExtension];
	NSURL *iconURL = nil;
	if ([layoutInfo hasIcon]) {
		iconURL = [[baseURL URLByAppendingPathComponent:[layoutInfo fileName]] URLByAppendingPathExtension:kStringIcnsExtension];
	}
	NSString *languageCode = [layoutInfo intendedLanguage];
	UKKeyboardPasteboardItem *pasteboardData = [UKKeyboardPasteboardItem pasteboardTypeForKeyboard:keyboardURL icon:iconURL language:languageCode];
	[pboard clearContents];
	[pboard writeObjects:@[pasteboardData]];
	return YES;
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
	NSInteger selectedRowNumber;
	KeyboardLayoutInformation *keyboardEntry;
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
		if (![self isBundle]) {
			return NO;
		}
		if ([[[self.tabView selectedTabViewItem] identifier] isEqualToString:kLocalisationsTab]) {
			return NO;
		}
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
	else if (theAction == @selector(chooseIntendedLanguage:) || theAction == @selector(attachIconFile:) ||
			 theAction == @selector(askKeyboardIdentifiers:) || theAction == @selector(removeKeyboardLayout:) ||
			 theAction == @selector(openKeyboardLayout:) || theAction == @selector(duplicateKeyboardLayout:) ||
			 theAction == @selector(localiseKeyboardName:)) {
			// Only active if there's a selection in the table
		if ([[[self.tabView selectedTabViewItem] identifier] isEqualToString:kLocalisationsTab]) {
			return NO;
		}
		if (![self isBundle]) {
			return NO;
		}
		selectedRowNumber = [self.keyboardLayoutsTable clickedRow];
		if (selectedRowNumber == -1) {
			selectedRowNumber = [self.keyboardLayoutsTable selectedRow];
		}
		return (selectedRowNumber != -1);
	}
	else if (theAction == @selector(removeIcon:)) {
			// Only active if there's a selection in the table, and the selected item has an icon
		if (![self isBundle]) {
			return NO;
		}
		if ([[[self.tabView selectedTabViewItem] identifier] isEqualToString:kLocalisationsTab]) {
			return NO;
		}
		selectedRowNumber = [self.keyboardLayoutsTable clickedRow];
		if (selectedRowNumber == -1) {
			selectedRowNumber = [self.keyboardLayoutsTable selectedRow];
		}
		if (selectedRowNumber != -1 && self.keyboardLayouts.count > 0) {
				// Have a selected row. Does it have an icon?
			keyboardEntry = [self.keyboardLayoutsController arrangedObjects][selectedRowNumber];
			if ([keyboardEntry iconData] != nil) {
				return YES;
			}
		}
		return NO;
	}
	else if (theAction == @selector(removeIntendedLanguage:)) {
			// Only active if there's a selection in the table, and the selected item has an intended language
		if (![self isBundle]) {
			return NO;
		}
		if ([[[self.tabView selectedTabViewItem] identifier] isEqualToString:kLocalisationsTab]) {
			return NO;
		}
		selectedRowNumber = [self.keyboardLayoutsTable clickedRow];
		if (selectedRowNumber == -1) {
			selectedRowNumber = [self.keyboardLayoutsTable selectedRow];
		}
		if (selectedRowNumber != -1 && self.keyboardLayouts.count > 0) {
				// Have a selected row. Does it have an intended language?
			keyboardEntry = [self.keyboardLayoutsController arrangedObjects][selectedRowNumber];
			if ([keyboardEntry intendedLanguage] != nil && ![[keyboardEntry intendedLanguage] isEqualToString:@""]) {
				return YES;
			}
		}
		return NO;
	}
	else if (theAction == @selector(editLocale:)) {
			// Only active if the current tab is localisations and there is a selected row
		if (![self isBundle]) {
			return NO;
		}
		if ([[[self.tabView selectedTabViewItem] identifier] isEqualToString:kKeyboardLayoutsTab]) {
			return NO;
		}
		selectedRowNumber = [self.keyboardLayoutsTable clickedRow];
		if (selectedRowNumber == -1) {
			selectedRowNumber = [self.keyboardLayoutsTable selectedRow];
		}
		return selectedRowNumber != -1 && [self.localisations count] > 0;
	}
	else if (theAction == @selector(removeLocale:)) {
			// Only active if the current tab is localisations and there is a selected row which is not the last one
		if (![self isBundle]) {
			return NO;
		}
		if ([[[self.tabView selectedTabViewItem] identifier] isEqualToString:kKeyboardLayoutsTab]) {
			return NO;
		}
		if ([self.localisations count] == 1) {
			return NO;
		}
		selectedRowNumber = [self.keyboardLayoutsTable clickedRow];
		if (selectedRowNumber == -1) {
			selectedRowNumber = [self.keyboardLayoutsTable selectedRow];
		}
		return selectedRowNumber != -1 && [self.localisations count] > 0;
	}
	else if (theAction == @selector(addLocale:)) {
			// Only active if the current tab is the localisations tab
		if (![self isBundle]) {
			return NO;
		}
		if ([[[self.tabView selectedTabViewItem] identifier] isEqualToString:kKeyboardLayoutsTab]) {
			return NO;
		}
		return YES;
	}
	else if (theAction == @selector(exportKeyboardLayout:)) {
		// These are always active
		return YES;
	}
	return [super validateUserInterfaceItem:anItem];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
#pragma unused(tabView)
	NSAssert(tabView == self.tabView, @"Should only get notifications from our tab view");
	if ([kLocalisationsTab isEqualToString:[tabViewItem identifier]]) {
			// Set the availability of the remove button
		[self.removeLocaleButton setEnabled:[self removeLocaleButtonShouldBeEnabled]];
	}
}

- (BOOL)removeLocaleButtonShouldBeEnabled {
	return [self.localisationsTable selectedRow] >= 0 && [self.localisations count] > 1;
}

#pragma mark User actions

	// Add a current keyboard layout window

- (IBAction)addOpenDocument:(id)sender {
#pragma unused(sender)
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
#pragma unused(sender)
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
#pragma unused(sender)
		// Run a dialog to define a keyboard layout
	[self setTableSelectionForMenu];
	__block UKNewKeyboardLayoutController *theController = [UKNewKeyboardLayoutController createController];
	NSArray *windowControllers = [self windowControllers];
	NSAssert([windowControllers count] > 0, @"Must be at least one window controller");
	NSWindowController *windowController = windowControllers[0];
	NSWindow *myWindow = [windowController window];
	[theController runDialog:myWindow withCompletion:^(NSString *keyboardName, NSUInteger baseLayout, NSUInteger commandLayout, NSUInteger capsLockLayout) {
		[self addNewKeyboardLayoutWithName:keyboardName base:baseLayout command:commandLayout capsLock:capsLockLayout];
		theController = nil;
	}];
}

- (void)addNewKeyboardLayoutWithName:(NSString *)keyboardName base:(NSUInteger)baseLayout command:(NSUInteger)commandLayout capsLock:(NSUInteger)capsLockLayout {
		// Check whether we have a valid layout
	if (baseLayout != kStandardLayoutNone) {
			// Create a keyboard with the given layout types
		NSAssert(commandLayout != kStandardLayoutNone, @"Must have a command layout specified");
		NSAssert(capsLockLayout != kStandardLayoutNone, @"Must have a caps lock layout specified");
		UkeleleKeyboardObject *keyboardObject = [[UkeleleKeyboardObject alloc] initWithName:keyboardName base:baseLayout command:commandLayout capsLock:capsLockLayout];
		[self addNewDocument:keyboardObject];
	}
}

	// Remove the selected keyboard layout from the bundle

- (IBAction)removeKeyboardLayout:(id)sender {
#pragma unused(sender)
	[self setTableSelectionForMenu];
	NSInteger selectedRowNumber = [self.keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	KeyboardLayoutInformation *selectedRowInfo = [self.keyboardLayoutsController arrangedObjects][selectedRowNumber];
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
#pragma unused(sender)
	[self setTableSelectionForMenu];
	NSInteger selectedRowNumber = [self.keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	KeyboardLayoutInformation *selectedRowInfo = [self.keyboardLayoutsController arrangedObjects][selectedRowNumber];
	UKKeyboardController *keyboardController = [selectedRowInfo keyboardController];
	if (keyboardController == nil) {
		keyboardController = [self createControllerForEntry:selectedRowInfo];
		if (keyboardController == nil) {
				// Bad keyboard layout, so bail
			return;
		}
	}
	NSAssert(keyboardController, @"Keyboard controller must exist");
	[keyboardController showWindow:self];
}

	// Choose the intended language of the selected keyboard layout

- (IBAction)chooseIntendedLanguage:(id)sender {
#pragma unused(sender)
	[self setTableSelectionForMenu];
	NSInteger selectedRowNumber = [self.keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	if (intendedLanguageSheet == nil) {
		intendedLanguageSheet = [IntendedLanguageSheet intendedLanguageSheet];
	}
	__block KeyboardLayoutInformation *keyboardEntry = [self.keyboardLayoutsController arrangedObjects][selectedRowNumber];
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
													 [self replaceIntendedLanguageForKeyboardInfo:keyboardEntry withLanguage:newLanguage];
												 }
											 }];
}

- (IBAction)removeIntendedLanguage:(id)sender {
#pragma unused(sender)
	[self setTableSelectionForMenu];
	NSInteger selectedRowNumber = [self.keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	KeyboardLayoutInformation *keyboardEntry = [self.keyboardLayoutsController arrangedObjects][selectedRowNumber];
		// Create an empty language code
	LanguageCode *emptyLanguage = [[LanguageCode alloc] init];
	[self replaceIntendedLanguageForKeyboardInfo:keyboardEntry withLanguage:emptyLanguage];
}

	// Create a new keyboard layout from the current keyboard input source

- (IBAction)captureInputSource:(id)sender {
#pragma unused(sender)
	NSError *createError = nil;
	UkeleleKeyboardObject *newKeyboard = [self keyboardFromCurrentInputSourceWithError:&createError];
	if (newKeyboard == nil) {
			// Failed to create it
		[NSApp presentError:createError];
		return;
	}
		// Create a new name for the keyboard layout
	NSString *newName = [self nameForCopyOf:[newKeyboard keyboardName]];
	[newKeyboard setKeyboardName:newName];
		// Get a new ID for the keyboard layout
	[newKeyboard assignRandomID];
		// Look for an icon
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
			// Create a folder to store the various icon files
			NSString *folderName = [NSString stringWithFormat:@"%@.iconset", newName];
			NSFileManager *fileManager = [NSFileManager defaultManager];
			NSString *tempDirectoryPath = NSTemporaryDirectory();
			NSURL *tempDirectory = [NSURL fileURLWithPath:tempDirectoryPath];
			NSURL *iconFolder = [tempDirectory URLByAppendingPathComponent:folderName isDirectory:YES];
			[fileManager createDirectoryAtURL:iconFolder withIntermediateDirectories:YES attributes:nil error:nil];
			// Create the icon files
			for (NSImageRep *iconImageRep in iconImageReps) {
				NSInteger imageHeight = (NSInteger)[iconImageRep size].height;
				NSInteger pixelHeight = [iconImageRep pixelsHigh];
				NSString *nameTemplate;
				if (imageHeight == pixelHeight) {
					nameTemplate = @"icon_%ldx%ld.png";
				}
				else {
					nameTemplate = @"icon_%ldx%ld@2x.png";
				}
				NSString *fileName = [NSString stringWithFormat:nameTemplate, imageHeight, imageHeight];
				NSURL *fileURL = [iconFolder URLByAppendingPathComponent:fileName];
				if (![fileManager fileExistsAtPath:[fileURL path]]) {
					CGImageDestinationRef destination = CGImageDestinationCreateWithURL((CFURLRef)fileURL, kUTTypePNG, 1, nil);
					NSRect imageRect = NSMakeRect(0, 0, imageHeight, imageHeight);
					CGImageRef imageRef = [iconImageRep CGImageForProposedRect:&imageRect context:nil hints:nil];
					CGImageDestinationAddImage(destination, imageRef, nil);
					CGImageDestinationFinalize(destination);
				}
			}
				// Get the conversion tool
//			NSURL *toolURL = [[NSBundle mainBundle] URLForAuxiliaryExecutable:UKIconutilTool];
			NSURL *toolURL = [NSURL fileURLWithPath:@"/usr/bin/iconutil"];
				// Set up and run the tool
			NSString *currentDirectory = [fileManager currentDirectoryPath];
			[fileManager changeCurrentDirectoryPath:[tempDirectory path]];
			NSTask *conversionTask = [NSTask launchedTaskWithLaunchPath:[toolURL path] arguments:@[@"-c", @"icns", folderName]];
			[conversionTask waitUntilExit];
			int returnStatus = [conversionTask terminationStatus];
#pragma unused(returnStatus)
			NSAssert(returnStatus == 0 || returnStatus == EINTR, @"Could not run conversion tool");
			[fileManager removeItemAtURL:iconFolder error:nil];
			[fileManager changeCurrentDirectoryPath:currentDirectory];
				// Finally, read the resulting file
			NSURL *icnsFileURL = [tempDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.icns", newName]];
			iconData = [NSMutableData dataWithContentsOfURL:icnsFileURL];
			[fileManager removeItemAtURL:icnsFileURL error:nil];
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
#pragma unused(sender)
	__weak NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		// These next four lines aren't necessary, it seems, but better to be safe...
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel setResolvesAliases:YES];
	[openPanel setAllowedFileTypes:@[kFileTypeKeyboardLayout]];
	NSWindow *docWindow = [self.keyboardLayoutsTable window];
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
					// Give it a new ID
				[keyboardLayout assignRandomID];
				[self addNewDocument:keyboardLayout];
					// Autosave the document after adding the new keyboard layout
				[self autosaveWithImplicitCancellability:YES completionHandler:^(NSError *errorOrNil) {
					if (errorOrNil) {
						[self presentError:errorOrNil];
					}
				}];
			}
		}
	}];
}

	// Attach an icon file to a keyboard layout

- (IBAction)attachIconFile:(id)sender {
#pragma unused(sender)
	[self setTableSelectionForMenu];
	__block NSInteger selectedRowNumber = [self.keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	__weak NSOpenPanel *openPanel = [NSOpenPanel openPanel];
		// These next four lines aren't necessary, it seems, but better to be safe...
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel setResolvesAliases:YES];
	[openPanel setAllowedFileTypes:@[(NSString *)kUTTypeAppleICNS]];
	NSWindow *docWindow = [self.keyboardLayoutsTable window];
	[openPanel beginSheetModalForWindow:docWindow completionHandler:^(NSModalResponse response) {
		if (response == NSModalResponseOK) {
				// User selected a file
			NSArray *selectedFiles = [openPanel URLs];
			NSURL *selectedFile = selectedFiles[0];	// Only one file
			NSData *iconData = [NSData dataWithContentsOfURL:selectedFile];
			if ([UKFileUtilities dataIsicns:iconData]) {
				KeyboardLayoutInformation *keyboardInfo = [self.keyboardLayoutsController arrangedObjects][selectedRowNumber];
				[self addIconData:iconData forKeyboard:[keyboardInfo keyboardObject]];
			}
		}
	}];
}

- (IBAction)removeIcon:(id)sender {
#pragma unused(sender)
	[self setTableSelectionForMenu];
	NSInteger selectedRowNumber = [self.keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	KeyboardLayoutInformation *keyboardInfo = [self.keyboardLayoutsController arrangedObjects][selectedRowNumber];
	[self removeIconFromKeyboardInfo:keyboardInfo];
}

	// Set the keyboard's name, script and/or id
- (IBAction)askKeyboardIdentifiers:(id)sender {
#pragma unused(sender)
	[self setTableSelectionForMenu];
	NSInteger selectedRowNumber = [self.keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	KeyboardLayoutInformation *keyboardEntry = [self.keyboardLayoutsController arrangedObjects][selectedRowNumber];
	UKKeyboardController *keyboardController = [keyboardEntry keyboardController];
	if (keyboardController == nil) {
			// Create the controller
		keyboardController = [self createControllerForEntry:keyboardEntry];
	}
	NSAssert(keyboardController, @"Keyboard controller must exist");
	NSWindow *docWindow = [self.keyboardLayoutsTable window];
	NSAssert(docWindow, @"Must have a document window");
	[keyboardController askKeyboardIdentifiers:docWindow];
}

	// Add and remove locales for this collection
- (IBAction)addLocale:(id)sender {
#pragma unused(sender)
	if (localeController == nil) {
		localeController = [LocaleDialogController localeDialog];
	}
	NSWindow *docWindow = [self.localisationsTable window];
	NSAssert(docWindow, @"Must have a document window");
	[localeController beginLocaleDialog:[[LocaleCode alloc] init] forWindow:docWindow callBack:^BOOL(LocaleCode *theLocale) {
		if (theLocale == nil) {
				// User cancelled
			return YES;
		}
		for (NSInteger rowNumber = 0; rowNumber < (NSInteger)[self.localisations count]; rowNumber++) {
			// Check whether we already have this locale
			if ([[[self.localisationsController arrangedObjects][rowNumber] localeCode] isEqualTo:theLocale]) {
				return NO;
			}
		}
			// We have a valid new locale
		[self addNewLocale:theLocale];
		return YES;
	}];
}

- (IBAction)removeLocale:(id)sender {
#pragma unused(sender)
	NSInteger selectedRowNumber = [self.localisationsTable clickedRow];
	if (selectedRowNumber == -1) {
		selectedRowNumber = [self.localisationsTable selectedRow];
	}
	NSAssert(selectedRowNumber != -1, @"Must have a selected row");
	LocalisationData *localeData = [self.localisationsController arrangedObjects][selectedRowNumber];
	[self removeLocaleWithData:localeData];
}

	// Edit a locale
- (IBAction)editLocale:(id)sender {
#pragma unused(sender)
	if (localeController == nil) {
		localeController = [LocaleDialogController localeDialog];
	}
	NSInteger selectedRowNumber = [self.localisationsTable clickedRow];
	if (selectedRowNumber == -1) {
		selectedRowNumber = [self.localisationsTable selectedRow];
	}
	if (selectedRowNumber == -1) {
			// No selected row, so do nothing
		return;
	}
	__block LocaleCode *currentLocale = [[self.localisationsController arrangedObjects][selectedRowNumber] localeCode];
	NSWindow *docWindow = [self.localisationsTable window];
	NSAssert(docWindow, @"Must have a document window");
	[localeController beginLocaleDialog:currentLocale forWindow:docWindow callBack:^BOOL(LocaleCode *theLocale) {
		if (theLocale == nil) {
				// User cancelled
			return YES;
		}
		for (NSInteger rowNumber = 0; rowNumber < (NSInteger)[self.localisations count]; rowNumber++) {
				// Check whether we already have this locale
			if (rowNumber != selectedRowNumber) {
				if ([[[self.localisationsController arrangedObjects][rowNumber] localeCode] isEqualTo:theLocale]) {
					return NO;
				}
			}
		}
			// We have a valid new locale
		LocalisationData *localeData = [self.localisationsController arrangedObjects][selectedRowNumber];
		[self replaceLocaleForLocalisation:localeData withLocale:theLocale];
		return YES;
	}];
}

	// Localise the keyboard's name
- (IBAction)localiseKeyboardName:(id)sender {
#pragma unused(sender)
	__block LocaliseKeyboardController *theController = [LocaliseKeyboardController localiseKeyboardController];
	NSInteger selectedRowNumber = [self.keyboardLayoutsTable clickedRow];
	if (selectedRowNumber == -1) {
		selectedRowNumber = [self.keyboardLayoutsTable selectedRow];
	}
	NSAssert(selectedRowNumber != -1, @"Must have a selected row");
	NSWindow *docWindow = [self.keyboardLayoutsTable window];
	NSAssert(docWindow, @"Must have a document window");
	KeyboardLayoutInformation *layoutInfo = self.keyboardLayouts[selectedRowNumber];
	[theController beginDialogWithWindow:docWindow forLocalisations:layoutInfo.localisedNames withCallback:^(NSDictionary *theDict) {
		if (theDict != nil) {
				// Got a valid dictionary
			[self changeLocalisedNames:theDict atIndex:selectedRowNumber];
		}
		theController = nil;
	}];
}


- (IBAction)duplicateKeyboardLayout:(id)sender {
#pragma unused(sender)
	[self setTableSelectionForMenu];
	NSInteger selectedRowNumber = [self.keyboardLayoutsTable selectedRow];
	if (selectedRowNumber < 0) {
		return;
	}
	KeyboardLayoutInformation *selectedRowInfo = [self.keyboardLayoutsController arrangedObjects][selectedRowNumber];
	UkeleleKeyboardObject *keyboardObject = [selectedRowInfo keyboardObject];
	if (keyboardObject == nil) {
			// Not loaded, so do so
		NSError *readError;
		NSFileWrapper *fileWrapper = [selectedRowInfo keyboardFileWrapper];
		NSData *fileData = [fileWrapper regularFileContents];
		keyboardObject = [[UkeleleKeyboardObject alloc] initWithData:fileData withError:&readError];
		if (keyboardObject == nil) {
				// Couldn't read the file
			[self presentError:readError];
			return;
		}
		[selectedRowInfo setKeyboardObject:keyboardObject];
		[selectedRowInfo setKeyboardName:[keyboardObject keyboardName]];
	}
		// Create a copy with a new ID
	UkeleleKeyboardObject *newKeyboardObject = [keyboardObject copy];
	NSString *keyboardName = [newKeyboardObject keyboardName];
	NSString *newName = [self nameForCopyOf:keyboardName];
	[newKeyboardObject setKeyboardName:newName];
	[newKeyboardObject assignRandomID];
	[self addNewDocument:newKeyboardObject];
}

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError *__autoreleasing *)outError {
#pragma unused(printSettings)
#pragma unused(outError)
	UKDocumentPrintViewController *printViewController = [UKDocumentPrintViewController documentPrintViewController];
	NSAssert(printViewController, @"Must have a print view controller");
	[printViewController setCurrentDocument:self];
	return [NSPrintOperation printOperationWithView:[printViewController view]];
}

- (IBAction)exportKeyboardLayout:(id)sender {
#pragma unused(sender)
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	[savePanel setAllowedFileTypes:@[(NSString *)kUTTypeDiskImage]];
	[savePanel setAllowsOtherFileTypes:NO];
	NSString *documentName;
	if (self.isBundle) {
		documentName = self.bundleName;
	}
	else {
		documentName = [self.keyboardLayout keyboardName];
	}
	[savePanel setNameFieldStringValue:documentName];
	NSArray *windowControllers = [self windowControllers];
	NSWindowController *windowController = windowControllers[0];
	NSWindow *myWindow = [windowController window];
	[savePanel beginSheetModalForWindow:myWindow completionHandler:^(NSInteger result) {
		if (result == NSFileHandlingPanelOKButton) {
				// Save it
			NSURL *saveURL = [savePanel URL];
			[savePanel orderOut:nil];
			[self exportInstallerTo:saveURL];
		}
	}];
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
		// Make sure that we know that we have a dirty subdocument
	[self updateChangeCount:NSChangeDone];
}

- (void)notifyNewName:(NSString *)newName forDocument:(id)keyboardDocument withOldName:(NSString *)oldName {
#pragma unused(newName)
#pragma unused(oldName)
	NSAssert([keyboardDocument isKindOfClass:[UKKeyboardController class]], @"Document must be a Ukelele document");
		// Find the document in the list
	for (KeyboardLayoutInformation *keyboardInfo in self.keyboardLayouts) {
		if ([keyboardInfo keyboardController] == keyboardDocument) {
			[keyboardInfo setKeyboardName:[(UKKeyboardController *)keyboardDocument keyboardDisplayName]];
			break;
		}
	}
		// Change the localised names, too...
	[self updateLocalisationForKeyboard:keyboardDocument oldName:oldName newName:newName];
	[self keyboardLayoutDidChange:[(UKKeyboardController *)keyboardDocument keyboardLayout]];
		// Notify the list that it's been updated
	UKKeyboardController *selectedController = [self currentSelectedController];
	[self.keyboardLayoutsController rearrangeObjects];
	[self.keyboardLayoutsTable reloadData];
	[self restoreSelectedController:selectedController];
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
	if ([[self.keyboardLayoutsTable selectedRowIndexes] count] == 1) {
			// We have a single selected keyboard layout
		UKKeyboardController *selectedWindow = [self controllerForCurrentEntry];
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
	if ([self.keyboardLayoutsTable selectedRow] == -1) {
		[inspectorController setCurrentKeyboard:NSNoSelectionMarker];
	}
	[self inspectorSetKeyboardSection];
}

- (void)windowDidBecomeMain:(NSNotification *)notification {
#pragma unused(notification)
	[self inspectorDidAppear];
}

- (void)windowDidResignMain:(NSNotification *)notification {
#pragma unused(notification)
	InspectorWindowController *inspectorController = [InspectorWindowController getInstance];
	[inspectorController setCurrentBundle:nil];
	[inspectorController unbind:@"currentDocument"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
#pragma unused(object)
#pragma unused(context)
	if ([keyPath isEqualToString:kKeyboardName]) {
			// Name change
		NSString *oldName = change[NSKeyValueChangeOldKey];
		NSString *newName = change[NSKeyValueChangeNewKey];
		if (![oldName isEqualToString:newName]) {
				// New name
			[[self controllerForCurrentEntry] changeKeyboardName:newName];
		}
	}
}

#pragma mark Callbacks

- (void)confirmDelete:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
#pragma unused(alert)
	if (returnCode == NSAlertAlternateReturn) {
			// User cancelled
		return;
	}
	NSInteger indexToDelete = [(__bridge NSNumber *)contextInfo integerValue];
	KeyboardLayoutInformation *keyboardInfo = [self.keyboardLayoutsController arrangedObjects][indexToDelete];
	[self removeDocumentWithInfo:keyboardInfo];
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
				// It already exists on disk, so make a copy with a new ID
			NSURL *documentURL = [chosenDocument fileURL];
			NSError *readError;
			UkeleleKeyboardObject *newKeyboard = [[UkeleleKeyboardObject alloc] initWithData:[NSData dataWithContentsOfURL:documentURL] withError:&readError];
			NSAssert(newKeyboard != nil, @"Copied keyboard should not create an error in reading");
			[newKeyboard assignRandomID];
			[self addNewDocument:newKeyboard];
		}
		else {
				// It hasn't been saved, so just copy it with a new ID
			UkeleleKeyboardObject *copiedKeyboard = [[chosenDocument keyboardLayout] copy];
			[copiedKeyboard assignRandomID];
			[self addNewDocument:copiedKeyboard];
		}
	}
	askFromListSheet = nil;
}

#pragma mark Localisations

- (NSMutableDictionary *)defaultLocalisations {
	NSMutableDictionary *theLocalisations = [NSMutableDictionary dictionary];
	for (KeyboardLayoutInformation *layoutInfo in self.keyboardLayouts) {
		NSString *keyboardName = [layoutInfo keyboardName];
		theLocalisations[keyboardName] = keyboardName;
	}
	return theLocalisations;
}

- (void)updateLocalisations {
	for (KeyboardLayoutInformation *layoutInfo in self.keyboardLayouts) {
			// Rebuild the dictionary of localised names
		NSMutableDictionary *layoutDict = [layoutInfo localisedNames];
		[layoutDict removeAllObjects];
		NSString *keyboardName = [layoutInfo keyboardName];
		for (LocalisationData *localeData in self.localisations) {
			NSString *localisedName = localeData.localisationStrings[keyboardName];
			if (localisedName == nil) {
				localisedName = keyboardName;
			}
			layoutDict[[localeData localeString]] = localisedName;
		}
	}
}

- (void)updateLocalisationForKeyboard:(UKKeyboardController *)keyboard oldName:(NSString *)oldName newName:(NSString *)newName {
	for (KeyboardLayoutInformation *layoutInfo in self.keyboardLayouts) {
		if ([layoutInfo keyboardController] == keyboard) {
				// Update the localisations for this keyboard
			for (LocalisationData *localeData in self.localisations) {
				NSString *localisedName = localeData.localisationStrings[oldName];
				if (localisedName != nil && [localisedName isEqualToString:oldName]) {
					localeData.localisationStrings[newName] = newName;
				}
				else {
					localeData.localisationStrings[newName] = localisedName;
				}
				[localeData.localisationStrings removeObjectForKey:oldName];
			}
			break;
		}
	}
	[self updateLocalisations];
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
	NSString *selectedName = [self currentSelectedName];
		// Create dictionary with appropriate information
	KeyboardLayoutInformation *keyboardInfo = [[KeyboardLayoutInformation alloc] initWithObject:newDocument fileName:nil];
	[self insertDocumentWithInfo:keyboardInfo];
	NSUndoManager *undoManager = [self undoManager];
	if (![undoManager isUndoing] && ![undoManager isRedoing]) {
		[undoManager setActionName:@"Add keyboard layout"];
	}
	[self.keyboardLayoutsTable reloadData];
	[self restoreSelectedName:selectedName];
}

- (void)removeDocumentWithInfo:(KeyboardLayoutInformation *)keyboardInfo {
	NSString *selectedName = [self currentSelectedName];
	NSUndoManager *undoManager = [self undoManager];
	if (![undoManager isUndoing] && ![undoManager isRedoing]) {
		[undoManager setActionName:@"Remove keyboard layout"];
	}
	[[undoManager prepareWithInvocationTarget:self] replaceDocumentWithInfo:keyboardInfo];
	[self.keyboardLayoutsController removeObject:keyboardInfo];
	[self.keyboardLayoutsTable deselectAll:self];
		// Notify the list that it's been updated
	[self.keyboardLayoutsTable reloadData];
	[self restoreSelectedName:selectedName];
		// Hide the document's windows, if they are shown
	UKKeyboardController *keyboardController = [keyboardInfo keyboardController];
	if (keyboardController != nil) {
		[keyboardController close];
	}
}

- (void)insertDocumentWithInfo:(KeyboardLayoutInformation *)keyboardInfo {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeDocumentWithInfo:keyboardInfo];
	if (![undoManager isUndoing] && ![undoManager isRedoing]) {
		[undoManager setActionName:@"Insert keyboard layout"];
	}
	[self.keyboardLayoutsController addObject:keyboardInfo];
	[self.keyboardLayoutsController rearrangeObjects];
	[self.keyboardLayoutsTable reloadData];
	NSUInteger newIndex = [[self.keyboardLayoutsController arrangedObjects] indexOfObject:keyboardInfo];
	NSAssert(newIndex != NSNotFound, @"Must be present after it has been added");
	[self.keyboardLayoutsTable scrollRowToVisible:newIndex];
}

- (void)replaceDocumentWithInfo:(KeyboardLayoutInformation *)keyboardInfo {
	NSString *selectedName = [self currentSelectedName];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeDocumentWithInfo:keyboardInfo];
	if (![undoManager isUndoing] && ![undoManager isRedoing]) {
		[undoManager setActionName:@"Insert keyboard layout"];
	}
	[self.keyboardLayoutsController addObject:keyboardInfo];
	[self.keyboardLayoutsController rearrangeObjects];
		// Notify the list that it's been updated
	[self.keyboardLayoutsTable reloadData];
	[self restoreSelectedName:selectedName];
}

- (void)addIcon:(NSData *)iconData toKeyboardInfo:(KeyboardLayoutInformation *)keyboardInfo {
	NSString *selectedName = [self currentSelectedName];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeIconFromKeyboardInfo:keyboardInfo];
	if (![undoManager isUndoing] && ![undoManager isRedoing]) {
		[undoManager setActionName:@"Add icon"];
	}
	[keyboardInfo setIconData:iconData];
		// Notify the list that it's been updated
	[self.keyboardLayoutsTable reloadData];
	[self restoreSelectedName:selectedName];
}

- (void)removeIconFromKeyboardInfo:(KeyboardLayoutInformation *)keyboardInfo {
	NSString *selectedName = [self currentSelectedName];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] addIcon:[keyboardInfo iconData] toKeyboardInfo:keyboardInfo];
	if (![undoManager isUndoing] && ![undoManager isRedoing]) {
		[undoManager setActionName:@"Remove icon"];
	}
	[keyboardInfo setIconData:nil];
		// Notify the list that it's been updated
	[self.keyboardLayoutsTable reloadData];
	[self restoreSelectedName:selectedName];
}

- (void)replaceIconForKeyboardInfo:(KeyboardLayoutInformation *)keyboardInfo withIcon:(NSData *)iconData {
	NSString *selectedName = [self currentSelectedName];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] replaceIconForKeyboardInfo:keyboardInfo withIcon:[keyboardInfo iconData]];
	[undoManager setActionName:@"Change icon"];
	[keyboardInfo setIconData:iconData];
		// Notify the list that it's been updated
	[self.keyboardLayoutsTable reloadData];
	[self restoreSelectedName:selectedName];
}

- (void)replaceIntendedLanguageForKeyboardInfo:(KeyboardLayoutInformation *)keyboardInfo withLanguage:(LanguageCode *)newLanguage {
	NSString *selectedName = [self currentSelectedName];
	LanguageCode *oldLanguage = [LanguageCode languageCodeFromString:[keyboardInfo intendedLanguage]];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] replaceIntendedLanguageForKeyboardInfo:keyboardInfo withLanguage:oldLanguage];
	[undoManager setActionName:@"Change intended language"];
	[keyboardInfo setIntendedLanguage:[newLanguage stringRepresentation]];
	[self.keyboardLayoutsController rearrangeObjects];
		// Notify the list that it's been updated
	[self.keyboardLayoutsTable reloadData];
	[self restoreSelectedName:selectedName];
}

- (void)addNewDocument:(UkeleleKeyboardObject *)newDocument withIcon:(NSData *)iconData withLanguage:(NSString *)intendedLanguage {
	NSUndoManager *undoManager = [self undoManager];
	[undoManager beginUndoGrouping];
	KeyboardLayoutInformation *keyboardInfo = [[KeyboardLayoutInformation alloc] initWithObject:newDocument fileName:nil];
	if (iconData != nil) {
		[keyboardInfo setIconData:iconData];
	}
	if (intendedLanguage != nil && [intendedLanguage length] > 0) {
		[keyboardInfo setIntendedLanguage:intendedLanguage];
	}
	[self insertDocumentWithInfo:keyboardInfo];
	[undoManager setActionName:@"Capture current input source"];
	[undoManager endUndoGrouping];
}

- (void)replaceLocaleForLocalisation:(LocalisationData *)localeData withLocale:(LocaleCode *)newLocale {
	LocaleCode *oldLocale = [localeData localeCode];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] replaceLocaleForLocalisation:localeData withLocale:oldLocale];
	[undoManager setActionName:@"Change locale"];
	[localeData setLocaleCode:newLocale];
	[self updateLocalisations];
	[self.localisationsController rearrangeObjects];
	[self.localisationsTable reloadData];
	[self.removeLocaleButton setEnabled:[self removeLocaleButtonShouldBeEnabled]];
}

- (void)addNewLocale:(LocaleCode *)newLocale {
	LocalisationData *newLocaleData = [[LocalisationData alloc] init];
	[newLocaleData setLocaleCode:newLocale];
	[newLocaleData setLocalisationStrings:[self defaultLocalisations]];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeLocaleWithData:newLocaleData];
	if (![undoManager isUndoing] && ![undoManager isRedoing]) {
		[undoManager setActionName:@"Add locale"];
	}
	[self.localisationsController addObject:newLocaleData];
	[self updateLocalisations];
	[self.localisationsController rearrangeObjects];
	[self.localisationsTable reloadData];
	[self.removeLocaleButton setEnabled:[self removeLocaleButtonShouldBeEnabled]];
}

- (void)insertLocale:(LocalisationData *)localisationData {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeLocaleWithData:localisationData];
	if (![undoManager isUndoing] && ![undoManager isRedoing]) {
		[undoManager setActionName:@"Add locale"];
	}
	[self.localisationsController addObject:localisationData];
	[self updateLocalisations];
	[self.localisationsController rearrangeObjects];
	[self.localisationsTable reloadData];
	[self.removeLocaleButton setEnabled:[self removeLocaleButtonShouldBeEnabled]];
}

- (void)removeLocaleWithData:(LocalisationData *)localisationData {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] insertLocale:localisationData];
	if (![undoManager isUndoing] && ![undoManager isRedoing]) {
		[undoManager setActionName:@"Replace locale"];
	}
	[self.localisationsController removeObject:localisationData];
	[self updateLocalisations];
	[self.localisationsTable reloadData];
	[self.removeLocaleButton setEnabled:[self removeLocaleButtonShouldBeEnabled]];
}

- (void)changeLocalisedNames:(NSDictionary *)localisedNames atIndex:(NSInteger)index {
	KeyboardLayoutInformation *layoutInfo = self.keyboardLayouts[index];
	NSString *keyboardName = [layoutInfo keyboardName];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] changeLocalisedNames:[[layoutInfo localisedNames] copy] atIndex:index];
	[undoManager setActionName:@"Edit localised names"];
	for (LocalisationData *localisationData	in self.localisations) {
		NSString *localeName = [localisationData localeString];
		NSString *localisedName = localisedNames[localeName];
		NSAssert(localisedName != nil, @"The localised name must exist");
		localisationData.localisationStrings[keyboardName] = localisedName;
	}
	[self updateLocalisations];
	[self.localisationsTable reloadData];
}

@end

//
//  UkeleleKeyboardInstaller.m
//  Ukelele 3
//
//  Created by John Brownie on 3/01/14.
//
//

#import "UkeleleKeyboardInstaller.h"
#import "UkeleleConstantStrings.h"
#import "UkeleleErrorCodes.h"
#import "UKAskYesNoController.h"
#import "UkeleleAppDelegate.h"
#import "KeyboardInstallerTool.h"

@implementation UkeleleKeyboardInstaller

- (instancetype)init {
	self = [super init];
	return self;
}

+ (UkeleleKeyboardInstaller *)defaultInstaller {
	static UkeleleKeyboardInstaller *theInstance = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		theInstance = [[UkeleleKeyboardInstaller alloc] init];
	});
	return theInstance;
}

- (BOOL)installForAllUsers:(NSURL *)sourceFile error:(NSError *__autoreleasing *)installError {
		// Does the Keyboard Layouts folder exist?
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *keyboardLayoutPath = @"/Library/Keyboard Layouts";
	NSURL *keyboardLayoutFolder = [NSURL fileURLWithPath:keyboardLayoutPath isDirectory:YES];
	NSString *currentFile = [sourceFile lastPathComponent];
	NSURL *installedURL = [keyboardLayoutFolder URLByAppendingPathComponent:currentFile isDirectory:NO];
	NSError *localError;
	NSDictionary *localErrorDict;
	BOOL isDirectory;
	if ([fileManager fileExistsAtPath:keyboardLayoutPath isDirectory:&isDirectory]) {
		if (!isDirectory) {
				// A plain file exists at this location!
			localErrorDict = @{NSLocalizedFailureReasonErrorKey: @"Cannot create the Keyboard Layouts folder because a file with that name already exists in the Library folder",
					  NSLocalizedDescriptionKey: @"Could not install the keyboard layout because there is a file called Keyboard Layouts in the Library folder"};
			localError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorKeyboardLayoutsFileExists userInfo:localErrorDict];
			if (installError != NULL) {
				*installError = localError;
			}
			return NO;
		}
	}
	if ([fileManager fileExistsAtPath:[installedURL path]]) {
			// The file currently exists
		__block UKAskYesNoController *theController = [UKAskYesNoController askYesNoController];
		[theController askQuestion:@"There is already a keyboard layout with this name installed. Do you wish to replace it?" forWindow:nil completion:^void(BOOL response) {
			if (response) {
				[self authenticatedInstallFromURL:sourceFile toURL:installedURL error:installError];
			}
			theController = nil;
		}];
		return YES;
	}
	return [self authenticatedInstallFromURL:sourceFile toURL:installedURL error:installError];
}

- (BOOL)installForCurrentUser:(NSURL *)sourceFile error:(NSError *__autoreleasing *)installError {
		// Does the Keyboard Layouts folder exist?
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *keyboardLayoutPath = [@"~/Library/Keyboard Layouts" stringByExpandingTildeInPath];
	NSError *localError;
	NSDictionary *localErrorDict;
	BOOL isDirectory;
	if ([fileManager fileExistsAtPath:keyboardLayoutPath isDirectory:&isDirectory]) {
		if (!isDirectory) {
				// A plain file exists at this location!
			localErrorDict = @{NSLocalizedFailureReasonErrorKey: @"Cannot create the Keyboard Layouts folder because a file with that name already exists in the Library folder",
					  NSLocalizedDescriptionKey: @"Could not install the keyboard layout because there is a file called Keyboard Layouts in the Library folder"};
			localError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorKeyboardLayoutsFileExists userInfo:localErrorDict];
			if (installError != NULL) {
				*installError = localError;
			}
			return NO;
		}
	}
	else {
			// Create the folder
		NSError *theError;
		BOOL createdFolder = [fileManager createDirectoryAtPath:keyboardLayoutPath withIntermediateDirectories:YES attributes:nil error:&theError];
		if (!createdFolder) {
				// Couldn't create the folder
			localErrorDict = @{NSLocalizedDescriptionKey: @"Cannot create the Keyboard Layouts folder"};
			localError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorCouldNotCreateKeyboardLayouts userInfo:localErrorDict];
			if (installError) {
				*installError = localError;
			}
			return NO;
		}
	}
	NSURL *keyboardLayoutFolder = [NSURL fileURLWithPath:keyboardLayoutPath isDirectory:YES];
	NSString *currentFile = [sourceFile lastPathComponent];
	NSURL *installedURL = [keyboardLayoutFolder URLByAppendingPathComponent:currentFile isDirectory:NO];
	if ([fileManager fileExistsAtPath:[installedURL path]]) {
			// File already exists. Overwrite?
		__block UKAskYesNoController *theController = [UKAskYesNoController askYesNoController];
		[theController askQuestion:@"There is already a keyboard layout with this name installed. Do you wish to replace it?" forWindow:nil completion:^void(BOOL response) {
			if (response) {
				[self installFromURL:sourceFile toURL:installedURL error:installError];
			}
			theController = nil;
		}];
		return YES;
	}
	return [self installFromURL:sourceFile toURL:installedURL error:installError];
}

- (BOOL)installFromURL:(NSURL *)sourceURL toURL:(NSURL *)targetURL error:(NSError **)installError {
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSError *copyError;
	BOOL createdOK = [fileManager copyItemAtURL:sourceURL toURL:targetURL error:&copyError];
	if (!createdOK) {
			// Failed to save
		if ([[copyError domain] isEqualToString:NSCocoaErrorDomain] && [copyError code] == NSFileWriteNoPermissionError) {
				// No permission, so try to authenticate
			createdOK = [self authenticatedInstallFromURL:sourceURL toURL:targetURL error:&copyError];
		}
	}
	if (!createdOK) {
		NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"Could not install the keyboard layout",
									NSUnderlyingErrorKey: copyError};
		NSError *error = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorCouldNotSaveInInstallDirectory userInfo:errorDictionary];
		if (installError) {
			*installError = error;
		}
	}
	return createdOK;
}

- (BOOL)authenticatedInstallFromURL:(NSURL *)sourceURL toURL:(NSURL *)targetURL error:(NSError **)installError {
#pragma unused(targetURL)
		// Call the helper tool
	UkeleleAppDelegate *appDelegate = (UkeleleAppDelegate *)[[NSApplication sharedApplication] delegate];
	BOOL helperInstalled = [appDelegate helperToolIsInstalled];
	if (!helperInstalled) {
		helperInstalled = [appDelegate installHelperTool];
	}
	if (helperInstalled) {
		[appDelegate connectAndExecuteCommandBlock:^(NSError *outerError) {
#pragma unused(outerError)
			NSXPCConnection *connection = [appDelegate helperToolConnection];
			id proxy =[connection remoteObjectProxyWithErrorHandler:^(NSError *error) {
				[[NSApplication sharedApplication] performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:YES];
				return;
			}];
			NSData *authorization = [appDelegate authorization];
			[proxy installFile:sourceURL authorization:authorization withReply:^(NSError *error) {
				if (error) {
						// Failed to do the copy
					NSDictionary *errDict = @{NSLocalizedDescriptionKey: @"Could not install the keyboard layout into the Keyboard Layouts folder",
							   NSUnderlyingErrorKey: error};
					NSError *reportedError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorCouldNotSaveInInstallDirectory userInfo:errDict];
					[[NSOperationQueue mainQueue] addOperationWithBlock:^(void) {
						[NSApp presentError:reportedError];
					}];
				}
			}];
		}];
		return  YES;
	}
		// Helper tool failed to install
	NSDictionary *authErrorDict = @{NSLocalizedDescriptionKey: @"Helper tool not installed"};
	if (installError != NULL) {
		*installError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorAuthenticationFailed userInfo:authErrorDict];
	}
	return NO;
}

@end

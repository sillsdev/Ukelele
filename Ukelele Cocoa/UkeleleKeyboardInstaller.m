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
#import "AskYesNoController.h"
#import "UkeleleAppDelegate.h"
#import "KeyboardInstallerTool.h"

@implementation UkeleleKeyboardInstaller {
	AuthorizationRef authorizationRef;
}

- (id)init {
	self = [super init];
	if (self) {
		authorizationRef = nil;
	}
	return self;
}

- (void)dealloc {
	if (authorizationRef) {
			// Clean up
		AuthorizationFree(authorizationRef, kAuthorizationFlagDestroyRights);
	}
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
	NSError *localError;
	NSDictionary *localErrorDict;
	BOOL isDirectory;
	if ([fileManager fileExistsAtPath:keyboardLayoutPath isDirectory:&isDirectory]) {
		if (!isDirectory) {
				// A plain file exists at this location!
			localErrorDict = @{NSLocalizedFailureReasonErrorKey: @"Cannot create the Keyboard Layouts folder because a file with that name already exists in the Library folder",
					  NSLocalizedDescriptionKey: @"Could not install the keyboard layout because there is a file called Keyboard Layouts in the Library folder"};
			localError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorKeyboardLayoutsFileExists userInfo:localErrorDict];
			*installError = localError;
			return NO;
		}
	}
	else {
			// Create the folder
		[self authenticatedCreateDirectory:keyboardLayoutPath];
		if (![fileManager fileExistsAtPath:keyboardLayoutPath isDirectory:&isDirectory]) {
				// Couldn't create the folder
			localErrorDict = @{NSLocalizedDescriptionKey: @"Cannot create the Keyboard Layouts folder"};
			localError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorCouldNotCreateKeyboardLayouts userInfo:localErrorDict];
			*installError = localError;
			return NO;
		}
	}
	NSURL *keyboardLayoutFolder = [NSURL fileURLWithPath:keyboardLayoutPath isDirectory:YES];
	NSString *currentFile = [sourceFile lastPathComponent];
	NSURL *installedURL = [keyboardLayoutFolder URLByAppendingPathComponent:currentFile isDirectory:NO];
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
			*installError = localError;
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
			*installError = localError;
			return NO;
		}
	}
	NSURL *keyboardLayoutFolder = [NSURL fileURLWithPath:keyboardLayoutPath isDirectory:YES];
	NSString *currentFile = [sourceFile lastPathComponent];
	NSURL *installedURL = [keyboardLayoutFolder URLByAppendingPathComponent:currentFile isDirectory:NO];
	if ([fileManager fileExistsAtPath:[installedURL path]]) {
			// File already exists. Overwrite?
		__block AskYesNoController *theController = [AskYesNoController askYesNoController];
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
		*installError = error;
	}
	return createdOK;
}

- (void)authenticatedCreateDirectory:(NSString *)directoryPath {
	if (![self setupAuthorization]) {
		return;
	}
		// Create an external form to pass to the helper tool
	AuthorizationExternalForm myExternalAuthorizationRef;
	OSStatus theStatus = AuthorizationMakeExternalForm(authorizationRef, &myExternalAuthorizationRef);
	if (theStatus != errAuthorizationSuccess) {
		return;
	}
		// Call the helper tool
	UkeleleAppDelegate *appDelegate = [NSApp delegate];
	if ([appDelegate installHelperTool]) {
		[appDelegate connectAndExecuteCommandBlock:^(NSError *error) {
			[[[appDelegate helperToolConnection] remoteObjectProxyWithErrorHandler:^(NSError *error) {
				return;
			}] createFolder:[NSURL URLWithString:directoryPath] authorization:[appDelegate authorization] withReply:^(NSError *error) {
				if (error) {
						// Failed to create the directory
					NSDictionary *errDict = @{NSLocalizedDescriptionKey: @"Could not create the Keyboard Layouts folder",
							   NSUnderlyingErrorKey: error};
					NSError *reportedError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorCouldNotCreateKeyboardLayouts userInfo:errDict];
					[NSApp presentError:reportedError];
				}
			}];
		}];

	}
	else {
		NSDictionary *authErrorDict = @{NSLocalizedDescriptionKey: @"Helper tool not installed"};
		NSError *authenticationError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorAuthenticationFailed userInfo:authErrorDict];
		[NSApp presentError:authenticationError];
	}
}

- (BOOL)authenticatedInstallFromURL:(NSURL *)sourceURL toURL:(NSURL *)targetURL error:(NSError **)installError {
	if (![self setupAuthorization]) {
		NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"Could not get permission to install"};
		*installError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorCouldNotSaveInInstallDirectory userInfo:errorDictionary];
		return NO;
	}
		// Create an external form to pass to the helper tool
	AuthorizationExternalForm myExternalAuthorizationRef;
	OSStatus theStatus = AuthorizationMakeExternalForm(authorizationRef, &myExternalAuthorizationRef);
	if (theStatus != errAuthorizationSuccess) {
		NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"Could not get permission to install"};
		*installError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorCouldNotSaveInInstallDirectory userInfo:errorDictionary];
		return NO;
	}
		// Call the helper tool
	UkeleleAppDelegate *appDelegate = [NSApp delegate];
	if ([appDelegate installHelperTool]) {
		[appDelegate connectAndExecuteCommandBlock:^(NSError *error) {
			[[[appDelegate helperToolConnection] remoteObjectProxyWithErrorHandler:^(NSError *error) {
				return;
			}] copyFile:sourceURL toFile:targetURL authorization:[appDelegate authorization] withReply:^(NSError *error) {
				if (error) {
						// Failed to do the copy
					NSDictionary *errDict = @{NSLocalizedDescriptionKey: @"Could not install the keyboard layout into the Keyboard Layouts folder",
							   NSUnderlyingErrorKey: error};
					NSError *reportedError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorCouldNotSaveInInstallDirectory userInfo:errDict];
					[NSApp presentError:reportedError];
				}
			}];
		}];
		return  YES;
	}
		// Helper tool failed to install
	NSDictionary *authErrorDict = @{NSLocalizedDescriptionKey: @"Helper tool not installed"};
	*installError = [NSError errorWithDomain:kDomainUkelele code:kUkeleleErrorAuthenticationFailed userInfo:authErrorDict];
	return NO;
}

	// Returns YES if successful
- (BOOL)setupAuthorization {
	OSStatus theStatus;
		// Create the authorization reference
	if (authorizationRef == nil) {
		theStatus = AuthorizationCreate(nil, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &authorizationRef);
		if (theStatus != errAuthorizationSuccess) {
			return NO;
		}
	}
		// Build the authorization rights set
	AuthorizationItem myItems[1];
	myItems[0].name = "org.sil.ukelele.InstallKeyboardLayout";
	myItems[0].valueLength = 0;
	myItems[0].value = NULL;
	myItems[0].flags = 0;
	AuthorizationRights myRights;
	myRights.count = sizeof(myItems) / sizeof(myItems[0]);
	myRights.items = myItems;
		// Set the flags for preauthorization
	AuthorizationFlags myFlags;
	myFlags = kAuthorizationFlagDefaults | kAuthorizationFlagExtendRights | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize;
		// Do the authorization
	theStatus = AuthorizationCopyRights(authorizationRef, &myRights, kAuthorizationEmptyEnvironment, myFlags, nil);
	if (theStatus != errAuthorizationSuccess) {
		return NO;
	}
	return YES;
}

@end

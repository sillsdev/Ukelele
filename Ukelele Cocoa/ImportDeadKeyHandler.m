//
//  ImportDeadKeyHandler.m
//  Ukelele 3
//
//  Created by John Brownie on 4/10/13.
//
// Interaction handler for importing a dead key state
//	Sequence of events will be:
//		Bring up a choose file dialog to choose the source file
//		If the source file is a bundle with more than one keyboard layout,
//			put up a dialog to choose one document
//		Verify that the modifier maps are compatible
//		If there is more than one state, put up a dialog to choose the state
//		If there is a state with that name, ask for a new name

#import "ImportDeadKeyHandler.h"
#import "UKKeyboardDocument.h"
#import "UKKeyboardController.h"
#import "KeyboardLayoutInformation.h"
#import "AskFromList.h"
#import "UkeleleConstantStrings.h"
#import "AskTextSheet.h"
#import "AskImportState.h"

@implementation ImportDeadKeyHandler {
	NSWindow *parentWindow;
	UKKeyboardController *targetDocumentWindow;
}

- (instancetype)init {
	if (self = [super init]) {
		parentWindow = nil;
		targetDocumentWindow = nil;
		_completionTarget = nil;
	}
	return self;
}

+ (ImportDeadKeyHandler *)importDeadKeyHandler {
	return [[ImportDeadKeyHandler alloc] init];
}

- (void)beginInteractionForWindow:(UKKeyboardController *)theDocumentWindow {
	parentWindow = [theDocumentWindow window];
	targetDocumentWindow = theDocumentWindow;
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setMessage:@"Choose the keyboard layout containing the dead key you wish to import"];
	NSBundle *theBundle = [NSBundle mainBundle];
	NSArray *documentTypes = [theBundle objectForInfoDictionaryKey:@"CFBundleDocumentTypes"];
	NSMutableArray *documentUTIs = [NSMutableArray arrayWithCapacity:[documentTypes count]];
	for (NSDictionary *docType in documentTypes) {
		NSArray *docTypes = docType[@"LSItemContentTypes"];
		[documentUTIs addObjectsFromArray:docTypes];
	}
	[openPanel setAllowedFileTypes:documentUTIs];
	[openPanel beginSheetModalForWindow:parentWindow completionHandler:^(NSInteger result) {
		if (result == NSModalResponseOK) {
				// Got the file
			NSArray *panelURLs = [openPanel URLs];
			NSAssert([panelURLs count] == 1, @"Must have only one file");
			NSURL *documentURL = panelURLs[0];
			[openPanel orderOut:self];
			[self handleChoiceOfSourceFile:documentURL];
		}
	}];
}

- (void)handleChoiceOfSourceFile:(NSURL *)documentURL {
	NSError *theError;
	NSDictionary *documentProperties = [documentURL resourceValuesForKeys:@[NSURLIsRegularFileKey, NSURLIsPackageKey] error:&theError];
	if (documentProperties == nil) {
			// Couldn't get properties!
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"Could not get the properties of the chosen file"];
		[alert runModal];
		[self interactionCompleted];
		return;
	}
	if ([documentProperties[NSURLIsRegularFileKey] boolValue]) {
			// Regular file, should be a keyboard layout file
		[self handleDocumentWithURL:documentURL];
	}
	else if ([documentProperties[NSURLIsPackageKey] boolValue]) {
			// Package, so have to determine whether it's a valid keyboard layout bundle
		UKKeyboardDocument *theBundle = [self getKeyboardLayoutBundle:documentURL];
		if (theBundle != nil) {
				// Valid bundle
			[self handleBundle:theBundle];
		}
		else {
				// Not a valid bundle
			NSAlert *alert = [[NSAlert alloc] init];
			[alert setMessageText:@"The document chosen was not a keyboard layout bundle"];
			[alert runModal];
			[self interactionCompleted];
		}
	}
}

- (UKKeyboardDocument *)getKeyboardLayoutBundle:(NSURL *)bundleURL {
		// See if we can create a keyboard layout bundle from the URL
	UKKeyboardDocument *bundleDocument = [[UKKeyboardDocument alloc] init];
	NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL:bundleURL options:0 error:NULL];
	if (fileWrapper != nil) {
		NSError *readError;
		if ([bundleDocument readFromFileWrapper:fileWrapper ofType:(NSString *)kUTTypeBundle error:&readError]) {
				// It reads OK
			return bundleDocument;
		}
	}
	return nil;
}

- (void)handleBundle:(UKKeyboardDocument *)theDocument {
		// Find the keyboard layouts in the bundle
	NSArray *keyboardLayouts = [theDocument keyboardLayouts];
	if ([keyboardLayouts count] == 1) {
			// Only one keyboard layout, so that's the one to use
		KeyboardLayoutInformation *docInfo = keyboardLayouts[0];
		UKKeyboardController *keyboardWindow = [docInfo keyboardController];
		if (keyboardWindow == nil) {
			keyboardWindow = [[(UKKeyboardController *)[parentWindow windowController] parentDocument] createControllerForEntry:docInfo];
		}
		[self handleDocument:keyboardWindow];
	}
	else if ([keyboardLayouts count] > 1) {
			// Put up a dialog to ask which one to use
		NSMutableArray *keyboardNames = [NSMutableArray arrayWithCapacity:[keyboardLayouts count]];
		for (KeyboardLayoutInformation *keyboardInfo in keyboardLayouts) {
			[keyboardNames addObject:[keyboardInfo keyboardName]];
		}
		[keyboardNames sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
			return [(NSString *)obj1 compare:obj2];
		}];
		__block AskFromList *askFromList = [AskFromList askFromList];
		[askFromList beginAskFromListWithText:@"Choose the keyboard layout to open" withMenu:keyboardNames forWindow:parentWindow callBack:^(NSString *chosenKeyboard) {
			if (chosenKeyboard == nil) {
					// User cancelled
				[self interactionCompleted];
				askFromList = nil;
				return;
			}
			NSUInteger index = [keyboardLayouts indexOfObjectPassingTest:^BOOL(id _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
#pragma unused(idx)
				if ([(KeyboardLayoutInformation *)obj keyboardName] == chosenKeyboard) {
					*stop = YES;
					return YES;
				}
				return NO;
			}];
			NSAssert(index != NSNotFound, @"Must have found the keyboard name");
			KeyboardLayoutInformation *info = keyboardLayouts[index];
			UKKeyboardController *keyboardWindow = [info keyboardController];
			if (keyboardWindow == nil) {
				keyboardWindow = [[(UKKeyboardController *)[self->parentWindow windowController] parentDocument] createControllerForEntry:info];
			}
			[self handleDocument:keyboardWindow];
			askFromList = nil;
		}];
	}
	else {
			// No keyboard layouts
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"There are no keyboard layouts in this document"];
		[alert runModal];
		[self interactionCompleted];
	}
}

- (void)handleDocumentWithURL:(NSURL *)documentURL {
		// We have a URL which should be a valid keyboard layout
	NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL:documentURL options:0 error:NULL];
	UKKeyboardDocument *theDocument = [[UKKeyboardDocument alloc] init];
	NSError *theError;
	BOOL success = [theDocument readFromFileWrapper:fileWrapper ofType:kFileTypeKeyboardLayout error:&theError];
	if (!success) {
			// Couldn't create the document
		NSAlert *alert = [NSAlert alertWithError:theError];
		[alert runModal];
		[self interactionCompleted];
		return;
	}
	UKKeyboardController *keyboardWindow = [[UKKeyboardController alloc] initWithWindowNibName:@"UKKeyboardLayout"];
	[keyboardWindow setKeyboardLayout:[theDocument keyboardLayout]];
	[self handleDocument:keyboardWindow];
}

- (void)handleDocument:(UKKeyboardController *)theDocumentWindow {
		// Have the source document as a UKKeyboardController
		// Check that we have equivalent modifier maps
	UkeleleKeyboardObject *sourceObject = [theDocumentWindow keyboardLayout];
	UkeleleKeyboardObject *targetObject = [targetDocumentWindow keyboardLayout];
	if (![targetObject hasEquivalentModifierMap:sourceObject]) {
			// Not compatible
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"The two keyboard layouts have different modifier maps, so cannot import the dead key state"];
		[alert runModal];
		[self interactionCompleted];
		return;
	}
	NSArray *stateNames = [[theDocumentWindow keyboardLayout] stateNamesExcept:kStateNameNone];
	if ([stateNames count] == 0) {
			// No states to import
		NSAlert *alert = [[NSAlert alloc] init];
		[alert setMessageText:@"This keyboard layout has no dead key states"];
		[alert runModal];
		[self interactionCompleted];
		return;
	}
		// Bring up a dialog to choose the state name to import
	NSArray *targetStateList = [targetObject stateNamesExcept:@""];
	__block AskImportState *askImport = [AskImportState askImportState];
	[askImport setImportPrompt:@"Choose the dead key state to import"];
	[askImport setDestinationStatePrompt:@"Enter a name for the imported dead key state"];
	[askImport askImportFromState:stateNames
				  excludingStates:targetStateList
					   withWindow:parentWindow
				  completionBlock:^(NSString *importState, NSString *destinationState) {
		if (importState != nil) {
				// Have valid states
			[[self->targetDocumentWindow keyboardLayout] importDeadKeyState:importState
															  toState:destinationState
														 fromKeyboard:sourceObject];
		}
		[self interactionCompleted];
		askImport = nil;
	}];
}

- (void)importState:(NSString *)stateName fromDocument:(UKKeyboardController *)sourceDocumentWindow {
		// Ask for a name for the imported state
	NSArray *targetStateList = [[targetDocumentWindow keyboardLayout] stateNamesExcept:@""];
	NSMutableSet *targetStates = [NSMutableSet setWithArray:targetStateList];
	[targetStates addObject:@""];
	[targetStates addObject:kStateNameNone];
	__block AskTextSheet *askText = [AskTextSheet askTextSheet];
	[askText beginAskValidatedText:@"Enter a name for the imported dead key state" notFromSet:targetStates errorText:@"The state name must not be already present in this keyboard layout" initialText:@"" forWindow:parentWindow callBack:^(id result) {
		NSString *chosenState = result;
		if (chosenState != nil) {
				// Valid state supplied
			[[self->targetDocumentWindow keyboardLayout] importDeadKeyState:stateName
														toState:chosenState
												   fromKeyboard:[sourceDocumentWindow keyboardLayout]];
		}
		[self interactionCompleted];
		askText = nil;
	}];
}

- (void)interactionCompleted {
	[self.completionTarget interactionDidComplete:self];
}

- (void)handleMessage:(NSDictionary *)messageData {
#pragma unused(messageData)
		// No messages to handle
}

- (void)cancelInteraction {
		// User cancelled
	[self interactionCompleted];
}

@end

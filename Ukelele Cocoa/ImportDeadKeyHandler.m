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
#import "KeyboardLayoutBundle.h"
#import "KeyboardLayoutInformation.h"
#import "AskFromList.h"
#import "UkeleleConstantStrings.h"
#import "AskTextSheet.h"

@implementation ImportDeadKeyHandler {
	NSWindow *parentWindow;
	UkeleleDocument *targetDocument;
}

- (id)init {
	if (self = [super init]) {
		parentWindow = nil;
		targetDocument = nil;
		_completionTarget = nil;
	}
	return self;
}

+ (ImportDeadKeyHandler *)importDeadKeyHandler {
	return [[ImportDeadKeyHandler alloc] init];
}

- (void)beginInteractionForWindow:(NSWindow *)theWindow withDocument:(UkeleleDocument *)theDocument {
	parentWindow = theWindow;
	targetDocument = theDocument;
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
		if (result == NSFileHandlingPanelOKButton) {
				// Got the file
			NSArray *panelURLs = [openPanel URLs];
			NSAssert([panelURLs count] == 1, @"Must have only one file");
			NSURL *documentURL = panelURLs[0];
			[self handleChoiceOfSourceFile:documentURL];
		}
	}];
}

- (void)handleChoiceOfSourceFile:(NSURL *)documentURL {
	NSError *theError;
	NSDictionary *documentProperties = [documentURL resourceValuesForKeys:@[NSURLIsRegularFileKey, NSURLIsPackageKey] error:&theError];
	if (documentProperties == nil) {
			// Couldn't get properties!
	}
	if ([documentProperties[NSURLIsRegularFileKey] boolValue]) {
			// Regular file, should be a keyboard layout file
		[self handleDocumentWithURL:documentURL];
	}
	else if ([documentProperties[NSURLIsPackageKey] boolValue]) {
			// Package, so have to determine whether it's a valid keyboard layout bundle
		KeyboardLayoutBundle *theBundle = [self getKeyboardLayoutBundle:documentURL];
		if (theBundle != nil) {
				// Valid bundle
			[self handleBundle:theBundle];
		}
		else {
				// Not a valid bundle
			NSAlert *alert = [NSAlert alertWithMessageText:@"The document chosen was not a keyboard layout bundle" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
			[alert runModal];
			[self interactionCompleted];
		}
	}
}

- (KeyboardLayoutBundle *)getKeyboardLayoutBundle:(NSURL *)bundleURL {
		// See if we can create a keyboard layout bundle from the URL
	KeyboardLayoutBundle *bundleDocument = [[KeyboardLayoutBundle alloc] init];
	NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL:bundleURL options:0 error:NULL];
	if (fileWrapper != nil) {
		NSError *readError;
		if ([bundleDocument readFromFileWrapper:fileWrapper ofType:@"com.apple.bundle" error:&readError]) {
				// It reads OK
			return bundleDocument;
		}
	}
	return nil;
}

- (void)handleBundle:(KeyboardLayoutBundle *)theDocument {
		// Find the keyboard layouts in the bundle
	NSArray *keyboardLayouts = [theDocument keyboardLayouts];
	if ([keyboardLayouts count] == 1) {
			// Only one keyboard layout, so that's the one to use
		KeyboardLayoutInformation *docInfo = keyboardLayouts[0];
		[self handleDocument:[docInfo document]];
	}
	else if ([keyboardLayouts count] > 1) {
			// Put up a dialog to ask which one to use
		NSMutableArray *keyboardNames = [NSMutableArray arrayWithCapacity:[keyboardLayouts count]];
		for (KeyboardLayoutInformation *keyboardInfo in keyboardLayouts) {
			[keyboardNames addObject:[keyboardInfo keyboardName]];
		}
		__block AskFromList *askFromList = [AskFromList askFromList];
		[askFromList beginAskFromListWithText:@"Choose the keyboard layout to open" withMenu:keyboardNames forWindow:parentWindow callBack:^(NSString *chosenKeyboard) {
			if (chosenKeyboard == nil) {
					// User cancelled
				[self interactionCompleted];
			}
			NSUInteger index = [keyboardNames indexOfObject:chosenKeyboard];
			NSAssert(index != NSNotFound, @"Must have found the keyboard name");
			KeyboardLayoutInformation *info = keyboardLayouts[index];
			[self handleDocument:[info document]];
		}];
	}
	else {
			// No keyboard layouts
		NSAlert *alert = [NSAlert alertWithMessageText:@"There are no keyboard layouts in this document" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
		[alert runModal];
		[self interactionCompleted];
	}
}

- (void)handleDocumentWithURL:(NSURL *)documentURL {
		// We have a URL which should be a valid keyboard layout
	NSData *documentData = [NSData dataWithContentsOfURL:documentURL];
	if (documentData == nil) {
			// Couldn't read the file
		NSAlert *alert = [NSAlert alertWithMessageText:@"Could not read the document" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
		[alert runModal];
		[self interactionCompleted];
		return;
	}
	UkeleleDocument *theDocument = [[UkeleleDocument alloc] init];
	NSError *theError;
	BOOL success = [theDocument readFromData:documentData
									  ofType:@"org.sil.ukelele.keylayout"
									   error:&theError];
	if (!success) {
			// Couldn't create the document
		NSAlert *alert = [NSAlert alertWithError:theError];
		[alert runModal];
		[self interactionCompleted];
		return;
	}
	[self handleDocument:theDocument];
}

- (void)handleDocument:(UkeleleDocument *)theDocument {
		// Have the source document as a UkeleleDocument
		// Check that we have equivalent modifier maps
	UkeleleKeyboardObject *sourceObject = [theDocument keyboardLayout];
	UkeleleKeyboardObject *targetObject = [targetDocument keyboardLayout];
	if (![targetObject hasEquivalentModifierMap:sourceObject]) {
			// Not compatible
		NSAlert *alert = [NSAlert alertWithMessageText:@"The two keyboard layouts have different modifier maps, so cannot import the dead key state" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
		[alert runModal];
		[self interactionCompleted];
		return;
	}
	NSArray *stateNames = [[theDocument keyboardLayout] stateNamesExcept:kStateNameNone];
	if ([stateNames count] == 0) {
			// No states to import
		NSAlert *alert = [NSAlert alertWithMessageText:@"This keyboard layout has no dead key states" defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:@""];
		[alert runModal];
		[self interactionCompleted];
		return;
	}
		// Bring up a dialog to choose the state name to import
	__block AskFromList *askFromList = [AskFromList askFromList];
	[askFromList beginAskFromListWithText:@"Choose the dead key state to import" withMenu:stateNames forWindow:parentWindow callBack:^(NSString *stateName) {
		if (stateName) {
				// Valid state name
			[self importState:stateName fromDocument:theDocument];
		}
		else {
				// User cancelled
			[self interactionCompleted];
		}
		askFromList = nil;
	}];
}

- (void)importState:(NSString *)stateName fromDocument:(UkeleleDocument *)sourceDocument {
		// Ask for a name for the imported state
	NSArray *targetStateList = [[targetDocument keyboardLayout] stateNamesExcept:@""];
	NSMutableSet *targetStates = [NSMutableSet setWithArray:targetStateList];
	[targetStates addObject:@""];
	[targetStates addObject:kStateNameNone];
	__block AskTextSheet *askText = [AskTextSheet askTextSheet];
	[askText beginAskValidatedText:@"Enter a name for the imported dead key state" notFromSet:targetStates errorText:@"The state name must not be already present in this keyboard layout" initialText:@"" forWindow:parentWindow callBack:^(id result) {
		NSString *chosenState = result;
		if (chosenState != nil) {
				// Valid state supplied
			[[targetDocument keyboardLayout] importDeadKeyState:stateName
														toState:chosenState
												   fromKeyboard:[sourceDocument keyboardLayout]];
		}
		[self interactionCompleted];
		askText = nil;
	}];
}

- (void)interactionCompleted {
	[self.completionTarget interactionDidComplete:self];
}

- (void)handleMessage:(NSDictionary *)messageData {
		// No messages to handle
}

@end

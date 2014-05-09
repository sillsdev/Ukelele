//
//  UkeleleDocument.m
//  Ukelele 3
//
//  Created by John Brownie on 11/01/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "UkeleleDocument.h"
#import "UkeleleDocument+Housekeeping.h"
#import "UkeleleConstants.h"
#import "UkeleleView.h"
#import "ViewScale.h"
#import "MathsUtilities.h"
#import "InspectorWindowController.h"
#import "XMLCocoaUtilities.h"
#import "DoubleClickHandler.h"
#import "DragTextHandler.h"
#import "KeyboardEnvironment.h"
#import "UkeleleConstantStrings.h"
#import "KeyboardDefinitions.h"
#import "LayoutInfo.h"
#import "UnlinkKeyHandler.h"
#import "KeyboardTypeSheet.h"
#import "KeyboardPrintView.h"
#import "PrintAccessoryPanel.h"
#import "ToolboxData.h"
#import "UnlinkModifierSetHandler.h"
#import "SwapKeysController.h"
#import "EditKeyWindowController.h"
#import "SelectKeyByCodeController.h"
#import "CreateSelectedDeadKeyController.h"
#import "CreateDeadKeySheet.h"
#import "AskStateAndTerminatorController.h"
#import "GetKeyCodeHandler.h"
#import "AskCommentController.h"
#import "ImportDeadKeyHandler.h"
#import "UkeleleErrorCodes.h"
#import "KeyCapView.h"
#import "AskYesNoController.h"
#import "UkeleleKeyboardInstaller.h"
#include <Carbon/Carbon.h>

const float kWindowMinWidth = 450.0f;
const float kWindowMinHeight = 300.0f;
const float kScalePercentageFactor = 100.0f;

// Keys for state variables

NSString *kStateCurrentState = @"CurrentState";         // NSString, current dead key state
NSString *kStateCurrentKeyboard = @"CurrentKeyboard";   // NSUInteger, current keyboard ID
NSString *kStateCurrentScale = @"CurrentScale";         // double, current view scale
NSString *kStateCurrentModifiers = @"CurrentModifiers"; // NSUInteger, current modifier combination
NSString *kStateModifiersInfo = @"ModifiersInfo";       // ModifiersInfo, modifiers currently being edited/added
NSString *kStateTargetKeyCode = @"TargetKeyCode";       // NSInteger, key code for current key

	// Names for tabs
NSString *kTabNameKeyboard = @"Keyboard";
NSString *kTabNameModifiers = @"Modifiers";
NSString *kTabNameComments = @"Comments";

@interface UkeleleDocument()

- (void)setupDataSource;
- (void)updateModifiers;
+ (NSString *)untitledDocumentName;

@end

@implementation UkeleleDocument {
	BOOL commentChanged;
}

- (id)init
{
    self = [super init];
    if (self) {
    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
    
		NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
        internalState = [NSMutableDictionary dictionary];
        internalState[kStateCurrentState] = kStateNameNone;
		stateStack = [NSMutableArray array];
		[stateStack addObject:kStateNameNone];
		scalesList = [ViewScale standardScales];
        internalState[kStateCurrentScale] = @([theDefaults floatForKey:UKScaleFactor]);
        internalState[kStateCurrentModifiers] = @0U;
		SInt32 keyboardType;
		OSStatus err = Gestalt(gestaltKeyboardType, &keyboardType);
		if (err != noErr  || [theDefaults boolForKey:UKAlwaysUsesDefaultLayout]) {
			keyboardType = [theDefaults integerForKey:UKDefaultLayoutID];
		}
		internalState[kStateCurrentKeyboard] = @(keyboardType);
        interactionHandler = nil;
        modifiersSheet = nil;
        askFromList = nil;
        askNewKeyMap = nil;
        chooseScale = nil;
		keyboardTypeSheet = nil;
		deadKeyData = nil;
		documentAlert = nil;
		replaceNameSheet = nil;
		_iconFile = nil;
		selectedKey = kNoKeyCode;
		commentChanged = NO;
    }
    return self;
}

- (id)initWithType:(NSString *)typeName error:(NSError **)outError
{
	self = [self init];
	[self setFileType:typeName];
	
		// Create an empty keyboard here
	_keyboardLayout = [[UkeleleKeyboardObject alloc] initWithName:[UkeleleDocument untitledDocumentName]];
	[_keyboardLayout setParentDocument:self];
    [_keyboardLayout setDelegate:self];
    [self setupDataSource];
	return self;
}

- (id)initWithCurrentInputSource {
		// Create a temporary file
	NSString *tempFilePath = [NSString stringWithFormat:@"%@UkeleleDataXXXXX.rsrc", NSTemporaryDirectory()];
	char tempFileTemplate[1025];
	[tempFilePath getCString:tempFileTemplate maxLength:1024 encoding:NSUTF8StringEncoding];
	int tempFileDescriptor = mkstemps(tempFileTemplate, 5);
	if (tempFileDescriptor == -1) {
			// Could not create temporary file
		return [self init];
	}
	tempFilePath = @(tempFileTemplate);
	NSFileHandle *tempFileHandle = [[NSFileHandle alloc] initWithFileDescriptor:tempFileDescriptor closeOnDealloc:YES];
	NSURL *tempFileURL = [NSURL fileURLWithPath:tempFilePath];
		// Capture the current keyboard layout as uchr data
	TISInputSourceRef currentInputSource = TISCopyCurrentKeyboardLayoutInputSource();
	CFDataRef uchrData = TISGetInputSourceProperty(currentInputSource, kTISPropertyUnicodeKeyLayoutData);
	if (NULL == uchrData) {
			// Could not get the current input source as uchr data
		return [self init];
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
		return [self init];
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
	self = [self init];
	if ([self readFromData:myData ofType:kFileTypeKeyboardLayout error:&theError]) {
			// Successful creating
		[self setFileURL:nil];
		[self.keyboardLayout addCreationComment];
		[self.keyboardLayout assignRandomID];
	}
	else {
			// The conversion failed
		NSDictionary *errorDictionary = @{NSLocalizedDescriptionKey: @"Could not create a keyboard layout", NSUnderlyingErrorKey: theError};
		NSError *presentedError = [NSError errorWithDomain:kDomainUkelele
													  code:kUkeleleErrorCouldNotCreateFromFile
												  userInfo:errorDictionary];
		[self presentError:presentedError];
		self = nil;
	}
	
		// Clean up
	return self;
}

- (NSDocument *)duplicateAndReturnError:(NSError *__autoreleasing *)outError {
	NSDocument *duplicateDocument = [super duplicateAndReturnError:outError];
	if (duplicateDocument && [duplicateDocument isKindOfClass:[UkeleleDocument class]]) {
			// Duplicated, so set a creation comment
		[(UkeleleDocument *)duplicateDocument addCreationComment];
			// Assign a new, random ID
		[[(UkeleleDocument *)duplicateDocument keyboardLayout] assignRandomID];
	}
	return duplicateDocument;
}

- (void)awakeFromNib {
	modifiersDataSource = [[ModifiersDataSource alloc] initWithKeyboardObject:nil];
	[modifiersTableView setDataSource:modifiersDataSource];
	[modifiersTableView setDoubleAction:@selector(doubleClickRow:)];
	[modifiersTableView setTarget:self];
	[modifiersTableView setDelegate:self];
	[modifiersTableView registerForDraggedTypes:@[ModifiersTableDragType]];
	[modifiersTableView setVerticalMotionCanBeginDrag:YES];
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers,
	// you should remove this method and override -makeWindowControllers instead.
    return @"UkeleleDocument";
}

+ (BOOL)autosavesInPlace
{
	return YES;
}

+ (NSString *)untitledDocumentName {
		// Need to get an appropriate version of "untitled" or "untitled n"
	BOOL gotUntitled = NO;
	NSInteger maximumUntitled = 0;
	for (NSDocument *currentDocument in [[NSDocumentController sharedDocumentController] documents]) {
		if ([currentDocument isKindOfClass:[UkeleleDocument class]]) {
			NSString *documentName = [(UkeleleDocument *)currentDocument keyboardDisplayName];
			if (!gotUntitled && [documentName isEqualToString:@"untitled"]) {
				gotUntitled = YES;
			}
			if ([documentName hasPrefix:@"untitled "]) {
				NSString *potentialNumber = [documentName substringFromIndex:9];
				NSScanner *stringScanner = [NSScanner scannerWithString:potentialNumber];
				NSInteger actualNumber;
				BOOL gotNumber = [stringScanner scanInteger:&actualNumber];
				if (gotNumber && [stringScanner isAtEnd]) {
					maximumUntitled = maximumUntitled > actualNumber ? maximumUntitled : actualNumber;
				}
			}
		}
	}
	NSString *generatedName;
	if (!gotUntitled && maximumUntitled == 0) {
		generatedName = @"untitled";
	}
	else {
		if (maximumUntitled == 0) {
			maximumUntitled = 1;
		}
		generatedName = [NSString stringWithFormat:@"untitled %ld", maximumUntitled + 1];
	}
	return generatedName;
}

#pragma mark Accessors

- (NSUInteger)currentModifiers
{
	return [internalState[kStateCurrentModifiers] unsignedIntegerValue];
}

- (NSString *)currentState
{
	return internalState[kStateCurrentState];
}

- (NSString *)keyboardDisplayName {
	NSString *theKeyboardName = [self.keyboardLayout keyboardName];
	if (nil == theKeyboardName || [theKeyboardName isEqualToString:@""]) {
		theKeyboardName = [ukeleleWindow title];
	}
	return theKeyboardName;
}

- (NSInteger)keyboardID {
	return [self.keyboardLayout keyboardID];
}

- (void)setKeyboardID:(NSInteger)keyboardID {
	[self changeKeyboardID:keyboardID];
}

- (NSInteger)keyboardScript {
	return [self.keyboardLayout keyboardGroup];
}

- (void)setKeyboardScript:(NSInteger)keyboardScript {
	[self changeKeyboardScript:keyboardScript];
}

- (NSString *)keyboardName {
	return [self.keyboardLayout keyboardName];
}

- (void)setKeyboardName:(NSString *)keyboardName {
	[self changeKeyboardName:keyboardName];
}

#pragma mark Internal routines

- (NSSize)getIdealContentSize
{
	UkeleleView *ukeleleView = [keyboardView documentView];
    NSSize contentSize = [[ukeleleWindow contentView] bounds].size;
    NSSize viewSize = [keyboardView contentSize];
    CGFloat verticalPadding = contentSize.height - viewSize.height;
    CGFloat horizontalPadding = contentSize.width - viewSize.width;
	NSSize keyboardSize = [ukeleleView bounds].size;
    keyboardSize = [NSScrollView frameSizeForContentSize:keyboardSize
                                 horizontalScrollerClass:[NSScroller class]
                                   verticalScrollerClass:[NSScroller class]
                                              borderType:NSLineBorder
                                             controlSize:NSRegularControlSize
                                           scrollerStyle:NSScrollerStyleOverlay];
    keyboardSize.height += 1;
    keyboardSize.width += 1;
	NSSize maximumSize = keyboardSize;
    maximumSize.height += verticalPadding;
    maximumSize.width += horizontalPadding;
	return maximumSize;
}

- (void)calculateSize
{
	NSSize maximumSize = [self getIdealContentSize];
	NSSize minimumSize = NSMakeSize(kWindowMinWidth, kWindowMinHeight);
	[ukeleleWindow setContentMaxSize:maximumSize];
	[ukeleleWindow setContentMinSize:minimumSize];
    NSDisableScreenUpdates();
	[ukeleleWindow setContentSize:maximumSize];
	NSRect winBounds = [ukeleleWindow frame];
	NSRect availableRect = [[NSScreen mainScreen] visibleFrame];
	if (!NSContainsRect(availableRect, winBounds)) {
			// Doesn't fit!
		availableRect = NSInsetRect(availableRect, 2, 2);
		NSRect newBounds;
        // If the width is too big to fit in the available rectangle
		if (winBounds.size.width > availableRect.size.width) {
            // Set the width to available and the origin to the available
			newBounds.size.width = availableRect.size.width;
			newBounds.origin.x = availableRect.origin.x;
		}
		else {
            // Width is OK
			newBounds.size.width = winBounds.size.width;
            // If the window is too far to the right
			if (winBounds.origin.x + winBounds.size.width > availableRect.origin.x + availableRect.size.width) {
                // Shift the origin to the left
				newBounds.origin.x = availableRect.origin.x + availableRect.size.width - winBounds.size.width;
			}
            // Else if the window is too far to the left
            else if (winBounds.origin.x < availableRect.origin.x) {
                // Shift the origin to the available rectangle
                newBounds.origin.x = availableRect.origin.x;
            }
			else {
                // Origin.x is OK
				newBounds.origin.x = winBounds.origin.x;
			}
		}
        // If the height is too big to fit
		if (winBounds.size.height > availableRect.size.height) {
            // Set the height to the available height, and the origin to the available
			newBounds.size.height = availableRect.size.height;
			newBounds.origin.y = availableRect.origin.y;
		}
		else {
            // Height is OK
			newBounds.size.height = winBounds.size.height;
            // If the window is too high
			if (winBounds.origin.y + winBounds.size.height > availableRect.origin.y + availableRect.size.height) {
                // Shift the origin down
				newBounds.origin.y = availableRect.origin.y + availableRect.size.height - winBounds.size.height;
			}
            // Else if the window is too low
            else if (winBounds.origin.y < availableRect.origin.y) {
                // Shift the origin up
                newBounds.origin.y = availableRect.origin.y + availableRect.size.height - winBounds.size.height;
            }
			else {
                // Origin.y is OK
				newBounds.origin.y = winBounds.origin.y;
			}
		}
		[ukeleleWindow setFrame:newBounds display:YES];
	}
    NSEnableScreenUpdates();
}

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)newFrame
{
	NSToolbar *theToolbar = [window toolbar];
	float toolbarHeight = 0.0;
	if ([theToolbar isVisible]) {
		NSRect windowFrame = [NSWindow contentRectForFrameRect:[window frame] styleMask:[window styleMask]];
		toolbarHeight = NSHeight(windowFrame) - NSHeight([[window contentView] frame]);
	}
	NSRect contentRect = [window contentRectForFrameRect:[window frame]];
	contentRect.size = [self getIdealContentSize];
	contentRect.size.height += toolbarHeight;
	NSRect frameRect = [NSWindow frameRectForContentRect:contentRect styleMask:[window styleMask]];
	if (!NSContainsRect(newFrame, frameRect)) {
			// Not inside, but will it fit there?
		if (frameRect.size.height > newFrame.size.height || frameRect.size.width > newFrame.size.width) {
			frameRect.size.height = fminf(frameRect.size.height, newFrame.size.height);
			frameRect.size.width = fminf(frameRect.size.width, newFrame.size.width);
		}
		NSRect windowFrame = [window frame];
		frameRect.origin = windowFrame.origin;
		frameRect.origin.y += NSHeight(windowFrame) - NSHeight(frameRect);
	}
	return frameRect;
}

- (void)setViewScaleComboBox
{
    NSNumber *scaleFactor = internalState[kStateCurrentScale];
	NSString *scaleString = [NSString stringWithFormat:@"%.0f%%", [scaleFactor doubleValue] * kScalePercentageFactor];
	[scaleComboBox setStringValue:scaleString];
}

- (CGFloat)fitWidthScale
{
		// First get the base width of the view
	UkeleleView *ukeleleView = [keyboardView documentView];
	CGFloat baseViewWidth = [ukeleleView baseFrame].size.width;
		// Now work out how much space would be available in a full width window
	NSRect winBounds = [ukeleleWindow frame];
	CGFloat horizontalPadding = winBounds.size.width - [keyboardView frame].size.width;
	NSRect availableRect = NSInsetRect([[NSScreen mainScreen] visibleFrame], 2, 2);
		// The scale we want is then the ratio of the size for the widest view to the base view width
	CGFloat widthFactor = (availableRect.size.width - horizontalPadding) / baseViewWidth;
	return widthFactor;
}

- (void)updateWindow
{
	UkeleleView *ukeleleView = [keyboardView documentView];
	NSArray *subViews = [ukeleleView keyCapViews];
    NSNumber *modifiersValue = internalState[kStateCurrentModifiers];
    unsigned int theModifiers = [modifiersValue unsignedIntValue];
    NSMutableDictionary *keyDataDict = [NSMutableDictionary dictionary];
    keyDataDict[kKeyKeyboardID] = internalState[kStateCurrentKeyboard];
    keyDataDict[kKeyKeyCode] = @0;
    keyDataDict[kKeyModifiers] = modifiersValue;
    keyDataDict[kKeyState] = internalState[kStateCurrentState];
	for (KeyCapView *keyCapView in subViews) {
		int keyCode = [keyCapView keyCode];
		if (theModifiers & NSNumericPadKeyMask) {
			keyCode = [keyCapView fnKeyCode];
		}
		NSString *output;
		BOOL deadKey;
		NSString *nextState;
        keyDataDict[kKeyKeyCode] = @(keyCode);
		output = [self.keyboardLayout getCharOutput:keyDataDict isDead:&deadKey nextState:&nextState];
		[keyCapView setOutputString:output];
		[keyCapView setDeadKey:deadKey];
	}
	[ukeleleView updateModifiers:theModifiers];
	[ukeleleView setNeedsDisplay:YES];
}

- (void)changeViewScale:(double)newScale
{
    UkeleleView *ukeleleView = [keyboardView documentView];
    internalState[kStateCurrentScale] = @(newScale);
	[ukeleleView scaleViewToScale:newScale limited:YES];
    [self calculateSize];
    [self setViewScaleComboBox];
    [self updateWindow];
}

- (void)changeKeyboardType:(NSInteger)newKeyboardType
{
	UkeleleView *ukeleleView = [keyboardView documentView];
	internalState[kStateCurrentKeyboard] = @(newKeyboardType);
	NSNumber *scaleValue = internalState[kStateCurrentScale];
	[ukeleleView createViewWithKeyboardID:newKeyboardType withScale:[scaleValue doubleValue]];
	[ukeleleView setMenuDelegate:self];
	[self assignClickTargets];
    [self calculateSize];
    [self setViewScaleComboBox];
    [self updateWindow];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSAssert(documentAlert != nil, @"Ending an alert when there is none");
	documentAlert = nil;
}

#pragma mark Setup

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
	
		// Create a window that has the current keyboard type
	SInt32 keyboardType;
	OSStatus err = Gestalt(gestaltKeyboardType, &keyboardType);
	NSUserDefaults *theDefaults = [NSUserDefaults standardUserDefaults];
	if (err != noErr || [theDefaults boolForKey:UKAlwaysUsesDefaultLayout]) {
		keyboardType = [theDefaults integerForKey:UKDefaultLayoutID];
	}
    internalState[kStateCurrentKeyboard] = @(keyboardType);
    [tabView selectTabViewItemWithIdentifier:kTabNameKeyboard];
	UkeleleView *ukeleleView = [[UkeleleView alloc] init];
    NSNumber *scaleValue = internalState[kStateCurrentScale];
	[ukeleleView createViewWithKeyboardID:keyboardType withScale:[scaleValue doubleValue]];
	[ukeleleView setMenuDelegate:self];
	[keyboardView setDocumentView:ukeleleView];
	[self assignClickTargets];
    [self setupDataSource];
	[self calculateSize];
	[self updateWindow];
	[self setViewScaleComboBox];
	[ukeleleWindow makeFirstResponder:keyboardView];
}

- (BOOL)canAsynchronouslyWriteToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation
{
	return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type.
	// If the given outError != NULL, ensure that you set *outError when returning nil.
	return [self.keyboardLayout convertToData];
	if ([kTabNameComments isEqualToString:[[tabView selectedTabViewItem] identifier]]) {
		[self updateCommentFields];
	}
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type.
	// If the given outError != NULL, ensure that you set *outError when returning NO.
	_keyboardLayout = [[UkeleleKeyboardObject alloc] initWithData:data withError:outError];
    BOOL validLayout = self.keyboardLayout != nil;
    if (validLayout) {
        [self.keyboardLayout setParentDocument:self];
        [self.keyboardLayout setDelegate:self];
        [self setupDataSource];
    }
    return validLayout;
}

- (NSView *)keyboardView
{
	return [keyboardView documentView];
}

- (NSRect)keyRect:(NSInteger)keyCode
{
	UkeleleView *ukeleleView = [keyboardView documentView];
	KeyCapView *keyCap = [ukeleleView findKeyWithCode:keyCode];
	return [keyCap frame];
}

- (CGFloat)currentScale {
    NSNumber *currentScaleValue = internalState[kStateCurrentScale];
	return [currentScaleValue floatValue];
}

- (NSUInteger)currentKeyboard {
    NSNumber *keyboardID = internalState[kStateCurrentKeyboard];
	return [keyboardID unsignedIntegerValue];
}

- (void)assignClickTargets {
	UkeleleView *ukeleleView = [keyboardView documentView];
	for (KeyCapView *subView in [ukeleleView keyCapViews]) {
		[subView setClickDelegate:self];
	}
}

#pragma mark Change display

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    NSNumber *keyboardID = internalState[kStateCurrentKeyboard];
    NSNumber *modifierValue = internalState[kStateCurrentModifiers];
	[KeyboardEnvironment updateKeyboard:[keyboardID integerValue]
						stickyModifiers:NO
							  modifiers:[modifierValue unsignedIntegerValue]
								  state:internalState[kStateCurrentState]];
		// Tell the font panel what font we have
	UkeleleView *ukeleleView = [keyboardView documentView];
	NSDictionary *largeAttributes = [ukeleleView largeAttributes];
	NSFont *largeFont = largeAttributes[NSFontAttributeName];
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	[fontManager setSelectedFont:largeFont isMultiple:NO];
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	[self inspectorDidActivateTab:[[[infoInspector tabView] selectedTabViewItem] identifier]];
	[infoInspector setCurrentKeyboard:self];
}

- (void)windowDidResignMain:(NSNotification *)notification {
	InspectorWindowController *inspectorController = [InspectorWindowController getInstance];
	[inspectorController setCurrentKeyboard:nil];
}

- (void)windowWillClose:(NSNotification *)notification {
	if (commentChanged) {
			// Unsaved comment
		[self saveUnsavedComment];
	}
}

- (void)interactionDidComplete:(id<UKInteractionHandler>)handler
{
    NSAssert(handler == interactionHandler, @"Wrong interaction handler");
    interactionHandler = nil;
}

#pragma mark Tab handling

- (void)tabView:(NSTabView *)theTabView willSelectTabViewItem:(NSTabViewItem *)tabViewItem {
	if ([kTabNameComments isEqualToString:[[theTabView selectedTabViewItem] identifier]]) {
			// We are about to leave the comment tab
		if (commentChanged) {
				// Unsaved comment
			[self saveUnsavedComment];
		}
	}
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if ([kTabNameKeyboard isEqualTo:[tabViewItem identifier]]) {
        // Activating the keyboard tab
        [self setMessageBarText:@""];
		[self setViewScaleComboBox];
		[ukeleleWindow makeFirstResponder:keyboardView];
    }
    else if ([kTabNameModifiers isEqualTo:[tabViewItem identifier]]) {
        // Activating the modifiers tab
        [modifiersTableView setDoubleAction:@selector(doubleClickRow:)];
        [modifiersTableView setTarget:self];
        [self updateModifiers];
        [removeModifiersButton setEnabled:([modifiersTableView selectedRow] >= 0)];
        [simplifyModifiersButton setEnabled:![self.keyboardLayout hasSimplifiedModifiers]];
    }
    else if ([kTabNameComments isEqualTo:[tabViewItem identifier]]) {
        // Activating the comments tab
		[self updateCommentFields];
    }
}

- (BOOL)validateUserInterfaceItem:(id<NSValidatedUserInterfaceItem>)anItem
{
	SEL action = [anItem action];
	if (action == @selector(setKeyboardType:)) {
		return [kTabNameKeyboard isEqualToString:[[tabView selectedTabViewItem] identifier]];
	}
	else if (action == @selector(createDeadKeyState:) || action == @selector(swapKeys:) ||
			 action == @selector(swapKeysByCode:) || action == @selector(addSpecialKeyOutput:) ||
			 action == @selector(unlinkKeyAskingKeyCode:) || action == @selector(unlinkModifierSet:) ||
			 action == @selector(importDeadKey:) || action == @selector(editKey:) ||
			 action == @selector(selectKeyByCode:) || action == @selector(cutKey:) ||
			 action == @selector(copyKey:) || action == @selector(attachComment:)) {
			// All of these can only be selected if there is no interaction in progress
		return (interactionHandler == nil) && [kTabNameKeyboard isEqualTo:[[tabView selectedTabViewItem] identifier]];
	}
	else if (action == @selector(enterDeadKeyState:) || action == @selector(changeStateName:) ||
			 action == @selector(changeTerminator:)) {
			// These can only be selected if there are any states other than "none"
		NSUInteger stateCount = [_keyboardLayout stateCount];
		return (interactionHandler == nil) &&
			[kTabNameKeyboard isEqualTo:[[tabView selectedTabViewItem] identifier]] &&
			([stateStack count] > 1 ? stateCount > 1 : stateCount > 0);
	}
	else if (action == @selector(leaveDeadKeyState:)) {
			// These can only selected if we are in a dead key state, and no interaction is in progress
		return (interactionHandler == nil) && [kTabNameKeyboard isEqualToString:[[tabView selectedTabViewItem] identifier]] && [stateStack count] > 1;
	}
	else if (action == @selector(unlinkKey:)) {
			// This can come up either on the keyboard or modifiers tab
		if ([kTabNameKeyboard isEqualToString:[[tabView selectedTabViewItem] identifier]]) {
			return interactionHandler == nil;
		}
		else if ([kTabNameModifiers isEqualToString:[[tabView selectedTabViewItem] identifier]]) {
			return (interactionHandler == nil) && ([modifiersTableView selectedRow] >= 0);
		}
		else {
			return NO;
		}
	}
	else if (action == @selector(pasteKey:)) {
			// This can only be selected if there is a key to paste, and no interation is in progress
		return (interactionHandler == nil) && [self.keyboardLayout hasKeyOnPasteboard];
	}
	else if (action == @selector(installForAllUsers:) || action == @selector(installForCurrentUser:)) {
			// These can only be selected if the keyboard has been saved
		return [self fileURL] != nil;
	}
	return [super validateUserInterfaceItem:anItem];
}

#pragma mark === Installing ===

- (IBAction)installForCurrentUser:(id)sender {
	UkeleleKeyboardInstaller *theInstaller = [UkeleleKeyboardInstaller defaultInstaller];
	NSError *theError;
	BOOL installOK = [theInstaller installForCurrentUser:[self fileURL] error:&theError];
	if (!installOK) {
		[self presentError:theError modalForWindow:ukeleleWindow delegate:nil didPresentSelector:nil contextInfo:nil];
	}
}

- (IBAction)installForAllUsers:(id)sender {
	UkeleleKeyboardInstaller *theInstaller = [UkeleleKeyboardInstaller defaultInstaller];
	NSError *theError;
	BOOL installOK = [theInstaller installForAllUsers:[self fileURL] error:&theError];
	if (!installOK) {
		[self presentError:theError modalForWindow:ukeleleWindow delegate:nil didPresentSelector:nil contextInfo:nil];
	}
}

#pragma mark === Inspector ===

- (void)inspectorDidActivateTab:(NSString *)tabIdentifier {
	InspectorWindowController *inspectorController = [InspectorWindowController getInstance];
	if ([tabIdentifier isEqualToString:kTabIdentifierDocument]) {
			// Activating the document tab
		[inspectorController setKeyboardSectionEnabled:YES];
		[inspectorController setBundleSectionEnabled:NO];
	}
	else if ([tabIdentifier isEqualToString:kTabIdentifierOutput]) {
			// Activating the output tab
	}
	else if ([tabIdentifier isEqualToString:kTabIdentifierState]) {
			// Activating the state tab
		[self inspectorSetModifiers];
		[self inspectorSetModifierMatch];
		[inspectorController setStateStack:stateStack];
	}
}

- (void)inspectorSetModifiers {
	NSInteger currentModifiers = [internalState[kStateCurrentModifiers] integerValue];
	NSMutableString *modifierString = [NSMutableString string];
	if (currentModifiers & NSAlphaShiftKeyMask) {
		[modifierString appendFormat:@"%C", (unichar)kCapsLockUnicode];
	}
	if (currentModifiers & NSCommandKeyMask) {
		[modifierString appendFormat:@"%C", (unichar)kCommandUnicode];
	}
	if (currentModifiers & NSShiftKeyMask) {
		[modifierString appendFormat:@"%C", (unichar)kShiftUnicode];
	}
	if (currentModifiers & NSControlKeyMask) {
		[modifierString appendFormat:@"%C", (unichar)kControlUnicode];
	}
	if (currentModifiers & NSAlternateKeyMask) {
		[modifierString appendFormat:@"%C", (unichar)kOptionUnicode];
	}
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	[[infoInspector modifiersField] setStringValue:modifierString];
}

- (void)inspectorSetModifierMatch {
	NSInteger currentModifiers = [internalState[kStateCurrentModifiers] integerValue];
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	NSUInteger matchingSet = [_keyboardLayout modifierSetIndexForModifiers:currentModifiers forKeyboard:[internalState[kStateCurrentKeyboard] unsignedIntegerValue]];
	[[infoInspector modifierMatchField] setStringValue:[NSString stringWithFormat:@"%lu", matchingSet]];
}

#pragma mark === Keyboard tab ===

- (IBAction)setScaleValue:(id)sender
{
	float scaleValue;
    NSInteger selItem = [sender indexOfSelectedItem];
	ViewScale *selectedObject = scalesList[selItem];
	scaleValue = [selectedObject scaleValue];
    NSNumber *currentScaleValue = internalState[kStateCurrentScale];
    double currentScale = [currentScaleValue doubleValue];
    if (scaleValue < 0) {
        // This is fit width
        [self changeViewScale:[self fitWidthScale]];
    }
    else if (scaleValue == 0) {
        // This is "other"
        chooseScale = [ChooseScale makeChooseScale];
        [chooseScale beginChooseScale:currentScale * kScalePercentageFactor
                            forWindow:ukeleleWindow
                             callBack:^(NSNumber *newValue) {
								 if (newValue != nil) {
										 // Extract the new scale value
									 double scaleValue = [newValue doubleValue];
										 // Change the scale of the window
									 [self changeViewScale:scaleValue / kScalePercentageFactor];
								 }
								 chooseScale = nil;
							 }];
    }
	else if (scaleValue != currentScale) {
        // Change the scale of the window
        [self changeViewScale:scaleValue];
	}
}

- (IBAction)setScaleLevel:(id)sender
{
	NSInteger selectedItem = [scaleComboBox indexOfSelectedItem];
	if (selectedItem == -1) {
			// No selection, so we take the value from the text field
		CGFloat percentageEntered = [scaleComboBox floatValue];
		CGFloat scaleEntered = percentageEntered / kScalePercentageFactor;
		[self changeViewScale:scaleEntered];
	}
	else {
		ViewScale *selectedObject = scalesList[selectedItem];
		CGFloat scaleValue = [selectedObject scaleValue];
		if (scaleValue < 0) {
			[self changeViewScale:[self fitWidthScale]];
		}
		else {
			[self changeViewScale:scaleValue];
		}
	}
	[self setViewScaleComboBox];
	[ukeleleWindow makeFirstResponder:keyboardView];
}

- (void)enterDeadKeyStateWithName:(NSString *)stateName
{
	if ([stateName isEqualToString:internalState[kStateCurrentState]]) {
        // We're already in this state
		NSLog(@"Trying to enter state %@ when we are in that state", stateName);
		return;
	}
	[stateStack addObject:stateName];
    internalState[kStateCurrentState] = stateName;
	[self updateWindow];
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	[infoInspector setStateStack:stateStack];
}

- (void)leaveCurrentDeadKeyState
{
	if ([stateStack count] <= 1) {
		NSLog(@"Trying to pop state none");
		return;
	}
	[stateStack removeLastObject];
    internalState[kStateCurrentState] = [stateStack lastObject];
	[self updateWindow];
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	[infoInspector setStateStack:stateStack];
}

- (void)setMessageBarText:(NSString *)message
{
	[messageBar setStringValue:message];
	[messageBar setNeedsDisplay:YES];
}

- (void)setSelectedKey:(NSInteger)keyCode {
	if (selectedKey == keyCode) {
			// Selecting the same key, so toggle it
		[self clearSelectedKey];
		return;
	}
	if (selectedKey != kNoKeyCode) {
			// There was a previous selected key
		[self clearSelectedKey];
	}
	selectedKey = keyCode;
	UkeleleView *ukeleleView = [keyboardView documentView];
	KeyCapView *keyCap = [ukeleleView findKeyWithCode:selectedKey];
	if (keyCap) {
		[keyCap setSelected:YES];
		[self updateWindow];
	}
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	if ([[infoInspector window] isVisible]) {
		NSString *keyCodeString = [NSString stringWithFormat:@"%ld", (long)keyCode];
		[[infoInspector selectedKeyField] setStringValue:keyCodeString];
	}
}

- (void)clearSelectedKey {
	UkeleleView *ukeleleView = [keyboardView documentView];
	KeyCapView *keyCap = [ukeleleView findKeyWithCode:selectedKey];
	if (keyCap) {
		[keyCap setSelected:NO];
		[self updateWindow];
	}
	selectedKey = kNoKeyCode;
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	if ([[infoInspector window] isVisible]) {
		[[infoInspector selectedKeyField] setStringValue:@""];
	}
}

#pragma mark Callbacks

- (void)showEditingPaneForKeyCode:(int)keyCode text:(NSString *)initialText target:(id)target action:(SEL)action
{
	UkeleleView *ukeleleView = [keyboardView documentView];
	KeyCapView *keyCap = [ukeleleView findKeyWithCode:keyCode];
	NSRect editingPaneFrame = [keyCap frame];
	NSTextField *editingPane = [[NSTextField alloc] initWithFrame:editingPaneFrame];
	[ukeleleView addSubview:editingPane];
	[editingPane setEditable:YES];
	[editingPane setStringValue:initialText];
	[editingPane setTarget:target];
	[editingPane setAction:action];
	[editingPane setHidden:NO];
	[editingPane setDelegate:target];
	[[ukeleleView window] makeFirstResponder:editingPane];
}

- (void)handleScaleChoice:(NSNumber *)newValue
{
    if (newValue != nil) {
        // Extract the new scale value
        double scaleValue = [newValue doubleValue];
        // Change the scale of the window
        [self changeViewScale:scaleValue / kScalePercentageFactor];
    }
    chooseScale = nil;
}

- (void)acceptDeadKeyStateToEnter:(NSString *)stateName
{
	if (stateName == nil) {
			// User cancelled
	} else {
		[self enterDeadKeyStateWithName:stateName];
	}
	askFromList = nil;
}

- (void)setKeyboard:(NSNumber *)keyboardID
{
	if (keyboardID == nil) {
			// User cancelled
	}
	else {
		NSInteger theKeyboard = [keyboardID intValue];
		[self changeKeyboardType:theKeyboard];
	}
	keyboardTypeSheet = nil;
}

#pragma mark User actions

- (IBAction)createDeadKeyState:(id)sender
{
	NSAssert(interactionHandler == nil, @"Starting an interaction when one is in progress");
	NSUInteger currentModifiers = [internalState[kStateCurrentModifiers] unsignedIntegerValue];
	CreateDeadKeyHandler *theHandler = [[CreateDeadKeyHandler alloc]
										initWithCurrentState:internalState[kStateCurrentState]
										modifiers:currentModifiers
										keyboardID:[internalState[kStateCurrentKeyboard] integerValue]
										keyboardDocument:self
										window:ukeleleWindow
										keyCode:selectedKey
										nextState:nil
										terminator:nil];
	interactionHandler = theHandler;
	[theHandler setCompletionTarget:self];
	[theHandler startHandling];
}

- (IBAction)enterDeadKeyState:(id)sender
{
		// Ask for a dead key state to enter
	if (!askFromList) {
		askFromList = [AskFromList askFromList];
	}
	NSString *dialogText = NSLocalizedStringFromTable(@"Choose the dead key state to enter.",
													  @"dialogs", @"Choose dead key state to enter");
	NSArray *menuItems = [self.keyboardLayout stateNamesExcept:internalState[kStateCurrentState]];
	[askFromList beginAskFromListWithText:dialogText
								 withMenu:menuItems
								forWindow:ukeleleWindow
								 callBack:^(NSString *stateName) {
									 if (stateName == nil) {
											 // User cancelled
									 } else {
										 [self enterDeadKeyStateWithName:stateName];
									 }
									 askFromList = nil;
								 }];
}

- (IBAction)leaveDeadKeyState:(id)sender
{
	[self leaveCurrentDeadKeyState];
}

- (void)changeDeadKeyNextState:(NSDictionary *)keyDataDict newState:(NSString *)nextState
{
	[self.keyboardLayout changeDeadKeyNextState:keyDataDict toState:nextState];
	[self updateWindow];
}

- (void)createNewDeadKey:(NSDictionary *)keyDataDict nextState:(NSString *)nextState usingExistingState:(BOOL)usingExisting
{
	if (!usingExisting) {
		[self.keyboardLayout createState:nextState withTerminator:keyDataDict[kDeadKeyDataTerminator]];
	}
	[self.keyboardLayout makeKeyDeadKey:keyDataDict state:nextState];
	[self enterDeadKeyStateWithName:nextState];
}

- (IBAction)unlinkKey:(id)sender
{
	if ([kTabNameModifiers isEqualToString:[[tabView selectedTabViewItem] identifier]]) {
			// We're on the modifiers tab, so invoke unlinking a set
		[self unlinkModifierSet:sender];
		return;
	}
	NSAssert(interactionHandler == nil, @"Interaction is in progress");
	UnlinkKeyHandler *theHandler = [UnlinkKeyHandler unlinkKeyHandler:self window:ukeleleWindow];
	interactionHandler = theHandler;
	[theHandler setCompletionTarget:self];
	UnlinkKeyType keyType = kUnlinkKeyTypeAskKey;
	if (selectedKey != kNoKeyCode || [sender isMemberOfClass:[KeyCapView class]]) {
		keyType = kUnlinkKeyTypeSelectedKey;
		if (selectedKey != kNoKeyCode) {
			[theHandler setSelectedKeyCode:selectedKey];
		}
		else {
			[theHandler setSelectedKeyCode:[(KeyCapView *)sender keyCode]];
		}
	}
	[theHandler beginInteraction:keyType];
}

- (IBAction)unlinkKeyAskingKeyCode:(id)sender
{
	NSAssert(interactionHandler == nil, @"Interaction is in progress");
	UnlinkKeyHandler *theHandler = [UnlinkKeyHandler unlinkKeyHandler:self window:ukeleleWindow];
	interactionHandler = theHandler;
	[theHandler setCompletionTarget:self];
	[theHandler beginInteraction:kUnlinkKeyTypeAskCode];
}

- (void)unlinkModifierCombination {
	NSAssert(interactionHandler == nil, @"Interaction is in progress");
	UnlinkModifierSetHandler *theHandler = [UnlinkModifierSetHandler unlinkModifierSetHandler:self window:ukeleleWindow];
	interactionHandler = theHandler;
	[theHandler setCompletionTarget:self];
	[theHandler beginInteractionWithCallback:^(NSInteger modifierSet) {
		if (modifierSet >= 0) {
				// Unlink the set
			NSInteger keyboardID = [internalState[kStateCurrentKeyboard] integerValue];
			[_keyboardLayout unlinkModifierSet:modifierSet forKeyboard:keyboardID];
		}
	}];
}

- (IBAction)swapKeys:(id)sender {
	interactionHandler = [SwapKeysController swapKeysController:self window:ukeleleWindow];
	[(SwapKeysController *)interactionHandler beginInteraction:NO];
}

- (IBAction)swapKeysByCode:(id)sender {
	interactionHandler = [SwapKeysController swapKeysController:self window:ukeleleWindow];
	[(SwapKeysController *)interactionHandler beginInteraction:YES];
}

- (IBAction)setKeyboardType:(id)sender
{
	keyboardTypeSheet = [KeyboardTypeSheet createKeyboardTypeSheet];
	[keyboardTypeSheet beginKeyboardTypeSheetForWindow:ukeleleWindow
										  withKeyboard:[internalState[kStateCurrentKeyboard] integerValue]
											  callBack:^(NSNumber *keyboardID) {
												  if (keyboardID == nil) {
														  // User cancelled
												  }
												  else {
													  NSInteger theKeyboard = [keyboardID intValue];
													  [self changeKeyboardType:theKeyboard];
												  }
												  keyboardTypeSheet = nil;
											  }];
}

- (IBAction)importDeadKey:(id)sender {
	NSAssert(interactionHandler == nil, @"Cannot start new interaction");
	ImportDeadKeyHandler *importHandler = [ImportDeadKeyHandler importDeadKeyHandler];
	interactionHandler = importHandler;
	[importHandler setCompletionTarget:self];
	[importHandler beginInteractionForWindow:ukeleleWindow withDocument:self];
}

- (IBAction)changeTerminator:(id)sender {
	NSString *currentTerminator;
	NSString *currentState = internalState[kStateCurrentState];
	if ([sender isMemberOfClass:[KeyCapView class]]) {
			// Contextual menu version
		NSInteger keyCode = [(KeyCapView *)sender keyCode];
		NSDictionary *keyData = @{kKeyKeyboardID: internalState[kStateCurrentKeyboard],
							kKeyState: currentState,
							kKeyKeyCode: @(keyCode),
							kKeyModifiers: internalState[kStateCurrentModifiers]};
		currentState = [self.keyboardLayout getNextState:keyData];
	}
	if ([currentState isEqualToString:kStateNameNone]) {
			// Not in a dead key state, and not a contextual menu
		[self changeTerminatorSpecifyingState];
		return;
	}
	currentTerminator = [self.keyboardLayout terminatorForState:currentState];
	__block AskTextSheet *askTerminatorSheet = [AskTextSheet askTextSheet];
	[askTerminatorSheet beginAskText:@"Please enter the new terminator"
						   minorText:[NSString stringWithFormat:@"This will be the terminator for the state \"%@\"", currentState]
						 initialText:currentTerminator
						   forWindow:ukeleleWindow
							callBack:^(NSString *suppliedString) {
								if (suppliedString) {
										// Got a new terminator
									[self changeTerminatorForState:currentState to:suppliedString];
								}
								askTerminatorSheet = nil;
	}];
}

- (void)changeTerminatorSpecifyingState {
	__block AskStateAndTerminatorController *theController = [AskStateAndTerminatorController askStateAndTerminatorController];
	[theController beginInteractionWithWindow:ukeleleWindow
								  forDocument:self.keyboardLayout
							  completionBlock:^(NSDictionary *dataDict) {
								  if (dataDict) {
										  // Got a valid terminator
									  [self changeTerminatorForState:dataDict[kAskStateAndTerminatorState] to:dataDict[kAskStateAndTerminatorTerminator]];
								  }
								  theController = nil;
	}];
}

- (IBAction)editKey:(id)sender {
	__block EditKeyWindowController *editKeyWindow = [EditKeyWindowController editKeyWindowController];
	NSDictionary *editKeyData = @{kKeyKeyboardObject: self.keyboardLayout,
							   kKeyKeyboardID: @(self.currentKeyboard),
							   kKeyState: self.currentState,
							   kKeyKeyCode: @(selectedKey),
							   kKeyModifiers: @(self.currentModifiers)};
	[editKeyWindow beginInteractionForWindow:ukeleleWindow withData:editKeyData action:^(NSDictionary *callbackData) {
		if ([callbackData[kKeyKeyType] isEqualToString:kKeyTypeOutput]) {
				// Output key
			NSDictionary *keyData = @{kKeyKeyboardObject: self.keyboardLayout,
							 kKeyKeyboardID: @(self.currentKeyboard),
							 kKeyState: self.currentState,
							 kKeyModifiers: callbackData[kDeadKeyDataModifiers],
							 kKeyKeyCode: callbackData[kDeadKeyDataKeyCode]};
			BOOL deadKey = [self.keyboardLayout isDeadKey:keyData];
			if (deadKey) {
				[self makeDeadKeyOutput:keyData output:callbackData[kKeyKeyOutput]];
			}
			else {
				BOOL jisOnly = [[ToolboxData sharedToolboxData] JISOnly];
				[self changeOutputForKey:keyData to:callbackData[kKeyKeyOutput] usingBaseMap:!jisOnly];
			}
		}
		else if ([callbackData[kKeyKeyType] isEqualToString:kKeyTypeDead]) {
				// Dead key
			CreateDeadKeyHandler *theHandler = [[CreateDeadKeyHandler alloc]
												initWithCurrentState:internalState[kStateCurrentState]
												modifiers:[internalState[kStateCurrentModifiers] unsignedIntegerValue]
												keyboardID:[internalState[kStateCurrentKeyboard] integerValue]
												keyboardDocument:self
												window:ukeleleWindow
												keyCode:[callbackData[kKeyKeyCode] integerValue]
												nextState:callbackData[kKeyNextState]
												terminator:callbackData[kKeyTerminator]];
			interactionHandler = theHandler;
			[theHandler setCompletionTarget:self];
			[theHandler startHandling];
		}
		editKeyWindow = nil;
	}];
}

- (IBAction)selectKeyByCode:(id)sender {
	__block SelectKeyByCodeController *selectKeySheet = [SelectKeyByCodeController selectKeyByCodeController];
	[selectKeySheet setMajorText:@"Enter the code of the key you want to select. Codes are in the range from 0 to 511, though the usual range is 0 to 127."];
	[selectKeySheet setMinorText:@""];
	[selectKeySheet beginDialogWithWindow:ukeleleWindow completionBlock:^(NSInteger keyCode) {
		if (keyCode >= 0) {
				// Valid selection
			[self setSelectedKey:keyCode];
		}
		selectKeySheet = nil;
	}];
}

- (void)printDocumentWithSettings:(NSDictionary *)printSettings showPrintPanel:(BOOL)showPrintPanel delegate:(id)delegate didPrintSelector:(SEL)didPrintSelector contextInfo:(void *)contextInfo {
	NSError *error;
	NSPrintOperation *operation = [self printOperationWithSettings:@{} error:&error];
	KeyboardPrintView *printView = (KeyboardPrintView *)[operation view];
	[operation setShowsPrintPanel:showPrintPanel];
	if (showPrintPanel) {
			// Create and show the accessory view
		PrintAccessoryPanel *accessoryPanel = [PrintAccessoryPanel printAccessoryPanel];
		[accessoryPanel setPrintView:printView];
		NSPrintPanel *printPanel = [operation printPanel];
		[printPanel addAccessoryController:accessoryPanel];
	}
	[self runModalPrintOperation:operation delegate:delegate didRunSelector:didPrintSelector contextInfo:contextInfo];
}

- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError {
	NSPrintInfo *pi = [self printInfo];
	NSSize paperSize = [pi paperSize];
	CGFloat pageWidth = paperSize.width - [pi leftMargin] - [pi rightMargin];
	CGFloat pageHeight = paperSize.height - [pi topMargin] - [pi bottomMargin];
	KeyboardPrintView *printView = [[KeyboardPrintView alloc] initWithFrame:NSMakeRect(0, 0, pageWidth, pageHeight)];
	[printView setParentDocument:self];
	NSPrintOperation *op = [NSPrintOperation printOperationWithView:printView printInfo:[self printInfo]];
	[printView setupPageParameters];
	return op;
}

- (void)document:(NSDocument *)document didPrint:(BOOL)didPrintSuccessfully contextInfo:(void *)contextInfo {
	NSLog(@"Did print");
}

- (void)changeFont:(id)sender {
		// The font has changed in the font panel, so update the window
	UkeleleView *ukeleleView = [keyboardView documentView];
	NSDictionary *largeAttributes = [ukeleleView largeAttributes];
	NSDictionary *smallAttributes = [ukeleleView smallAttributes];
	NSFont *oldLargeFont = largeAttributes[NSFontAttributeName];
	NSFont *newLargeFont = [sender convertFont:oldLargeFont];
	NSMutableDictionary *newLargeAttributes = [largeAttributes mutableCopy];
	newLargeAttributes[NSFontAttributeName] = newLargeFont;
	[ukeleleView setLargeAttributes:newLargeAttributes];
	CGFloat largeSize = [newLargeFont pointSize];
	CGFloat smallSize = largeSize * kDefaultSmallFontSize / kDefaultLargeFontSize;
	NSFont *newSmallFont = [sender convertFont:newLargeFont toSize:smallSize];
	NSMutableDictionary *newSmallAttributes = [smallAttributes mutableCopy];
	newSmallAttributes[NSFontAttributeName] = newSmallFont;
	[ukeleleView setSmallAttributes:newSmallAttributes];
}

- (IBAction)cutKey:(id)sender {
	NSInteger keyCode;
	if ([sender isKindOfClass:[KeyCapView class]]) {
			// Came from a contextual menu
		keyCode = [(KeyCapView *)sender keyCode];
	}
	else if (selectedKey != kNoKeyCode) {
			// We have a selected key, so use that
		keyCode = selectedKey;
	}
	else {
			// No selected key, so need to ask for it
		[self setMessageBarText:@"Click or type the key you wish to cut"];
		interactionHandler = [GetKeyCodeHandler getKeyCodeHandler];
		[(GetKeyCodeHandler *)interactionHandler setCompletionTarget:self];
		[(GetKeyCodeHandler *)interactionHandler beginInteractionWithCompletion:^(NSInteger enteredKeyCode) {
			if (enteredKeyCode != kNoKeyCode) {
				[self doCutKey:enteredKeyCode];
			}
			[self setMessageBarText:@""];
		}];
		return;
	}
	[self doCutKey:keyCode];
}

- (IBAction)copyKey:(id)sender {
	NSInteger keyCode;
	if ([sender isKindOfClass:[KeyCapView class]]) {
			// Came from a contextual menu
		keyCode = [(KeyCapView *)sender keyCode];
	}
	else if (selectedKey != kNoKeyCode) {
			// We have a selected key, so use that
		keyCode = selectedKey;
	}
	else {
			// No selected key, so need to ask for it
		[self setMessageBarText:@"Click or type the key you wish to copy"];
		interactionHandler = [GetKeyCodeHandler getKeyCodeHandler];
		[(GetKeyCodeHandler *)interactionHandler setCompletionTarget:self];
		[(GetKeyCodeHandler *)interactionHandler beginInteractionWithCompletion:^(NSInteger enteredKeyCode) {
			if (enteredKeyCode != kNoKeyCode) {
				[self doCopyKey:enteredKeyCode];
			}
			[self setMessageBarText:@""];
		}];
		return;
	}
	[self doCopyKey:keyCode];
}

- (IBAction)pasteKey:(id)sender {
	NSInteger keyCode;
	if ([sender isKindOfClass:[KeyCapView class]]) {
			// Came from a contextual menu
		keyCode = [(KeyCapView *)sender keyCode];
	}
	else if (selectedKey != kNoKeyCode) {
			// We have a selected key, so use that
		keyCode = selectedKey;
	}
	else {
			// No selected key, so need to ask for it
		[self setMessageBarText:@"Click or type the key you wish to paste onto"];
		interactionHandler = [GetKeyCodeHandler getKeyCodeHandler];
		[(GetKeyCodeHandler *)interactionHandler setCompletionTarget:self];
		[(GetKeyCodeHandler *)interactionHandler beginInteractionWithCompletion:^(NSInteger enteredKeyCode) {
			if (enteredKeyCode != kNoKeyCode) {
				[self doPasteKey:enteredKeyCode];
			}
			[self setMessageBarText:@""];
		}];
		return;
	}
	[self doPasteKey:keyCode];
}

- (IBAction)makeOutput:(id)sender {
	NSInteger keyCode = [(KeyCapView *)sender keyCode];
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:self, kKeyDocument,
									 internalState[kStateCurrentKeyboard], kKeyKeyboardID,
									 @(keyCode), kKeyKeyCode,
									 internalState[kStateCurrentModifiers], kKeyModifiers,
									 internalState[kStateCurrentState], kKeyState, nil];
	DoubleClickHandler *handler = [[DoubleClickHandler alloc] initWithData:dataDict
															keyboardLayout:self.keyboardLayout
																	window:[keyboardView window]];
    [handler setCompletionTarget:self];
	[handler setDeadKeyProcessingType:kDoubleClickDeadKeyChangeToOutput];
	[handler startDoubleClick];
    interactionHandler = handler;
}

- (IBAction)makeDeadKey:(id)sender {
	selectedKey = [(KeyCapView *)sender keyCode];
	[self createDeadKeyState:self];
}

- (IBAction)changeNextState:(id)sender {
	NSInteger keyCode = [(KeyCapView *)sender keyCode];
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:self, kKeyDocument,
									 internalState[kStateCurrentKeyboard], kKeyKeyboardID,
									 @(keyCode), kKeyKeyCode,
									 internalState[kStateCurrentModifiers], kKeyModifiers,
									 internalState[kStateCurrentState], kKeyState, nil];
	DoubleClickHandler *handler = [[DoubleClickHandler alloc] initWithData:dataDict
															keyboardLayout:self.keyboardLayout
																	window:[keyboardView window]];
    [handler setCompletionTarget:self];
	[handler askNewState];
    interactionHandler = handler;
}

- (IBAction)changeOutput:(id)sender {
	NSInteger keyCode = [(KeyCapView *)sender keyCode];
	[self messageDoubleClick:keyCode];
}

- (IBAction)attachComment:(id)sender {
	if ([sender isKindOfClass:[KeyCapView class]]) {
		__block NSInteger keyCode = [(KeyCapView *)sender keyCode];
		__block AskCommentController *commentController = [AskCommentController askCommentController];
		[commentController askCommentForWindow:ukeleleWindow completion:^(NSString *commentText) {
			if (commentText != nil && [commentText length] > 0) {
					// Got a non-empty comment
				NSDictionary *dataDict = @{kKeyDocument: self,
							   kKeyKeyboardID: internalState[kStateCurrentKeyboard],
							   kKeyKeyCode: @(keyCode),
							   kKeyModifiers: internalState[kStateCurrentModifiers],
							   kKeyState: internalState[kStateCurrentState]};
				XMLCommentHolderObject *commentHolder = [self.keyboardLayout commentHolderForKey:dataDict];
				[self addComment:commentText toHolder:commentHolder];
			}
			commentController = nil;
		}];
	}
}

#pragma mark Messages

- (void)handleKeyCapClick:(KeyCapView *)keyCapView clickCount:(NSInteger)clickCount {
	if (clickCount == 1) {
		[self messageClick:[keyCapView keyCode]];
	}
	else if (clickCount == 2) {
		[self messageDoubleClick:[keyCapView keyCode]];
	}
}

- (void)messageModifiersChanged:(int)modifiers
{
	static NSUInteger lastModifiers = 0;
    // Modifiers have changed, so make note of changes
	BOOL usingStickyModifiers = [[ToolboxData sharedToolboxData] stickyModifiers];
	NSUInteger newCurrentModifiers = modifiers;
	if (usingStickyModifiers) {
		NSUInteger changedModifiers = lastModifiers ^ modifiers;
		static NSUInteger modifierKeys[] = { NSShiftKeyMask, NSCommandKeyMask, NSControlKeyMask, NSAlternateKeyMask };
		static NSInteger numModifierKeys = sizeof(modifierKeys) / sizeof(NSUInteger);
		for (NSUInteger i = 0; i < numModifierKeys; i++) {
				// If it is a key down event, then update the modifiers
			if ((changedModifiers & modifierKeys[i]) && (modifiers & modifierKeys[i])) {
				newCurrentModifiers ^= modifierKeys[i];
			}
		}
		newCurrentModifiers &= ~NSAlphaShiftKeyMask;
		newCurrentModifiers |= NSAlphaShiftKeyMask & modifiers;
	}
    internalState[kStateCurrentModifiers] = @(newCurrentModifiers);
	[self inspectorSetModifiers];
	[self inspectorSetModifierMatch];
	[self updateWindow];
}

- (void)messageMouseEntered:(int)keyCode
{
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	if ([[infoInspector window] isVisible]) {
		NSDictionary *keyDataDict = @{kKeyKeyboardID: internalState[kStateCurrentKeyboard],
									  kKeyKeyCode: @(keyCode),
									  kKeyModifiers: internalState[kStateCurrentModifiers],
									  kKeyState: internalState[kStateCurrentState]};
        NSString *displayText = [self.keyboardLayout getOutputInfoForKey:keyDataDict];
		[[infoInspector outputField] setStringValue:displayText];
	}
}

- (void)messageMouseExited:(int)keyCode
{
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	if ([[infoInspector window] isVisible]) {
		[[infoInspector outputField] setStringValue:@""];
	}
}

- (void)messageKeyDown:(int)keyCode
{
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	if ([[infoInspector window] isVisible]) {
		NSString *keyCodeString = [NSString stringWithFormat:@"%d", keyCode];
		[[infoInspector keyCodeField] setStringValue:keyCodeString];
	}
	if (interactionHandler != nil) {
		NSDictionary *messageDictionary = @{kMessageNameKey: kMessageKeyDown,
										   kMessageArgumentKey: @(keyCode)};
		[interactionHandler handleMessage:messageDictionary];
	}
	else {
		[self setSelectedKey:keyCode];
	}
}

- (void)messageKeyUp:(int)keyCode
{
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	if ([[infoInspector window] isVisible]) {
		[[infoInspector keyCodeField] setStringValue:@""];
	}
}

- (void)messageClick:(int)keyCode
{
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	if ([[infoInspector window] isVisible]) {
		NSString *keyCodeString = [NSString stringWithFormat:@"%d", keyCode];
		[[infoInspector keyCodeField] setStringValue:keyCodeString];
	}
	BOOL usingStickyModifiers = [[ToolboxData sharedToolboxData] stickyModifiers];
	BOOL handleClickAsDoubleClick = [[NSUserDefaults standardUserDefaults] boolForKey:UKUsesSingleClickToEdit];
	if ([LayoutInfo getKeyType:keyCode] == kModifierKeyType) {
		if (usingStickyModifiers) {
				// Toggle the modifier key
			NSUInteger modifier = [LayoutInfo getModifierFromKeyCode:keyCode];
			NSUInteger currentModifiers = [internalState[kStateCurrentModifiers] unsignedIntegerValue];
			currentModifiers ^= modifier;
			internalState[kStateCurrentModifiers] = @(currentModifiers);
			[self inspectorSetModifiers];
			[self inspectorSetModifierMatch];
			[self updateWindow];
		}
	}
	else if (interactionHandler != nil) {
			// Allow the interaction handler to deal with this
		NSDictionary *messageDictionary = @{kMessageNameKey: kMessageClick,
										   kMessageArgumentKey: @(keyCode)};
		[interactionHandler handleMessage:messageDictionary];
	}
	else if (handleClickAsDoubleClick) {
		[self messageDoubleClick:keyCode];
	}
	else {
		[self setSelectedKey:keyCode];
	}
}

- (void)messageDoubleClick:(int)keyCode
{
	if (interactionHandler != nil) {
			// We're in the midst of an interaction, so we can't start a new one
		return;
	}
	else if ([LayoutInfo getKeyType:keyCode] == kModifierKeyType) {
			// Double-clicking a modifier key should be treated as two clicks
		[self messageClick:keyCode];
		return;
	}
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:self, kKeyDocument,
                                      internalState[kStateCurrentKeyboard], kKeyKeyboardID,
                                      @(keyCode), kKeyKeyCode,
                                      internalState[kStateCurrentModifiers], kKeyModifiers,
                                      internalState[kStateCurrentState], kKeyState, nil];
	DoubleClickHandler *handler = [[DoubleClickHandler alloc] initWithData:dataDict
															keyboardLayout:self.keyboardLayout
																	window:[keyboardView window]];
    [handler setCompletionTarget:self];
	[handler startDoubleClick];
    interactionHandler = handler;
}

- (void)messageDragText:(NSString *)draggedText toKey:(int)keyCode
{
    // Handle drop of text onto a key
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:self, kKeyDocument,
                                      internalState[kStateCurrentKeyboard], kKeyKeyboardID,
                                      @(keyCode), kKeyKeyCode,
                                      internalState[kStateCurrentModifiers], kKeyModifiers,
                                      internalState[kStateCurrentState], kKeyState, nil];
	DragTextHandler *handler = [[DragTextHandler alloc] initWithData:dataDict
															dragText:draggedText
															  window:[keyboardView window]];
    [handler setCompletionTarget:self];
	[handler startDrag];
	interactionHandler = handler;
}

- (void)messageEditPaneClosed
{
	UkeleleView *ukeleleView = [keyboardView documentView];
	[[ukeleleView window] makeFirstResponder:ukeleleView];
}

- (void)messageScaleChanged:(CGFloat)newScale
{
	internalState[kStateCurrentScale] = @(newScale);
	[self setViewScaleComboBox];
}

- (void)messageScaleCompleted
{
		// Tell the font panel what font we have
	UkeleleView *ukeleleView = [keyboardView documentView];
	NSDictionary *largeAttributes = [ukeleleView largeAttributes];
	NSFont *largeFont = largeAttributes[NSFontAttributeName];
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	[fontManager setSelectedFont:largeFont isMultiple:NO];
    [self calculateSize];
    [self setViewScaleComboBox];
	[self updateWindow];
}

#pragma mark Action routines

- (void)changeOutputForKey:(NSDictionary *)keyDataDict to:(NSString *)newOutput usingBaseMap:(BOOL)usingBaseMap
{
		// Check whether the output is actually different
	NSString *oldOutput = [self.keyboardLayout getCharOutput:keyDataDict isDead:nil nextState:nil];
	if (![oldOutput isEqualToString:newOutput]) {
		[self.keyboardLayout changeOutputForKey:keyDataDict to:newOutput usingBaseMap:usingBaseMap];
		[self updateWindow];
	}
}

- (void)changeTerminatorForState:(NSString *)stateName to:(NSString *)newTerminator
{
		// Check whether the terminator is actually different
	NSString *oldTeminator = [self.keyboardLayout getTerminatorForState:stateName];
	if (![oldTeminator isEqualToString:newTerminator]) {
		[self.keyboardLayout changeTerminatorForState:stateName to:newTerminator];
		[self updateWindow];
	}
}

- (void)makeKeyDeadKey:(NSDictionary *)keyDataDict state:(NSString *)nextState
{
	[self.keyboardLayout makeKeyDeadKey:keyDataDict state:nextState];
	[self updateWindow];
}

- (void)makeDeadKeyOutput:(NSDictionary *)keyDataDict output:(NSString *)newOutput
{
	[self.keyboardLayout makeDeadKeyOutput:keyDataDict output:newOutput];
	[self updateWindow];
}

- (void)unlinkKeyWithKeyCode:(NSInteger)keyCode andModifiers:(NSUInteger)modifierCombination
{
	NSDictionary *keyDataDict = @{kKeyKeyboardID: internalState[kStateCurrentKeyboard],
							   kKeyKeyCode: @(keyCode), kKeyModifiers: @(modifierCombination)};
	if (![self.keyboardLayout isActionElement:keyDataDict]) {
			// It's not an action element, so we can't unlink
		NSString *messageText = NSLocalizedStringFromTable(@"The key you specified is not linked, so cannot be unlinked", @"dialogs", @"Tell the user why it cannot be unlinked");
		NSString *infoText = NSLocalizedStringFromTable(@"A key may be not be linked because it only ever produces one output (e.g. the space bar), or because it never produces any output (e.g. in an empty keyboard layout)", @"dialogs", @"Explain what may produce a key not linked");
		NSAssert(documentAlert == nil, @"Starting an alert when one already exists");
		documentAlert = [[NSAlert alloc] init];
		[documentAlert setAlertStyle:NSInformationalAlertStyle];
		[documentAlert setMessageText:messageText];
		[documentAlert setInformativeText:infoText];
		[documentAlert beginSheetModalForWindow:ukeleleWindow
								  modalDelegate:self
								 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
									contextInfo:nil];
		return;
	}
	[self doUnlinkKey:keyDataDict];
}

- (void)doUnlinkKey:(NSDictionary *)keyDataDict
{
	NSString *actionName = [_keyboardLayout actionNameForKey:keyDataDict];
	[self.keyboardLayout unlinkKey:keyDataDict];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] doRelinkKey:keyDataDict originalAction:actionName];
	[undoManager setActionName:@"Unlink key"];
	[self updateWindow];
}

- (void)doRelinkKey:(NSDictionary *)keyDataDict originalAction:(NSString *)actionName
{
	[self.keyboardLayout relinkKey:keyDataDict actionName:actionName];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] doUnlinkKey:keyDataDict];
	[undoManager setActionName:@"Unlink key"];
	[self updateWindow];
}

- (void)swapKeyWithCode:(NSInteger)keyCode1 andKeyWithCode:(NSInteger)keyCode2 {
	[self.keyboardLayout swapKeyCode:keyCode1 withKeyCode:keyCode2];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] swapKeyWithCode:keyCode1 andKeyWithCode:keyCode2];
	[undoManager setActionName:@"Swap keys"];
	[self updateWindow];
}

- (void)doCutKey:(NSInteger)keyCode {
	[self.keyboardLayout cutKeyCode:keyCode];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] undoCutKey:keyCode];
	[undoManager setActionName:@"Cut key"];
	[self updateWindow];
}

- (void)undoCutKey:(NSInteger)keyCode {
	[self.keyboardLayout undoCutKeyCode:keyCode];
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] doCutKey:keyCode];
	[undoManager setActionName:@"Cut key"];
	[self updateWindow];
}

- (void)doCopyKey:(NSInteger)keyCode {
	[self.keyboardLayout copyKeyCode:keyCode];
}

- (void)doPasteKey:(NSInteger)keyCode {
	[self.keyboardLayout pasteKeyCode:keyCode];
}

#pragma mark Delegate methods

- (void)documentDidChange {
	[self updateWindow];
}

- (NSMenu *)contextualMenuForData:(NSDictionary *)dataDict {
	NSMenu *theMenu = nil;
	NSInteger keyCode = [dataDict[kKeyKeyCode] integerValue];
	unsigned int keyType = [LayoutInfo getKeyType:keyCode];
	if (keyType == kModifierKeyType) {
			// Modifier key: No menu
	}
	else if (keyType == kOrdinaryKeyType || keyType == kSpecialKeyType) {
			// Ordinary or special key
		NSDictionary *keyData = @{kKeyKeyboardID: internalState[kStateCurrentKeyboard],
							kKeyKeyCode: @(keyCode),
							kKeyModifiers: internalState[kStateCurrentModifiers],
							kKeyState: internalState[kStateCurrentState]};
		BOOL deadKey = [self.keyboardLayout isDeadKey:keyData];
		if (deadKey) {
				// Contextual menu for a dead key
			theMenu = [self deadKeyContextualMenu];
		}
		else {
				// Contextual menu for a non-dead key
			theMenu = [self nonDeadKeyContextualMenu];
		}
			// Enable menu items
		for (NSMenuItem *menuItem in [theMenu itemArray]) {
			[menuItem setEnabled:[self validateUserInterfaceItem:menuItem]];
		}
	}
	return theMenu;
}

#pragma mark === Modifiers tab ===

#pragma mark Setup

- (void)setupDefaultIndex:(UkeleleKeyboardObject *)keyboardObject
{
	NSMenu *indexMenu = [defaultIndexButton menu];
	[indexMenu removeAllItems];
	NSArray *modifierIndices = [keyboardObject getModifierIndices];
	for (NSNumber *theIndex in modifierIndices) {
		[indexMenu addItemWithTitle:[NSString stringWithFormat:@"%@", theIndex] action:nil keyEquivalent:@""];
	}
	NSUInteger defaultIndex = [keyboardObject getDefaultModifierIndex];
	[defaultIndexButton selectItemWithTitle:[NSString stringWithFormat:@"%d", (int)defaultIndex]];
}

- (void)setupDataSource
{
	[modifiersDataSource setKeyboard:_keyboardLayout];
	if ([modifiersTableView dataSource] != modifiersDataSource) {
		[modifiersTableView setDataSource:modifiersDataSource];
	}
	else {
		[modifiersTableView reloadData];
	}
	[self setupDefaultIndex:_keyboardLayout];
}

- (void)updateModifiers
{
	[modifiersDataSource updateKeyboard];
	[modifiersTableView reloadData];
	[self setupDefaultIndex:_keyboardLayout];
    [simplifyModifiersButton setEnabled:![_keyboardLayout hasSimplifiedModifiers]];
}

#pragma mark User actions

- (IBAction)doubleClickRow:(id)sender
{
	NSInteger selectedRow = [modifiersTableView selectedRow];
    if (selectedRow < 0) {
        return;
    }
    ModifiersInfo *modifiersInfo = internalState[kStateModifiersInfo];
    if (modifiersInfo == nil) {
        modifiersInfo = [[ModifiersInfo alloc] init];
        internalState[kStateModifiersInfo] = modifiersInfo;
    }
	[modifiersInfo setShiftValue:[modifiersDataSource modifierValueForRow:selectedRow column:kLabelShift]];
	[modifiersInfo setCapsLockValue:[modifiersDataSource modifierValueForRow:selectedRow column:kLabelCapsLock]];
	[modifiersInfo setOptionValue:[modifiersDataSource modifierValueForRow:selectedRow column:kLabelOption]];
	[modifiersInfo setCommandValue:[modifiersDataSource modifierValueForRow:selectedRow column:kLabelCommand]];
	[modifiersInfo setControlValue:[modifiersDataSource modifierValueForRow:selectedRow column:kLabelControl]];
    if ([_keyboardLayout hasSimplifiedModifiers]) {
        modifiersSheet = [ModifiersSheet simplifiedModifiersSheet:modifiersInfo];
        [modifiersSheet beginSimplifiedModifiersSheetWithCallback:^(ModifiersInfo *newModifiersInfo) {
			[self acceptEditModifiers:newModifiersInfo];
		}
															isNew:NO
												   canBeSameIndex:NO
														forWindow:ukeleleWindow];
    }
    else {
        modifiersSheet = [ModifiersSheet modifiersSheet:modifiersInfo];
        [modifiersSheet beginModifiersSheetWithCallback:^(ModifiersInfo *newModifiersInfo) {
			[self acceptEditModifiers:newModifiersInfo];
		}
                                      isNew:NO
                             canBeSameIndex:NO
                                  forWindow:ukeleleWindow];
    }
}

- (IBAction)setDefaultIndex:(id)sender
{
	NSUInteger newIndex = [[[defaultIndexButton selectedItem] title] integerValue];
	if (newIndex != [_keyboardLayout getDefaultModifierIndex]) {
		[_keyboardLayout setDefaultModifierIndex:newIndex];
		[modifiersDataSource setKeyboard:_keyboardLayout];
		[modifiersTableView reloadData];
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[removeModifiersButton setEnabled:([modifiersTableView selectedRow] >= 0)];
}

- (IBAction)addModifiers:(id)sender
{
	NSInteger selectedRow = [modifiersTableView selectedRow];
    ModifiersInfo *modifiersInfo = internalState[kStateModifiersInfo];
    if (modifiersInfo == nil) {
        modifiersInfo = [[ModifiersInfo alloc] init];
        internalState[kStateModifiersInfo] = modifiersInfo;
    }
	if (selectedRow != -1) {
		[modifiersInfo setExistingOrNewValue:kModifiersSameIndex];
	}
	else {
		[modifiersInfo setExistingOrNewValue:kModifiersNewIndex];
	}
    if ([self.keyboardLayout hasSimplifiedModifiers]) {
        modifiersSheet = [ModifiersSheet simplifiedModifiersSheet:modifiersInfo];
        [modifiersSheet beginSimplifiedModifiersSheetWithCallback:^(ModifiersInfo *newModifiersInfo) {
			[self acceptNewModifiers:newModifiersInfo];
		}
                                                isNew:YES
                                       canBeSameIndex:(selectedRow != -1)
                                            forWindow:ukeleleWindow];
    }
    else {
        modifiersSheet = [ModifiersSheet modifiersSheet:modifiersInfo];
        [modifiersSheet beginModifiersSheetWithCallback:^(ModifiersInfo *newModifiersInfo) {
			[self acceptNewModifiers:newModifiersInfo];
		}
                                      isNew:YES
                             canBeSameIndex:(selectedRow != -1)
                                  forWindow:ukeleleWindow];
    }
}

- (IBAction)removeModifiers:(id)sender
{
	NSInteger selectedRow = [modifiersTableView selectedRow];
	NSAssert(selectedRow != -1, @"No selected row to delete");
	NSInteger selectedIndex = [modifiersDataSource indexForRow:selectedRow];
	NSInteger selectedSubindex = [modifiersDataSource subindexForRow:selectedRow];
	if ([_keyboardLayout keyMapSelectHasOneModifierCombination:selectedIndex]) {
        // Deleting a whole map
		if (selectedIndex == [_keyboardLayout getDefaultModifierIndex]) {
            // Deleting the map with default index
			NSArray *modifierIndices = [_keyboardLayout getModifierIndices];
			NSMutableArray *menuItems = [NSMutableArray arrayWithCapacity:[modifierIndices count]];
			for (NSNumber *modIndex in modifierIndices) {
				if ([modIndex integerValue] != selectedIndex) {
					[menuItems addObject:[NSString stringWithFormat:@"%@", modIndex]];
				}
			}
			NSString *dialogText =
            NSLocalizedStringFromTable(@"You are deleting the modifier set with the default index. Please select a new default index.",
                                       @"dialogs", @"Choose new default index");
            if (!askFromList) {
                askFromList = [AskFromList askFromList];
            }
			[askFromList beginAskFromListWithText:dialogText
                                         withMenu:menuItems
                                        forWindow:ukeleleWindow
										 callBack:^(NSString *newDefault) {
											 if (newDefault == nil) {	// User cancelled
												 return;
											 }
											 NSUndoManager *undoManager = [self undoManager];
											 [undoManager beginUndoGrouping];
												 // Change the default index
											 NSInteger deleteIndex = [modifiersDataSource indexForRow:[modifiersTableView selectedRow]];
											 NSInteger defaultIndex = [newDefault integerValue];
											 if (deleteIndex < defaultIndex) {
												 defaultIndex--;
											 }
											 [_keyboardLayout setDefaultModifierIndex:defaultIndex];
												 // Delete the row
											 [_keyboardLayout removeKeyMap:deleteIndex
															  forKeyboard:[[KeyboardEnvironment instance] currentKeyboardID]
														  newDefaultIndex:defaultIndex];
											 [undoManager endUndoGrouping];
											 [self updateModifiers];
										 }];
		}
		else {
            // Delete the row
			NSInteger newDefaultIndex = [_keyboardLayout getDefaultModifierIndex];
			if (newDefaultIndex > selectedIndex) {
				newDefaultIndex--;
			}
			[_keyboardLayout removeKeyMap:selectedIndex
							  forKeyboard:[[KeyboardEnvironment instance] currentKeyboardID]
						  newDefaultIndex:newDefaultIndex];
			[self updateModifiers];
		}
	}
	else {
        // Do the deletion
		[_keyboardLayout removeModifierElement:[[KeyboardEnvironment instance] currentKeyboardID]
										 index:selectedIndex
									  subindex:selectedSubindex];
        [self updateModifiers];
	}
}

- (IBAction)simplifyModifiers:(id)sender
{
    [_keyboardLayout simplifyModifiers];
}

- (IBAction)unlinkModifierSet:(id)sender
{
	if ([kTabNameKeyboard isEqualToString:[[tabView selectedTabViewItem] identifier]]) {
			// We're on the keyboard tab, so invoke unlinking a set
		[self unlinkModifierCombination];
		return;
	}
	NSInteger selectedRow = [modifiersTableView selectedRow];
	NSAssert(selectedRow != -1, @"No selected row for unlinking");
	NSInteger selectedIndex = [modifiersDataSource indexForRow:selectedRow];
	NSInteger keyboardID = [internalState[kStateCurrentKeyboard] integerValue];
	NSUInteger modifiers = [_keyboardLayout modifiersForIndex:selectedIndex forKeyboard:keyboardID];
	[_keyboardLayout unlinkModifierSet:modifiers forKeyboard:keyboardID];
}

#pragma mark Callbacks

- (void)acceptEditModifiers:(ModifiersInfo *)newModifiersInfo
{
	if (newModifiersInfo == nil) {
        // User cancelled
		return;
	}
	if (![newModifiersInfo modifiersAreEqualTo:internalState[kStateModifiersInfo]]) {
        // New modifiers
        internalState[kStateModifiersInfo] = newModifiersInfo;
		NSInteger selectedRow = [modifiersTableView selectedRow];
		NSInteger index = [modifiersDataSource indexForRow:selectedRow];
        [newModifiersInfo setKeyMapIndex:index];
		NSInteger subindex = [modifiersDataSource subindexForRow:selectedRow];
        [newModifiersInfo setKeyMapSubindex:subindex];
		[_keyboardLayout changeModifiersIndex:index
									 subIndex:subindex
										shift:[newModifiersInfo shiftValue]
									   option:[newModifiersInfo optionValue]
									 capsLock:[newModifiersInfo capsLockValue]
									  command:[newModifiersInfo commandValue]
									  control:[newModifiersInfo controlValue]];
	}
	[self updateModifiers];
}

- (void)acceptNewModifiers:(ModifiersInfo *)newModifiersInfo
{
	if (newModifiersInfo == nil) {
        // User cancelled
		return;
	}
	NSInteger selectedRow = [modifiersTableView selectedRow];
	BOOL newIndex = selectedRow == -1 || [newModifiersInfo existingOrNewValue] == kModifiersNewIndex;
	if (newIndex) {
        // Creating a new modifier map, so have to ask what type
        [newModifiersInfo setKeyMapIndex:-1];
        [newModifiersInfo setKeyMapSubindex:0];
        internalState[kStateModifiersInfo] = newModifiersInfo;
        if (!askNewKeyMap) {
            askNewKeyMap = [AskNewKeyMap askNewKeyMap];
        }
		NSString *infoString = NSLocalizedStringFromTable(@"Choose what kind of key map to create:", @"dialogs",
														  @"Ask user for key map type");
		NSArray *modifierIndices = [self.keyboardLayout getModifierIndices];
		NSMutableArray *keyMaps = [NSMutableArray arrayWithCapacity:[modifierIndices count]];
		for (NSNumber *theIndex in modifierIndices) {
			[keyMaps addObject:[NSString stringWithFormat:@"%@", theIndex]];
		}
		[askNewKeyMap beginNewKeyMapWithText:infoString
								 withKeyMaps:keyMaps
								   forWindow:ukeleleWindow
									callBack:^(NewKeyMapInfo *mapTypeInfo) {
										[self acceptNewKeyMapType:mapTypeInfo];
									}];
		return;
	}
    // Adding to an existing modifier map
	NSInteger rowIndex = [modifiersDataSource indexForRow:selectedRow];
	NSInteger subindex = [modifiersDataSource subindexForRow:selectedRow];
	[self.keyboardLayout addModifierElement:[[KeyboardEnvironment instance] currentKeyboardID]
								 index:rowIndex
							  subIndex:subindex
								 shift:[newModifiersInfo shiftValue]
							  capsLock:[newModifiersInfo capsLockValue]
								option:[newModifiersInfo optionValue]
							   command:[newModifiersInfo commandValue]
							   control:[newModifiersInfo controlValue]];
    internalState[kStateModifiersInfo] = newModifiersInfo;
	[self modifierMapDidChange];
}

- (void)acceptNewKeyMapType:(NewKeyMapInfo *)mapTypeInfo
{
	if (mapTypeInfo == nil) {
        // User cancelled
		return;
	}
	NSInteger keyMapType = [mapTypeInfo keyMapTypeSelection];
    NSNumber *keyboardID = internalState[kStateCurrentKeyboard];
    if (keyMapType == kNewKeyMapEmpty) {
        // Create an empty key map
        [self.keyboardLayout addEmptyKeyMapForKeyboard:[keyboardID integerValue]
                                    withModifiers:internalState[kStateModifiersInfo]];
    }
    else if (keyMapType == kNewKeyMapStandard) {
        // Create a new key map of the specified standard type
        NSInteger standardType = [mapTypeInfo standardKeyMapSelection];
        switch (standardType) {
            case kStandardKeyMapqwerty:
                standardType = kStandardKeyboardQWERTYLowerCase;
                break;
                
            case kStandardKeyMapQWERTY:
                standardType = kStandardKeyboardQWERTYUpperCase;
                break;
                
            case kStandardKeyMapDvorackLower:
                standardType = kStandardKeyboardDvorakLowerCase;
                break;
                
            case kStandardKeyMapDvorackUpper:
                standardType = kStandardKeyboardDvorakUpperCase;
                break;
                
            case kStandardKeyMapazerty:
                standardType = kStandardKeyboardAZERTYLowerCase;
                break;
                
            case kStandardKeyMapAZERTY:
                standardType = kStandardKeyboardAZERTYUpperCase;
                break;
                
            case kStandardKeyMapqwertz:
                standardType = kStandardKeyboardQWERTZLowerCase;
                break;
                
            case kStandardKeyMapQWERTZ:
                standardType = kStandardKeyboardQWERTZUpperCase;
                break;
        }
        [self.keyboardLayout addStandardKeyMap:standardType
                              forKeyboard:[keyboardID integerValue]
                            withModifiers:internalState[kStateModifiersInfo]];
    }
    else if (keyMapType == kNewKeyMapCopy) {
        // Create a copy of the new key map
        NSInteger mapToCopyIndex = [mapTypeInfo copyKeyMapSelection];
        BOOL unlinkMap = [mapTypeInfo isUnlinked];
        [self.keyboardLayout addCopyKeyMap:mapToCopyIndex
                               unlink:unlinkMap
                          forKeyboard:[keyboardID integerValue]
                        withModifiers:internalState[kStateModifiersInfo]];
    }
    else {
        // Some unknown value!
        NSLog(@"Received unknown map type %ld to create a new key map", (long)keyMapType);
        return;
    }
}

- (void)acceptReplacementDefaultIndex:(NSString *)newDefault
{
	if (newDefault == nil) {	// User cancelled
		return;
	}
	NSUndoManager *undoManager = [self undoManager];
	[undoManager beginUndoGrouping];
    // Change the default index
	NSInteger deleteIndex = [modifiersDataSource indexForRow:[modifiersTableView selectedRow]];
	NSInteger defaultIndex = [newDefault integerValue];
	if (deleteIndex < defaultIndex) {
		defaultIndex--;
	}
	[_keyboardLayout setDefaultModifierIndex:defaultIndex];
    // Delete the row
	[_keyboardLayout removeKeyMap:deleteIndex
					 forKeyboard:[[KeyboardEnvironment instance] currentKeyboardID]
				 newDefaultIndex:defaultIndex];
	[undoManager endUndoGrouping];
	[self updateModifiers];
}

- (void)modifierMapDidChange
{
    // Delegate method to indicate that the modifier map has changed
    [modifiersDataSource updateKeyboard];
    [modifiersTableView reloadData];
    [self setupDefaultIndex:_keyboardLayout];
    [simplifyModifiersButton setEnabled:![_keyboardLayout hasSimplifiedModifiers]];
    [self updateWindow];
}

#pragma mark Action routines

- (void)setDefaultModifierIndex:(NSUInteger)defaultIndex
{
	[_keyboardLayout setDefaultModifierIndex:defaultIndex];
	[self updateWindow];
    [self setupDataSource];
}

- (void)changeModifiersIndex:(NSInteger)index
					subIndex:(NSInteger)subindex
					   shift:(NSInteger)newShift
					  option:(NSInteger)newOption
					capsLock:(NSInteger)newCapsLock
					 command:(NSInteger)newCommand
					 control:(NSInteger)newControl
{
	[_keyboardLayout changeModifiersIndex:index
								subIndex:subindex
								   shift:newShift
								  option:newOption
								capsLock:newCapsLock
								 command:newCommand
								 control:newControl];
	[self updateWindow];
}

- (void)removeModifierElement:(NSInteger)keyboardID
						index:(NSInteger)index
					 subindex:(NSInteger)subindex
{
	[_keyboardLayout removeModifierElement:keyboardID index:index subindex:subindex];
	[self updateWindow];
}

- (void)addModifierElement:(NSInteger)keyboardID
					 index:(NSInteger)index
				  subIndex:(NSInteger)subindex
					 shift:(NSInteger)newShift
				  capsLock:(NSInteger)newCapsLock
					option:(NSInteger)newOption
				   command:(NSInteger)newCommand
				   control:(NSInteger)newControl
{
	[_keyboardLayout addModifierElement:keyboardID
								 index:index
							  subIndex:subindex
								 shift:newShift
							  capsLock:newCapsLock
								option:newOption
							   command:newCommand
							   control:newControl];
	[self updateWindow];
}

- (void)removeKeyMap:(NSInteger)index forKeyboard:(NSInteger)keyboardID newDefaultIndex:(NSInteger)newDefaultIndex
{
	[_keyboardLayout removeKeyMap:index forKeyboard:keyboardID newDefaultIndex:newDefaultIndex];
	[self updateWindow];
}

- (void)replaceKeyMap:(NSInteger)index
		  forKeyboard:(NSInteger)keyboardID
		 defaultIndex:(NSInteger)defaultIndex
		 keyMapSelect:(void *)keyMapSelect
	   keyMapElements:(void *)deletedKeyMapElements
{
	[_keyboardLayout replaceKeyMap:index
                      forKeyboard:keyboardID
					 defaultIndex:defaultIndex
					 keyMapSelect:keyMapSelect
				   keyMapElements:deletedKeyMapElements];
	[self updateWindow];
}

#pragma mark === Comments tab ===

- (void)addCreationComment {
	[self.keyboardLayout addCreationComment];
}

- (IBAction)addComment:(id)sender
{
    if (commentChanged) {
		[self saveUnsavedComment];
	}
    XMLCommentHolderObject *commentHolder = [self.keyboardLayout currentCommentHolder];
	if (!commentHolder) {
		commentHolder = [self.keyboardLayout documentCommentHolder];
	}
	[self addComment:@"" toHolder:commentHolder];
	[self updateCommentFields];
}

- (IBAction)removeComment:(id)sender
{
    XMLCommentHolderObject *commentHolder = [self.keyboardLayout currentCommentHolder];
	NSString *commentText = [self.keyboardLayout currentComment];
	[self removeComment:commentText fromHolder:commentHolder];
	if ([self.keyboardLayout currentComment]) {
			// There is a new current comment
		[self updateCommentFields];
	}
	else {
			// No more comments left
		[self clearCommentFields];
	}
}

- (IBAction)firstComment:(id)sender
{
    if (commentChanged) {
		[self saveUnsavedComment];
	}
	NSString *commentText = [self.keyboardLayout firstComment];
	[commentPane setString:commentText];
	[self updateCommentFields];
}

- (IBAction)previousComment:(id)sender
{
    if (commentChanged) {
		[self saveUnsavedComment];
	}
	NSString *commentText = [self.keyboardLayout previousComment];
	[commentPane setString:commentText];
	[self updateCommentFields];
}

- (IBAction)nextComment:(id)sender
{
    if (commentChanged) {
		[self saveUnsavedComment];
	}
	NSString *commentText = [self.keyboardLayout nextComment];
	[commentPane setString:commentText];
	[self updateCommentFields];
}

- (IBAction)lastComment:(id)sender
{
    if (commentChanged) {
		[self saveUnsavedComment];
	}
	NSString *commentText = [self.keyboardLayout lastComment];
	[commentPane setString:commentText];
	[self updateCommentFields];
}

- (void)updateCommentFields {
	if (commentChanged) {
			// Save the changed comment
		commentChanged = NO;
	}
		// Set the comment text pane
	NSString *commentText = [self.keyboardLayout currentComment];
	if (commentText) {
		[commentPane setString:commentText];
	}
		// Set the XML statement pane
	NSString *holderText = [self.keyboardLayout currentHolderText];
	if (holderText) {
		[commentBindingPane setStringValue:holderText];
	}
		// Set the button states
	if ([self.keyboardLayout isFirstComment]) {
		[firstCommentButton setEnabled:NO];
		[previousCommentButton setEnabled:NO];
	}
	else {
		[firstCommentButton setEnabled:YES];
		[previousCommentButton setEnabled:YES];
	}
	if ([self.keyboardLayout isLastComment]) {
		[lastCommentButton setEnabled:NO];
		[nextCommentButton setEnabled:NO];
	}
	else {
		[lastCommentButton setEnabled:YES];
		[nextCommentButton setEnabled:YES];
	}
	if ([self.keyboardLayout isEditableComment]) {
		[removeCommentButton setEnabled:YES];
		[commentPane setEditable:YES];
	}
	else {
		[removeCommentButton setEnabled:NO];
		[commentPane setEditable:NO];
	}
}

- (void)clearCommentFields {
	[commentPane setString:@""];
	[commentBindingPane setStringValue:@""];
	[firstCommentButton setEnabled:NO];
	[previousCommentButton setEnabled:NO];
	[nextCommentButton setEnabled:NO];
	[lastCommentButton setEnabled:NO];
	[removeCommentButton setEnabled:NO];
}

- (void)saveUnsavedComment {
	NSString *existingComment = [self.keyboardLayout currentComment];
	NSString *commentPaneContents = [[commentPane string] copy];
	XMLCommentHolderObject *currentHolder = [self.keyboardLayout currentCommentHolder];
	if (![commentPaneContents isEqualToString:existingComment]) {
		[self changeCommentTextFrom:existingComment to:commentPaneContents forHolder:currentHolder];
	}
	commentChanged = NO;
}

#pragma mark Delegate methods

- (void)textDidChange:(NSNotification *)notification {
	commentChanged = YES;
}

#pragma mark Undo routines

- (void)changeCommentTextFrom:(NSString *)oldText
						   to:(NSString *)newText
					forHolder:(XMLCommentHolderObject *)commentHolder {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] changeCommentTextFrom:newText to:oldText forHolder:commentHolder];
	[undoManager setActionName:@"Change comment"];
	[self.keyboardLayout changeCommentText:oldText to:newText forHolder:commentHolder];
	[self updateCommentFields];
}

- (void)addComment:(NSString *)commentText toHolder:(XMLCommentHolderObject *)commentHolder {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] removeComment:commentText fromHolder:commentHolder];
	[undoManager setActionName:[undoManager isUndoing] ? @"Remove comment" : @"Add comment"];
	[self.keyboardLayout addComment:commentText toHolder:commentHolder];
	[self updateCommentFields];
}

- (void)removeComment:(NSString *)commentText fromHolder:(XMLCommentHolderObject *)commentHolder {
	NSUndoManager *undoManager = [self undoManager];
	[[undoManager prepareWithInvocationTarget:self] addComment:commentText toHolder:commentHolder];
	[undoManager setActionName:[undoManager isUndoing] ? @"Add comment" : @"Remove comment"];
	[self.keyboardLayout removeComment:commentText fromHolder:commentHolder];
	[self updateCommentFields];
}

@end

//
//  UkeleleAppDelegate.m
//  Ukelele 3
//
//  Created by John Brownie on 26/08/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "UkeleleAppDelegate.h"
#import "UkeleleConstants.h"
#import "UkeleleConstantStrings.h"
#import "UKKeyboardDocument.h"
#import "ColourTheme.h"
#import "ToolboxController.h"
#import "InspectorWindowController.h"
#import "UnicodeTable.h"
#import "UkelelePreferenceController.h"
#import "KeyboardInstallerTool.h"
#import "Common.h"
#include <ServiceManagement/ServiceManagement.h>

@interface UkeleleAppDelegate () {
	AuthorizationRef _authRef;
}

@end

@implementation UkeleleAppDelegate

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
//	[NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^(NSEvent *inEvent){
//		NSString *characters = [inEvent characters];
//		NSString *charsWithoutModifiers = [inEvent charactersIgnoringModifiers];
//		NSUInteger modifiers = [NSEvent modifierFlags];
//		NSLog(@"Characters '%@', without modifiers '%@', modifiers %lx", characters, charsWithoutModifiers, modifiers);
//		return inEvent;
//	}];
    
    return self;
}

static NSDictionary *defaultValues() {
	static NSDictionary *dict = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		ColourTheme *defaultTheme = [ColourTheme defaultColourTheme];
		NSData *defaultThemeData = [NSKeyedArchiver archivedDataWithRootObject:defaultTheme];
		ColourTheme *printTheme = [ColourTheme defaultPrintTheme];
		NSData *printThemeData = [NSKeyedArchiver archivedDataWithRootObject:printTheme];
		NSDictionary *colourThemes = @{kDefaultThemeName: defaultThemeData,
								 kPrintThemeName: printThemeData};
		dict = @{UKScaleFactor: @1.25f,
		   UKTextSize: @(kDefaultLargeFontSize),
		   UKTextFont: @"Lucida Grande",
		   UKUsesSingleClickToEdit: @NO,
		   UKDefaultLayoutID: @(gestaltUSBAndyANSIKbd),
		   UKAlwaysUsesDefaultLayout: @NO,
		   UKStateNameBase: @"Dead Key State",
		   UKDiacriticDisplayCharacter: @(UKDiacriticSpace),
		   UKUsesPopover: @YES,
		   UKTigerCompatibleBundles: @NO,
		   UKCodeNonAscii: @NO,
		   UKColourThemes: colourThemes,
		   UKColourTheme: kDefaultThemeName};
	});
	return dict;
}

- (NSError *)application:(NSApplication *)application willPresentError:(NSError *)error
{
    if ([[error domain] isEqualToString:kDomainUkelele]) {
		NSError *underlyingError = [error userInfo][NSUnderlyingErrorKey];
        return underlyingError == nil ? error : underlyingError;
    }
    return error;
}

- (IBAction)doPreferences:(id)sender {
		// Create (if necessary) and run the preference window
	UkelelePreferenceController *thePrefsController = [UkelelePreferenceController getInstance];
	[thePrefsController runPreferences];
}

- (IBAction)newBundle:(id)sender {
	NSError *theError;
	UKKeyboardDocument *theDocument = [[NSDocumentController sharedDocumentController]
										 makeUntitledDocumentOfType:(NSString *)kUTTypeBundle error:&theError];
	if (nil != theDocument) {
			// Got a document
		[[NSDocumentController sharedDocumentController] addDocument:theDocument];
		[theDocument makeWindowControllers];
		[theDocument showWindows];
	}
}

- (IBAction)newFromCurrentInput:(id)sender {
	UKKeyboardDocument *newDocument = [[UKKeyboardDocument alloc] init];
	if (newDocument) {
		[newDocument captureInputSource:self];
		NSDocumentController *documentController = [NSDocumentController sharedDocumentController];
		[documentController addDocument:newDocument];
		[newDocument makeWindowControllers];
		[newDocument showWindows];
	}
}

- (IBAction)toggleToolbox:(id)sender {
	ToolboxController *toolboxController = [ToolboxController sharedToolboxController];
	NSWindow *toolboxWindow = [toolboxController window];
	if ([toolboxWindow isVisible]) {
		[toolboxWindow close];
	}
	else {
		[toolboxController showWindow:self];
	}
}

- (IBAction)toggleStickyModifiers:(id)sender {
	ToolboxData *toolboxData = [ToolboxData sharedToolboxData];
	[toolboxData setStickyModifiers:![toolboxData stickyModifiers]];
}

- (IBAction)showHideInspector:(id)sender
{
	InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
	if ([[infoInspector window] isVisible]) {
		[[infoInspector window] orderOut:sender];
	}
	else {
		[infoInspector showWindow:sender];
	}
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
		// Register defaults
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues()];
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues()];
	
		// Set up the Unicode table
	[UnicodeTable setup];
	
		// Create our connection to the authorization system.
		//
		// If we can't create an authorization reference then the app is not going to be able
		// to do anything requiring authorization.  Generally this only happens when you launch
		// the app in some wacky, and typically unsupported, way.  In the debug build we flag that
		// with an assert.  In the release build we continue with self->_authRef as NULL, which will
		// cause all authorized operations to fail.
    
    OSStatus err = AuthorizationCreate(NULL, NULL, 0, &self->_authRef);
	AuthorizationExternalForm extForm;
    if (err == errAuthorizationSuccess) {
        err = AuthorizationMakeExternalForm(self->_authRef, &extForm);
    }
    if (err == errAuthorizationSuccess) {
        self.authorization = [[NSData alloc] initWithBytes:&extForm length:sizeof(extForm)];
    }
    assert(err == errAuthorizationSuccess);
    
		// If we successfully connected to Authorization Services, add definitions for our default
		// rights (unless they're already in the database).
    
    if (self->_authRef) {
        [Common setupAuthorizationRights:self->_authRef];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
	SEL action = [menuItem action];
	if (action == @selector(toggleStickyModifiers:)) {
		ToolboxData *toolboxData = [ToolboxData sharedToolboxData];
		[menuItem setState:[toolboxData stickyModifiers] ? NSOnState : NSOffState];
		return YES;
	}
	else if (action == @selector(toggleToolbox:)) {
		ToolboxController *toolboxController = [ToolboxController sharedToolboxController];
		NSWindow *toolboxWindow = [toolboxController window];
		if ([toolboxWindow isVisible]) {
			[menuItem setTitle:@"Hide Toolbox"];
		}
		else {
			[menuItem setTitle:@"Show Toolbox"];
		}
		return YES;
	}
	else if (action == @selector(showHideInspector:)) {
		InspectorWindowController *infoInspector = [InspectorWindowController getInstance];
		if ([[infoInspector window] isVisible]) {
			[menuItem setTitle:@"Hide Inspector"];
		}
		else {
			[menuItem setTitle:@"Show Inspector"];
		}
		return YES;
	}
	else if (action == @selector(removeHelperTool:))	{
			// Only enabled if it is installed
		return [self helperToolIsInstalled];
	}
	return YES;
}

- (IBAction)removeHelperTool:(id)sender {
	NSAssert([self helperToolIsInstalled], @"Helper tool must be installed before removal");
	AuthorizationRef removeAuth;
	AuthorizationItem myItem;
	myItem.name = kSMRightModifySystemDaemons;
	myItem.valueLength = 0;
	myItem.value = NULL;
	myItem.flags = 0;
	AuthorizationItemSet myItems;
	myItems.count = 1;
	myItems.items = &myItem;
    OSStatus err = AuthorizationCreate(&myItems, NULL, kAuthorizationFlagExtendRights | kAuthorizationFlagInteractionAllowed, &removeAuth);
	NSAssert(err == errAuthorizationSuccess, @"Could not create authorization");
	CFErrorRef error;
	Boolean success = SMJobRemove(kSMDomainSystemLaunchd, (__bridge CFStringRef)kHelperToolMachServiceName, removeAuth, true, &error);
	if (!success) {
		[NSApp presentError:(__bridge NSError *)error];
	}
	err = AuthorizationFree(removeAuth, kAuthorizationFlagDestroyRights);
	NSAssert(err == errAuthorizationSuccess, @"Could not destroy authorisation");
}

- (BOOL)installHelperTool {
	CFErrorRef error;
	Boolean success = SMJobBless(kSMDomainSystemLaunchd, (__bridge CFStringRef)kHelperToolMachServiceName, self->_authRef, &error);
	if (!success) {
			// Log the error
		[NSApp presentError:(__bridge NSError *)(error)];
	}
	return success;
}

- (BOOL)helperToolIsInstalled {
	CFDictionaryRef toolDict = SMJobCopyDictionary(kSMDomainSystemLaunchd, (__bridge CFStringRef)kHelperToolMachServiceName);
	return toolDict != NULL;
}

- (void)connectToHelperTool
// Ensures that we're connected to our helper tool.
{
    assert([NSThread isMainThread]);
    if (self.helperToolConnection == nil) {
        self.helperToolConnection = [[NSXPCConnection alloc] initWithMachServiceName:kHelperToolMachServiceName options:NSXPCConnectionPrivileged];
        self.helperToolConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(KeyboardInstallerProtocol)];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
			// We can ignore the retain cycle warning because a) the retain taken by the
			// invalidation handler block is released by us setting it to nil when the block
			// actually runs, and b) the retain taken by the block passed to -addOperationWithBlock:
			// will be released when that operation completes and the operation itself is deallocated
			// (notably self does not have a reference to the NSBlockOperation).
        self.helperToolConnection.invalidationHandler = ^{
				// If the connection gets invalidated then, on the main thread, nil out our
				// reference to it.  This ensures that we attempt to rebuild it the next time around.
            self.helperToolConnection.invalidationHandler = nil;
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                self.helperToolConnection = nil;
            }];
        };
#pragma clang diagnostic pop
        [self.helperToolConnection resume];
    }
}

- (void)connectAndExecuteCommandBlock:(void(^)(NSError *))commandBlock
// Connects to the helper tool and then executes the supplied command block on the
// main thread, passing it an error indicating if the connection was successful.
{
    assert([NSThread isMainThread]);
    
		// Ensure that there's a helper tool connection in place.
    
    [self connectToHelperTool];
	
		// Run the command block.  Note that we never error in this case because, if there is
		// an error connecting to the helper tool, it will be delivered to the error handler
		// passed to -remoteObjectProxyWithErrorHandler:.  However, I maintain the possibility
		// of an error here to allow for future expansion.
	
    commandBlock(nil);
}

@end

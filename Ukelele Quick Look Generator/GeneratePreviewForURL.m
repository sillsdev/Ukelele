#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import "UkeleleKeyboardObject.h"
#import "UkeleleView.h"
#import "UkeleleConstantStrings.h"
#import "UkeleleConstants.h"

__attribute__((visibility("default"))) OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
__attribute__((visibility("default"))) void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
#pragma unused(thisInterface)
#pragma unused(contentTypeUTI)
#pragma unused(options)
		// Get the contents of the file
	NSError *error;
	NSURL *theURL = (__bridge NSURL *)url;
	NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL:theURL options:0 error:&error];
	if (fileWrapper == nil) {
		return kCFURLErrorFileDoesNotExist;
	}
	NSData *fileData = [fileWrapper regularFileContents];
	if (fileData == nil) {
		return kCFURLErrorCannotOpenFile;
	}
	if (QLPreviewRequestIsCancelled(preview)) {
		return noErr;
	}
		// Parse the file into a keyboard object
	UkeleleKeyboardObject *keyboardObject = [[UkeleleKeyboardObject alloc] initWithData:fileData withError:&error];
	if (QLPreviewRequestIsCancelled(preview)) {
		return noErr;
	}
		// Create a view
	UkeleleView *ukeleleView = [[UkeleleView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
		// Get the resource we need
	NSBundle *theBundle = [NSBundle bundleWithIdentifier:@"org.sil.Ukelele.Ukelele-Quick-Look-Generator"];
	NSURL *resourceURL = [theBundle URLForResource:@"UkeleleQLResources" withExtension:@"plist"];
	NSDictionary *resourceDict = [NSDictionary dictionaryWithContentsOfURL:resourceURL];
	NSString *idString = [NSString stringWithFormat:@"%d", UKDefaultKeyboardType];
	NSData *resourceData = resourceDict[idString];
	char *resourceBuffer = malloc([resourceData length]);
	[resourceData getBytes:resourceBuffer length:[resourceData length]];
	[ukeleleView createViewWithStream:resourceBuffer forID:UKDefaultKeyboardType withScale:1.25];
	free(resourceBuffer);
	[ukeleleView setFrameOrigin:NSZeroPoint];
	if (QLPreviewRequestIsCancelled(preview)) {
		return noErr;
	}
		// Now populate the view
	NSArray *subViews = [ukeleleView keyCapViews];
	NSMutableDictionary *keyDataDict = [NSMutableDictionary dictionary];
	keyDataDict[kKeyKeyboardID] = @(UKDefaultKeyboardType);
	keyDataDict[kKeyKeyCode] = @0;
	keyDataDict[kKeyModifiers] = @(0);
	keyDataDict[kKeyState] = @"none";
	for (KeyCapView *keyCapView in subViews) {
		NSInteger keyCode = [keyCapView keyCode];
		NSString *output;
		BOOL deadKey;
		NSString *nextState;
		keyDataDict[kKeyKeyCode] = @(keyCode);
		output = [keyboardObject getCharOutput:keyDataDict isDead:&deadKey nextState:&nextState];
		[keyCapView setOutputString:output];
		[keyCapView setDeadKey:deadKey];
	}
	[ukeleleView updateModifiers:0];
		// Finally, draw the view
	CGContextRef cgContext = QLPreviewRequestCreateContext(preview, NSSizeToCGSize([ukeleleView bounds].size), true, NULL);
	if (cgContext) {
		NSGraphicsContext *nsContext = [NSGraphicsContext graphicsContextWithCGContext:cgContext flipped:NO];
		if (nsContext) {
				// Draw the view
			NSRect theRect = [ukeleleView frame];
			[NSGraphicsContext saveGraphicsState];
			[NSGraphicsContext setCurrentContext:nsContext];
			[nsContext saveGraphicsState];
			[ukeleleView displayRectIgnoringOpacity:theRect inContext:nsContext];
			[nsContext restoreGraphicsState];
			[NSGraphicsContext restoreGraphicsState];
		}
		QLPreviewRequestFlushContext(preview, cgContext);
		CFRelease(cgContext);
	}
    // To complete your generator please implement the function GeneratePreviewForURL in GeneratePreviewForURL.c
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
#pragma unused(thisInterface)
#pragma unused(preview)
    // Implement only if supported
}

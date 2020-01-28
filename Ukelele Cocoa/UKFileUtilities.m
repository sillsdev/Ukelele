//
//  UKFileUtilities.m
//  Ukelele
//
//  Created by John Brownie on 3/1/17.
//  Copyright © 2017 John Brownie. All rights reserved.
//

#import "UKFileUtilities.h"
#include <pwd.h>

#define kLibraryKeyboardLayouts	@"file:///Library/Keyboard%20Layouts/"
#define kUserKeyboardLayouts @"file:///Users/user/Library/Keyboard%20Layouts/"
#define kUser	@"user"
#define kLibraryName	@"Library"

@implementation UKFileUtilities

+ (BOOL)isKeyboardLayoutsURL:(NSURL *)fileURL {
		// Get the components to the parent directory
	NSArray *urlComponents = [[fileURL URLByDeletingLastPathComponent] pathComponents];
		// Compare them to the /Library/Keyboard Layouts URL
	NSArray *libraryComponents = [[NSURL URLWithString:kLibraryKeyboardLayouts] pathComponents];
	if ([urlComponents count] == [libraryComponents count]) {
			// Same number of components, check each one for equality
		for (NSUInteger i = 0; i < [urlComponents count]; i++) {
			NSString *component = urlComponents[i];
			if (![component isEqualToString:libraryComponents[i]]) {
				return NO;
			}
		}
		return YES;
	}
	libraryComponents = [[NSURL URLWithString:kUserKeyboardLayouts] pathComponents];
	if ([urlComponents count] == [libraryComponents count]) {
			// Same number of components, check equality
		for (NSUInteger i = 0; i < [urlComponents count]; i++) {
			NSString *component = urlComponents[i];
			if (![component isEqualToString:libraryComponents[i]] && ![libraryComponents[i] isEqualToString:kUser]) {
				return NO;
			}
		}
		return YES;
	}
	return NO;
}

+ (BOOL)dataIsicns:(NSData *)icnsData {
	UInt32 icnsHeader;
	UInt32 icnsDataLength;
	[icnsData getBytes:&icnsHeader range:NSMakeRange(0, sizeof(UInt32))];
	[icnsData getBytes:&icnsDataLength range:NSMakeRange(sizeof(UInt32), sizeof(UInt32))];
		// Need to swap bytes on the data
	icnsHeader = CFSwapInt32(icnsHeader);
	icnsDataLength = CFSwapInt32(icnsDataLength);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfour-char-constants"
	if (icnsHeader != 'icns' || icnsDataLength != [icnsData length]) {
			// Bad icon data
		return NO;
	}
#pragma clang diagnostic pop
	return YES;
}

+ (NSURL *)userLibrary {
	long bufsize = sysconf(_SC_GETPW_R_SIZE_MAX);
	if (bufsize == -1) {
		// Can't get the right buffer size
		return nil;
	}
	NSURL *libraryURL = nil;
	char *buffer = malloc(bufsize);
	struct passwd pwd;
	struct passwd *result;
	int returnValue = getpwuid_r(getuid(), &pwd, buffer, bufsize, &result);
	if (returnValue == 0 && result != nil) {
		// Success, so read out the path
		NSString *homePath = [NSString stringWithCString:pwd.pw_dir encoding:NSUTF8StringEncoding];
		NSURL *homeURL = [NSURL fileURLWithPath:homePath];
		if (homeURL != nil) {
			libraryURL = [homeURL URLByAppendingPathComponent:kLibraryName];
		}
	}
	return libraryURL;
}

@end

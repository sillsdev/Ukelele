//
//  UKFileUtilities.m
//  Ukelele
//
//  Created by John Brownie on 3/1/17.
//  Copyright © 2017 John Brownie. All rights reserved.
//

#import "UKFileUtilities.h"

#define kLibraryKeyboardLayouts	@"file:///Library/Keyboard%20Layouts/"
#define kUserKeyboardLayouts @"file:///Users/user/Library/Keyboard%20Layouts/"
#define kUser	@"user"

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
	icnsHeader = ((icnsHeader & 0x000000ff) << 24) |
	((icnsHeader & 0x0000ff00) << 8) |
	((icnsHeader & 0x00ff0000) >> 8) |
	((icnsHeader & 0xff000000) >> 24);
	icnsDataLength = ((icnsDataLength & 0x000000ff) << 24) |
	((icnsDataLength & 0x0000ff00) << 8) |
	((icnsDataLength & 0x00ff0000) >> 8) |
	((icnsDataLength & 0xff000000) >> 24);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfour-char-constants"
	if (icnsHeader != 'icns' || icnsDataLength != [icnsData length]) {
			// Bad icon data
		return NO;
	}
#pragma clang diagnostic pop
	return YES;
}

@end

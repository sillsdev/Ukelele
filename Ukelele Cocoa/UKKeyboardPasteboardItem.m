//
//  UKKeyboardPasteboardItem.m
//  Ukelele Cocoa
//
//  Created by John Brownie on 29/05/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import "UKKeyboardPasteboardItem.h"

#define UKKeyboardPasteboardKeyboard	@"Keyboard"
#define UKKeyboardPasteboardIcon		@"Icon"
#define UKKeyboardPasteboardLanguage	@"Language"

@implementation UKKeyboardPasteboardItem

- (instancetype)init {
	self = [super init];
	if (self) {
		_keyboardLayoutFile = nil;
		_iconFile = nil;
		_languageCode = nil;
	}
	return self;
}

+ (UKKeyboardPasteboardItem *)pasteboardTypeForKeyboard:(NSURL *)keyboard icon:(NSURL *)icon language:(NSString *)language {
	UKKeyboardPasteboardItem *result = [[UKKeyboardPasteboardItem alloc] init];
	[result setKeyboardLayoutFile:keyboard];
	[result setIconFile:icon];
	[result setLanguageCode:language];
	return result;
}

- (instancetype)initWithPasteboardPropertyList:(id)propertyList ofType:(NSString *)type {
	self = [self init];
	NSURL *theKeyboard;
	if ([type isEqualToString:UKKeyboardPasteType]) {
			// Has all the items
		NSDictionary *theDict = propertyList[0];
		if (theDict) {
			theKeyboard = [NSURL URLWithString:theDict[UKKeyboardPasteboardKeyboard]];
			if (theKeyboard == nil) {
					// No keyboard, which is an error
				return self;
			}
			self.keyboardLayoutFile = theKeyboard;
			NSString *theIconFile = theDict[UKKeyboardPasteboardIcon];
			if (theIconFile) {
				self.iconFile = [NSURL URLWithString:theIconFile];
			}
			NSString *theLanguage = theDict[UKKeyboardPasteboardLanguage];
			if (theLanguage) {
				self.languageCode = theLanguage;
			}
		}
	}
	else if ([type isEqualToString:(NSString *)kUTTypeFileURL] || [type isEqualToString:NSPasteboardTypeURL]) {
			// Just a URL, so a keyboard layout file
		theKeyboard = [NSURL URLWithString:propertyList];
		if (theKeyboard) {
			self.keyboardLayoutFile = theKeyboard;
		}
	}
	return self;
}

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard {
#pragma unused(pasteboard)
	return @[UKKeyboardPasteType, (NSString *)kUTTypeFileURL];
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
#pragma unused(pasteboard)
	return @[UKKeyboardPasteType, (NSString *)kUTTypeFileURL];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
#pragma unused(pasteboard)
	if ([type isEqualToString:UKKeyboardPasteType]) {
		return NSPasteboardReadingAsPropertyList;
	}
	if ([type isEqualToString:(NSString *)kUTTypeFileURL] || [type isEqualToString:NSPasteboardTypeURL]) {
		return NSPasteboardReadingAsString;
	}
	return NSPasteboardReadingAsData;
}

- (NSPasteboardWritingOptions)writingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard {
#pragma unused(type)
#pragma unused(pasteboard)
	return 0;
}

- (id)pasteboardPropertyListForType:(NSString *)type {
	if ([type isEqualToString:UKKeyboardPasteType]) {
			// Create a property list
		NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionaryWithCapacity:3];
		dataDictionary[UKKeyboardPasteboardKeyboard] = [self.keyboardLayoutFile absoluteString];
		if (self.iconFile) {
			dataDictionary[UKKeyboardPasteboardIcon] = [self.iconFile absoluteString];
		}
		if (self.languageCode) {
			dataDictionary[UKKeyboardPasteboardLanguage] = self.languageCode;
		}
		return @[dataDictionary];
	}
	else if ([type isEqualToString:(NSString *)kUTTypeFileURL] || [type isEqualToString:NSPasteboardTypeURL]) {
			// Return the URL of the keyboard layout file as a string
		return [self.keyboardLayoutFile absoluteString];
	}
	else {
			// Should not get this
		return nil;
	}
}

@end

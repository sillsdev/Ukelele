//
//  UKKeyboardPasteboardItem.h
//  Ukelele Cocoa
//
//  Created by John Brownie on 29/05/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import <Foundation/Foundation.h>

	// Pasteboard type
#define UKKeyboardPasteType	@"org.sil.ukelele.keyboardpasteboardtype"

@interface UKKeyboardPasteboardItem : NSObject<NSPasteboardWriting, NSPasteboardReading>

@property (strong) NSURL *keyboardLayoutFile;
@property (strong) NSURL *iconFile;
@property (strong) NSString *languageCode;

+ (UKKeyboardPasteboardItem *)pasteboardTypeForKeyboard:(NSURL *)keyboard icon:(NSURL *)icon language:(NSString *)language;

@end

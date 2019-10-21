//
//  KeyboardLayoutInformation.h
//  Ukelele 3
//
//  Created by John Brownie on 13/10/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UkeleleKeyboardObject.h"

@class UKKeyboardController;

@interface KeyboardLayoutInformation : NSObject

@property (strong) UkeleleKeyboardObject *keyboardObject;
@property (copy) NSString *keyboardName;
@property (copy) NSString *fileName;
@property (readonly) BOOL hasIcon;
@property (copy) NSString *intendedLanguage;
@property (strong) NSData *iconData;
@property (nonatomic) BOOL doesCapsLockSwitching;
@property (strong) UKKeyboardController *keyboardController;
@property (strong) NSFileWrapper *keyboardFileWrapper;
@property (assign) BOOL hasBadKeyboard;
@property (strong) NSMutableDictionary *localisedNames;

- (instancetype)initWithObject:(UkeleleKeyboardObject *)theKeyboard fileName:(NSString *)fileName NS_DESIGNATED_INITIALIZER;

@end

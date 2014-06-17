//
//  KeyboardLayoutInformation.h
//  Ukelele 3
//
//  Created by John Brownie on 13/10/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UkeleleKeyboardObject.h"

@class UKKeyboardWindow;

@interface KeyboardLayoutInformation : NSObject

@property (strong) UkeleleKeyboardObject *keyboardObject;
@property (copy) NSString *keyboardName;
@property (copy) NSString *fileName;
@property (nonatomic) BOOL hasIcon;
@property (copy) NSString *intendedLanguage;
@property (strong) NSData *iconData;
@property (strong) UKKeyboardWindow *keyboardWindow;

- (id)initWithObject:(UkeleleKeyboardObject *)theKeyboard fileName:(NSString *)fileName;

@end

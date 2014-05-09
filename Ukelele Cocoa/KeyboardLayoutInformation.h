//
//  KeyboardLayoutInformation.h
//  Ukelele 3
//
//  Created by John Brownie on 13/10/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UkeleleDocument.h"

@interface KeyboardLayoutInformation : NSObject

@property (strong) UkeleleDocument *document;
@property (copy) NSString *keyboardName;
@property (copy) NSString *fileName;
@property (nonatomic) BOOL hasIcon;
@property (copy) NSString *intendedLanguage;
@property (strong) NSData *iconData;

- (id)initWithDocument:(UkeleleDocument *)theDocument;

@end

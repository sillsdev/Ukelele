//
//  UKDocumentPrintViewController.h
//  Ukelele Cocoa
//
//  Created by John Brownie on 16/02/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKKeyboardDocument.h"

@interface UKDocumentPrintViewController : NSViewController

@property (strong) IBOutlet NSTextField *bundleNameField;
@property (strong) IBOutlet NSTextField *bundleVersionField;
@property (strong) IBOutlet NSTextField *buildVersionField;
@property (strong) IBOutlet NSTextField *sourceVersionField;

@property (weak) UKKeyboardDocument *currentDocument;

+ (UKDocumentPrintViewController *)documentPrintViewController;

@end

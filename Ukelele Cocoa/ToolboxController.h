//
//  ToolboxController.h
//  Ukelele 3
//
//  Created by John Brownie on 26/12/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ToolboxData.h"

@interface ToolboxController : NSWindowController<NSWindowDelegate>

@property (strong) IBOutlet NSButton *stickyModifiers;
@property (strong) IBOutlet NSButton *JISOnly;
@property (readonly, weak) ToolboxData *toolboxData;

+ (ToolboxController *)sharedToolboxController;

@end

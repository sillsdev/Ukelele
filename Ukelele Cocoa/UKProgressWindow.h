//
//  UKProgressWindow.h
//  Ukelele
//
//  Created by John Brownie on 11/10/2015.
//  Copyright © 2015 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UKProgressWindow : NSWindowController

@property (strong) IBOutlet NSProgressIndicator *progressIndicator;
@property (strong) IBOutlet NSTextField *mainText;
@property (strong) IBOutlet NSTextField *secondaryText;

+ (UKProgressWindow *)progressWindow;

@end

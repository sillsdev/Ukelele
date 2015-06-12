//
//  PrintAccessoryPanel.h
//  Ukelele 3
//
//  Created by John Brownie on 3/12/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UKKeyboardPrintView.h"

@interface PrintAccessoryPanel : NSViewController<NSPrintPanelAccessorizing> {
	IBOutlet NSButton *allStates;
	IBOutlet NSButton *allModifiers;
}

@property (assign) UKKeyboardPrintView *printView;

+ (PrintAccessoryPanel *)printAccessoryPanel;

- (IBAction)toggleAllStates:(id)sender;
- (IBAction)toggleAllModifiers:(id)sender;

@end

//
//  PrintAccessoryPanel.h
//  Ukelele 3
//
//  Created by John Brownie on 3/12/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KeyboardPrintView.h"

@interface PrintAccessoryPanel : NSViewController<NSPrintPanelAccessorizing> {
	IBOutlet NSButton *allStates;
	IBOutlet NSButton *allModifiers;
}

@property (weak) KeyboardPrintView *printView;

+ (PrintAccessoryPanel *)printAccessoryPanel;

- (IBAction)toggleAllStates:(id)sender;
- (IBAction)toggleAllModifiers:(id)sender;

@end

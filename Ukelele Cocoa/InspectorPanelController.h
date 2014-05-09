//
//  InspectorPanelController.h
//  Ukelele 3
//
//  Created by John Brownie on 24/02/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface InspectorPanelController : NSWindowController<NSTableViewDelegate> {
	IBOutlet NSTextField *outputField;
	IBOutlet NSBox *outputBox;
	IBOutlet NSTextField *keyCodeField;
	IBOutlet NSScrollView *stateStackScroll;
	IBOutlet NSTableView *stateStackTable;
	IBOutlet NSArrayController *stateStackController;
	NSArray *stateStack;
}

+ (InspectorPanelController *)getInstance;
- (IBAction)showHideOutput:(id)sender;
- (IBAction)showHideStateStack:(id)sender;
- (NSArray *)stateStack;
- (void)setStateStack:(NSArray *)newStack;
- (void)setOutput:(NSString *)newOutput;
- (void)setKeyCode:(NSString *)newKeyCode;

@end

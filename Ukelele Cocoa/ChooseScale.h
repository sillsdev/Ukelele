//
//  ChooseScale.h
//  Ukelele 3
//
//  Created by John Brownie on 16/09/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UkeleleConstants.h"

@interface ChooseScale : NSWindowController {
    IBOutlet NSSlider *slider;
    IBOutlet NSTextField *textField;
    IBOutlet NSStepper *stepper;
    UKSheetCompletionBlock callBack;
};

@property (nonatomic) double value;

- (IBAction)acceptScale:(id)sender;
- (IBAction)cancelScale:(id)sender;
- (IBAction)stepScale:(id)sender;
- (IBAction)slideScale:(id)sender;
- (IBAction)textFieldEdited:(id)sender;

+ (ChooseScale *)makeChooseScale;
- (void)beginChooseScale:(double)initialValue
               forWindow:(NSWindow *)theWindow
                callBack:(UKSheetCompletionBlock)theCallBack;

@end

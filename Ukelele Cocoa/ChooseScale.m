//
//  ChooseScale.m
//  Ukelele 3
//
//  Created by John Brownie on 16/09/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "ChooseScale.h"

static const double kMinValidValue = 50.0;
static const double kMaxValidValue = 500.0;

@implementation ChooseScale

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"ChooseScale" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
        _value = 125.0;
		callBack = nil;
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

+ (ChooseScale *)makeChooseScale
{
    return [[ChooseScale alloc] initWithWindowNibName:@"ChooseScale"];
}

- (void)beginChooseScale:(double)initialValue
               forWindow:(NSWindow *)theWindow
                callBack:(UKSheetCompletionBlock)theCallBack
{
    [self setValue:initialValue];
    callBack = theCallBack;
    [NSApp beginSheet:[self window] modalForWindow:theWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (void)setValue:(double)newValue
{
    _value = newValue;
    [slider setDoubleValue:_value];
    [stepper setDoubleValue:_value];
    [textField setStringValue:[NSString stringWithFormat:@"%.1f", _value]];
}

- (IBAction)acceptScale:(id)sender
{
#pragma unused(sender)
    // User clicked OK
    [[self window] orderOut:self];
    [NSApp endSheet:[self window]];
	callBack(@(self.value));
}

- (IBAction)cancelScale:(id)sender
{
#pragma unused(sender)
    // User cancelled
    [[self window] orderOut:self];
    [NSApp endSheet:[self window]];
	callBack(nil);
}

- (IBAction)slideScale:(id)sender
{
#pragma unused(sender)
    // User changed the slider position
    [self setValue:[slider doubleValue]];
}

- (IBAction)stepScale:(id)sender
{
#pragma unused(sender)
    // User clicked the stepper
    [self setValue:[stepper doubleValue]];
}

- (IBAction)textFieldEdited:(id)sender
{
#pragma unused(sender)
    // User finished editing the text field, so validate
    double newValue = [textField doubleValue];
    if (newValue >= kMinValidValue && newValue <= kMaxValidValue) {
        [self setValue:newValue];
    }
    else {
        [textField setStringValue:[NSString stringWithFormat:@"%.1f", self.value]];
    }
}

@end

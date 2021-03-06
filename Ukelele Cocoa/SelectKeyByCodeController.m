//
//  SelectKeyByCodeController.m
//  Ukelele 3
//
//  Created by John Brownie on 4/09/13.
//
//

#import "SelectKeyByCodeController.h"
#import "UkeleleConstants.h"
#import "LayoutInfo.h"

@interface SelectKeyByCodeController ()

@end

@implementation SelectKeyByCodeController {
	void (^completionBlock)(NSInteger);
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"SelectKeyByCodeSheet" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
		completionBlock = nil;
    }
    
    return self;
}

+ (SelectKeyByCodeController *)selectKeyByCodeController {
	return [[SelectKeyByCodeController alloc] initWithWindowNibName:@"SelectKeyByCodeSheet"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)beginDialogWithWindow:(NSWindow *)parentWindow completionBlock:(void (^)(NSInteger))callback {
	completionBlock = callback;
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (void)setMajorText:(NSString *)majorText {
	[self.majorTextField setStringValue:majorText];
}

- (void)setMinorText:(NSString *)minorText {
	[self.minorTextField setStringValue:minorText];
}

- (IBAction)acceptKeyCode:(id)sender {
#pragma unused(sender)
	NSInteger keyCode = [self.keyCodeField integerValue];
	if ([LayoutInfo getKeyType:(unsigned)keyCode] == kModifierKeyType) {
			// Can't select a modifier
		[self.minorTextField setStringValue:[NSString stringWithFormat:@"The key with code %d is a modifier key, which cannot be selected.", (int)keyCode]];
		return;
	}
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(keyCode);
}

- (IBAction)cancelKeyCode:(id)sender {
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(kNoKeyCode);
}

- (void)control:(NSControl *)control didFailToValidatePartialString:(NSString *)string errorDescription:(NSString *)error {
#pragma unused(control)
#pragma unused(string)
	[self.minorTextField setStringValue:error];
	NSBeep();
}

@end

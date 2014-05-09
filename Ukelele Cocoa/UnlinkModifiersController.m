//
//  UnlinkModifiersController.m
//  Ukelele 3
//
//  Created by John Brownie on 10/05/13.
//
//

#import "UnlinkModifiersController.h"
#import "UkeleleConstants.h"

@interface UnlinkModifiersController ()

@end

static NSString *nibFileName = @"UnlinkModifierDialog";
static NSString *nibWindowName = @"UnlinkModifiers";

@implementation UnlinkModifiersController

- (id)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner
{
	[NSBundle loadNibNamed:nibFileName owner:self];
    self = [super initWithWindowNibName:windowNibName owner:self];
    if (self) {
		parentWindow = nil;
		callback = nil;
    }
    
    return self;
}

+ (UnlinkModifiersController *)unlinkModifiersController {
	return [[UnlinkModifiersController alloc] initWithWindowNibName:nibWindowName owner:self];
}

- (void)beginDialogWithWindow:(NSWindow *)window callback:(void (^)(NSNumber *))theCallback {
	parentWindow = window;
	callback = theCallback;
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)setText:(NSString *)infoText {
	[_textField setStringValue:infoText];
}

- (void)setUsesSimplifiedModifiers:(BOOL)useSimplified {
	if (useSimplified) {
		[_leftShift setTitle:@"Shift"];
		[_rightShift setHidden:YES];
		[_leftOption setTitle:@"Option"];
		[_rightOption setHidden:YES];
		[_leftControl setTitle:@"Control"];
		[_rightControl setHidden:YES];
	}
	else {
		[_leftShift setTitle:@"Left Shift"];
		[_rightShift setHidden:NO];
		[_leftOption setTitle:@"Left Option"];
		[_rightOption setHidden:NO];
		[_leftControl setTitle:@"Left Control"];
		[_rightControl setHidden:NO];
	}
}

- (IBAction)acceptModifiers:(id)sender {
	NSInteger result = 0;
	if ([_leftShift integerValue] == NSOnState) {
		result |= UKShiftKey;
	}
	if ([_rightShift integerValue] == NSOnState) {
		result |= UKRightShiftKey;
	}
	if ([_leftOption integerValue] == NSOnState) {
		result |= UKOptionKey;
	}
	if ([_rightOption integerValue] == NSOnState) {
		result |= UKRightOptionKey;
	}
	if ([_leftControl integerValue] == NSOnState) {
		result |= UKControlKey;
	}
	if ([_rightControl integerValue] == NSOnState) {
		result |= UKRightControlKey;
	}
	if ([_capsLock integerValue] == NSOnState) {
		result |= UKAlphaLock;
	}
	if ([_command integerValue] == NSOnState) {
		result |= UKCmdKey;
	}
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callback(@(result));
}

- (IBAction)cancelModifiers:(id)sender {
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callback(nil);
}

@end

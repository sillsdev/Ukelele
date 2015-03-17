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
	[[NSBundle mainBundle] loadNibNamed:nibFileName owner:self topLevelObjects:nil];
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
		[self.leftShift setTitle:@"Shift"];
		[self.rightShift setHidden:YES];
		[self.leftOption setTitle:@"Option"];
		[self.rightOption setHidden:YES];
		[self.leftControl setTitle:@"Control"];
		[self.rightControl setHidden:YES];
	}
	else {
		[self.leftShift setTitle:@"Left Shift"];
		[self.rightShift setHidden:NO];
		[self.leftOption setTitle:@"Left Option"];
		[self.rightOption setHidden:NO];
		[self.leftControl setTitle:@"Left Control"];
		[self.rightControl setHidden:NO];
	}
}

- (IBAction)acceptModifiers:(id)sender {
	NSInteger result = 0;
	if ([self.leftShift integerValue] == NSOnState) {
		result |= UKShiftKey;
	}
	if ([self.rightShift integerValue] == NSOnState) {
		result |= UKRightShiftKey;
	}
	if ([self.leftOption integerValue] == NSOnState) {
		result |= UKOptionKey;
	}
	if ([self.rightOption integerValue] == NSOnState) {
		result |= UKRightOptionKey;
	}
	if ([self.leftControl integerValue] == NSOnState) {
		result |= UKControlKey;
	}
	if ([self.rightControl integerValue] == NSOnState) {
		result |= UKRightControlKey;
	}
	if ([self.capsLock integerValue] == NSOnState) {
		result |= UKAlphaLock;
	}
	if ([self.command integerValue] == NSOnState) {
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

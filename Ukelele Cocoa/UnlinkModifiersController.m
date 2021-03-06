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
static NSString *nibWindowName = @"UnlinkModifiersDialog";

@implementation UnlinkModifiersController

- (instancetype)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner
{
#pragma unused(owner)
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
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (void)beginDialogWithWindow:(NSWindow *)window isSimplified:(BOOL)isSimplified callback:(void (^)(NSNumber *))theCallback {
	[self beginDialogWithWindow:window callback:theCallback];
	[self setUsesSimplifiedModifiers:isSimplified];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)setText:(NSString *)infoText {
	[self.textField setStringValue:infoText];
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
#pragma unused(sender)
	NSInteger result = 0;
	if ([self.leftShift integerValue] == NSControlStateValueOn) {
		result |= UKShiftKey;
	}
	if ([self.rightShift integerValue] == NSControlStateValueOn) {
		result |= UKRightShiftKey;
	}
	if ([self.leftOption integerValue] == NSControlStateValueOn) {
		result |= UKOptionKey;
	}
	if ([self.rightOption integerValue] == NSControlStateValueOn) {
		result |= UKRightOptionKey;
	}
	if ([self.leftControl integerValue] == NSControlStateValueOn) {
		result |= UKControlKey;
	}
	if ([self.rightControl integerValue] == NSControlStateValueOn) {
		result |= UKRightControlKey;
	}
	if ([self.capsLock integerValue] == NSControlStateValueOn) {
		result |= UKAlphaLock;
	}
	if ([self.command integerValue] == NSControlStateValueOn) {
		result |= UKCmdKey;
	}
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callback(@(result));
}

- (IBAction)cancelModifiers:(id)sender {
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callback(nil);
}

@end

//
//  AskSwapKeysWindowController.m
//  Ukelele 3
//
//  Created by John Brownie on 15/08/13.
//
//

#import "AskSwapKeysWindowController.h"

@interface AskSwapKeysWindowController () {
	void (^callerCallback)(NSArray *);
	NSWindow *parentWindow;
}

@end

@implementation AskSwapKeysWindowController

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"AskSwapKeyCodesWindow" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (AskSwapKeysWindowController *)askSwapKeysWindowController {
	return [[self alloc] initWithWindowNibName:@"AskSwapKeyCodesWindow"];
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)beginInteractionWithWindow:(NSWindow *)theWindow callback:(void (^)(NSArray *))theCallback {
	parentWindow = theWindow;
	callerCallback = theCallback;
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (IBAction)acceptCodes:(id)sender {
	if ([[self.keyCode1 stringValue] length] == 0 || [[self.keyCode2 stringValue] length] == 0) {
		[[self keyCodeWarning] setHidden:NO];
		return;
	}
	else if ([self.keyCode1 integerValue] == [self.keyCode2 integerValue]) {
		[[self keyCodeWarning] setHidden:YES];
		[[self sameKeyCodeWarning] setHidden:NO];
		return;
	}
	NSArray *resultArray = @[@([self.keyCode1 integerValue]), @([self.keyCode2 integerValue])];
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callerCallback(resultArray);
}

- (IBAction)cancelDialog:(id)sender {
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callerCallback(nil);
}

	// Show an error message if an invalid key code is entered

- (void)control:(NSControl *)control didFailToValidatePartialString:(NSString *)string errorDescription:(NSString *)error {
	[control setStringValue:@""];
	[[self keyCodeWarning] setHidden:NO];
	[[self sameKeyCodeWarning] setHidden:YES];
}

@end

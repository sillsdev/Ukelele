//
//  WarningDialogController.m
//  Ukelele
//
//  Created by John Brownie on 18/08/2016.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#import "WarningDialogController.h"

@interface WarningDialogController ()

+ (void)setHasBeenShown:(BOOL)value;

@property (weak) NSWindow *parentWindow;

@end

@implementation WarningDialogController

static BOOL dialogHasBeenShown = NO;

- (instancetype)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner {
	[[NSBundle mainBundle] loadNibNamed:@"WarningDialog" owner:self topLevelObjects:nil];
	self = [super initWithWindowNibName:windowNibName owner:owner];
	return self;
}

+ (WarningDialogController *)warningDialog {
	return [[WarningDialogController alloc] initWithWindowNibName:@"WarningDialog" owner:self];
}

+ (BOOL)hasBeenShown {
	@synchronized (self) {
		return dialogHasBeenShown;
	}
}

+ (void)setHasBeenShown:(BOOL)value {
	@synchronized (self) {
		dialogHasBeenShown = value;
	}
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)loadWarning:(NSURL *)warningFile {
	NSDictionary<NSAttributedStringDocumentAttributeKey, id> *options = @{};
	NSAttributedString *warningString = [[NSAttributedString alloc] initWithURL:warningFile options:options documentAttributes:nil error:nil];
	[[self.warningField textStorage] setAttributedString:warningString];
}

- (void)runDialogForWindow:(NSWindow *)theWindow {
	[WarningDialogController setHasBeenShown:YES];
	self.parentWindow = theWindow;
	[self.parentWindow beginSheet:self.window completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (IBAction)closeDialog:(id)sender {
#pragma unused(sender)
	[self.window orderOut:self];
	[self.parentWindow endSheet:self.window];
}

@end

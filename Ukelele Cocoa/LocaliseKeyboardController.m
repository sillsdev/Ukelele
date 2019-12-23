//
//  LocaliseKeyboardController.m
//  Ukelele
//
//  Created by John Brownie on 10/11/16.
//  Copyright © 2016 John Brownie. All rights reserved.
//

#import "LocaliseKeyboardController.h"

@interface LocaliseKeyboardController ()

@end

@implementation LocaliseKeyboardController {
	NSWindow *parentWindow;
	void (^callback)(NSDictionary *);
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner {
	[[NSBundle mainBundle] loadNibNamed:@"LocaliseKeyboardDialog" owner:self topLevelObjects:nil];
	self = [super initWithWindowNibName:windowNibName owner:owner];
	if (self) {
		_localisationsDictionary = [NSMutableDictionary dictionary];
		_dictionaryController = [[NSDictionaryController alloc] init];
		parentWindow = nil;
		callback = nil;
	}
	return self;
}

+ (LocaliseKeyboardController *)localiseKeyboardController {
	return [[LocaliseKeyboardController alloc] initWithWindowNibName:@"LocaliseKeyboardDialog" owner:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
	[self.localisationsTable reloadData];
}

- (void)beginDialogWithWindow:(NSWindow *)theWindow forLocalisations:(NSDictionary *)initialLocalisations withCallback:(void (^)(NSDictionary *))theCallback {
	parentWindow = theWindow;
	callback = theCallback;
	self.localisationsDictionary = [initialLocalisations mutableCopy];
	[parentWindow beginSheet:self.window completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (IBAction)acceptLocalisations:(id)sender {
#pragma unused(sender)
	[self.window orderOut:nil];
	[NSApp endSheet:self.window];
	callback(self.localisationsDictionary);
}

- (IBAction)cancelLocalisations:(id)sender {
#pragma unused(sender)
	[self.window orderOut:nil];
	[NSApp endSheet:self.window];
	callback(nil);
}

@end

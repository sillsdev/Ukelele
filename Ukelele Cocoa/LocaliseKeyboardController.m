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

- (void)beginDialogWithWindow:(NSWindow *)theWindow forLocalisations:(NSDictionary *)localisationsDictionary withCallback:(void (^)(NSDictionary *))theCallback {
	parentWindow = theWindow;
	callback = theCallback;
	self.localisationsDictionary = [localisationsDictionary mutableCopy];
	[NSApp beginSheet:self.window modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
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

#pragma mark Table delegate methods

//- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//	NSTableCellView *view = [tableView makeViewWithIdentifier:[tableColumn identifier] owner:self];
//	if (view == nil) {
//		view = [[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, [tableColumn width], 10)];
//		[view setIdentifier:[tableColumn identifier]];
//	}
//	[view.textField setStringValue:[self tableView:tableView objectValueForTableColumn:tableColumn row:row]];
//	return view;
//}

@end

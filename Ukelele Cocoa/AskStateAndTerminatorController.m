//
//  AskStateAndTerminatorController.m
//  Ukelele 3
//
//  Created by John Brownie on 13/09/13.
//
//

#import "AskStateAndTerminatorController.h"
#import "UkeleleKeyboardObject.h"
#import "UkeleleConstantStrings.h"

@interface AskStateAndTerminatorController ()

@end

@implementation AskStateAndTerminatorController {
	void (^completionBlock)(NSDictionary *dataDict);
	UkeleleKeyboardObject *keyboardObject;
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[NSBundle loadNibNamed:@"AskStateAndTerminatorSheet" owner:self];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (AskStateAndTerminatorController *)askStateAndTerminatorController {
	return [[AskStateAndTerminatorController alloc] initWithWindowNibName:@"AskStateAndTerminatorSheet"];
}

- (void)beginInteractionWithWindow:(NSWindow *)parentWindow
					   forDocument:(UkeleleKeyboardObject *)theDocument
				   completionBlock:(void (^)(NSDictionary *))callback {
	completionBlock = callback;
	keyboardObject = theDocument;
	NSArray *stateNames = [keyboardObject stateNamesExcept:kStateNameNone];
	[self.statePopup removeAllItems];
	[self.statePopup addItemsWithTitles:stateNames];
	[self.statePopup selectItemAtIndex:-1];
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)selectState:(id)sender {
	NSString *stateName = [self.statePopup titleOfSelectedItem];
	NSString *terminator = [keyboardObject terminatorForState:stateName];
	[self.currentTerminator setStringValue:terminator];
}

- (IBAction)acceptTerminator:(id)sender {
	[[self window] orderOut:self];
	NSDictionary *resultDictionary = nil;
	if (![[self.statePopup stringValue] isEqualToString:@""]) {
			// Valid state selected
		resultDictionary = @{kAskStateAndTerminatorState: [self.statePopup stringValue],
					   kAskStateAndTerminatorTerminator: [self.terminatorField stringValue]};
	}
	[NSApp endSheet:[self window]];
	completionBlock(resultDictionary);
}

- (IBAction)cancelTerminator:(id)sender {
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(nil);
}

@end

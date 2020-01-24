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

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"AskStateAndTerminatorSheet" owner:self topLevelObjects:nil];
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
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (IBAction)selectState:(id)sender {
#pragma unused(sender)
	NSString *stateName = [self.statePopup titleOfSelectedItem];
	NSString *terminator = [keyboardObject terminatorForState:stateName];
	[self.currentTerminator setStringValue:terminator];
}

- (IBAction)acceptTerminator:(id)sender {
#pragma unused(sender)
	[[self window] orderOut:self];
	NSDictionary *resultDictionary = nil;
	if (![[self.statePopup stringValue] isEqualToString:@""]) {
			// Valid state selected
		resultDictionary = @{kAskStateAndTerminatorState: [self.statePopup titleOfSelectedItem],
					   kAskStateAndTerminatorTerminator: [self.terminatorField stringValue]};
	}
	[NSApp endSheet:[self window]];
	completionBlock(resultDictionary);
}

- (IBAction)cancelTerminator:(id)sender {
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(nil);
}

@end

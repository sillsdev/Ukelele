//
//  AskStateAndTerminatorController.h
//  Ukelele 3
//
//  Created by John Brownie on 13/09/13.
//
//

#import <Cocoa/Cocoa.h>

@class UkeleleKeyboardObject;

#define kAskStateAndTerminatorState	@"State"
#define kAskStateAndTerminatorTerminator	@"Terminator"

@interface AskStateAndTerminatorController : NSWindowController

@property (strong) IBOutlet NSPopUpButton *statePopup;
@property (strong) IBOutlet NSTextField *terminatorField;
@property (strong) IBOutlet NSTextField *currentTerminator;

- (IBAction)selectState:(id)sender;
- (IBAction)acceptTerminator:(id)sender;
- (IBAction)cancelTerminator:(id)sender;

+ (AskStateAndTerminatorController *)askStateAndTerminatorController;

- (void)beginInteractionWithWindow:(NSWindow *)parentWindow
					   forDocument:(UkeleleKeyboardObject *)theDocument
				   completionBlock:(void (^)(NSDictionary *))callback;

@end

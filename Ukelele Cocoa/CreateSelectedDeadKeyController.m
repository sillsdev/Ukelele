//
//  CreateSelectedDeadKeyController.m
//  Ukelele 3
//
//  Created by John Brownie on 3/09/13.
//
//

#import "CreateSelectedDeadKeyController.h"
#import "UkeleleKeyboardObject.h"
#import "UkeleleConstantStrings.h"
#import "UKKeyboardController+Housekeeping.h"

#define theNibName @"CreateSelectedDeadKeySheet"

@interface CreateSelectedDeadKeyController ()

@property (strong, nonatomic) NSArray *stateNames;

@end

@implementation CreateSelectedDeadKeyController {
	void (^completionBlock)(NSDictionary *);
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:theNibName owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
		_stateNames = nil;
    }
    
    return self;
}

+ (CreateSelectedDeadKeyController *)createSelectedDeadKeyController {
	return [[CreateSelectedDeadKeyController alloc] initWithWindowNibName:theNibName];
}

- (void)runSheetForWindow:(NSWindow *)parentWindow keyboard:(UkeleleKeyboardObject *)keyboardObject keyCode:(NSInteger)keyCode targetState:(NSString *)targetState completionBlock:(void (^)(NSDictionary *))callback {
#pragma unused(keyCode)
	NSMutableArray *states = [[keyboardObject stateNamesExcept:kStateNameNone] mutableCopy];
	[states insertObject:[keyboardObject uniqueStateName] atIndex:0];
	self.stateNames = states;
	completionBlock = callback;
	[self.stateField removeAllItems];
	[self.stateField addItemsWithObjectValues:self.stateNames];
	if (targetState != nil) {
			// Select the target state
		[self.stateField selectItemWithObjectValue:targetState];
	}
	else {
			// Select the newly created state name
		[self.stateField selectItemAtIndex:0];
	}
	[self.missingStateWarning setHidden:YES];
	[self.invalidStateNameWarning setHidden:YES];
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (IBAction)acceptDeadKey:(id)sender {
#pragma unused(sender)
	NSString *stateName = [self.stateField stringValue];
	if ([self.stateField indexOfSelectedItem] == -1 && [stateName length] == 0) {
			// No state specified
		[self.missingStateWarning setHidden:NO];
		[self.invalidStateNameWarning setHidden:YES];
		return;
	}
	if (![UKKeyboardController isValidStateName:stateName]) {
		[self.missingStateWarning setHidden:YES];
		[self.invalidStateNameWarning setHidden:NO];
		return;
	}
	NSMutableDictionary *resultDict = [NSMutableDictionary dictionaryWithObject:stateName forKey:kCreateSelectedDeadKeyState];
	if ([self.stateField indexOfSelectedItem] == -1) {
			// Return the terminator as well
		resultDict[kCreateSelectedDeadKeyTerminator] = [self.terminatorField stringValue];
	}
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(resultDict);
}

- (IBAction)cancelDeadKey:(id)sender {
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(nil);
}

@end

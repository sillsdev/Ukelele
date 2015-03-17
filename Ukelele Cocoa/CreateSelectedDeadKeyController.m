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

@interface CreateSelectedDeadKeyController ()

@property (strong, nonatomic) NSArray *stateNames;

@end

@implementation CreateSelectedDeadKeyController {
	void (^completionBlock)(NSDictionary *);
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"CreateSelectedDeadKeySheet" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
		_stateNames = nil;
    }
    
    return self;
}

+ (CreateSelectedDeadKeyController *)createSelectedDeadKeyController {
	return [[CreateSelectedDeadKeyController alloc] initWithWindowNibName:@"CreateSelectedDeadKeySheet"];
}

- (void)runSheetForWindow:(NSWindow *)parentWindow keyboard:(UkeleleKeyboardObject *)keyboardObject keyCode:(NSInteger)keyCode completionBlock:(void (^)(NSDictionary *))callback {
	self.stateNames = [keyboardObject stateNamesExcept:kStateNameNone];
	completionBlock = callback;
	[self.stateField removeAllItems];
	[self.stateField addItemsWithObjectValues:self.stateNames];
	[self.missingStateWarning setHidden:YES];
	[self.invalidStateNameWarning setHidden:YES];
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)acceptDeadKey:(id)sender {
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
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(nil);
}

@end

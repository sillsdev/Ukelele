//
//  HandleDeadKeyController.m
//  Ukelele 3
//
//  Created by John Brownie on 14/09/13.
//
//

#import "HandleDeadKeyController.h"
#import "UkeleleKeyboardObject.h"
#import "UkeleleConstantStrings.h"

@interface HandleDeadKeyController ()

@end

@implementation HandleDeadKeyController {
	void (^completionBlock)(NSDictionary *dataDict);
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"HandleDeadKeySheet" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

+ (HandleDeadKeyController *)handleDeadKeyController {
	return [[[HandleDeadKeyController alloc] initWithWindowNibName:@"HandleDeadKeySheet"] autorelease];
}

- (HandleDeadKeyType)typeForTab:(NSString *)tabIdentifier {
	if ([UKHandleDeadKeyTerminator isEqualToString:tabIdentifier]) {
		return kHandleDeadKeyChangeTerminator;
	}
	if ([UKHandleDeadKeyChangeState isEqualToString:tabIdentifier]) {
		return kHandleDeadKeyChangeState;
	}
	if ([UKHandleDeadKeyMakeOutput isEqualToString:tabIdentifier]) {
		return kHandleDeadKeyChangeToOutput;
	}
	if ([UKHandledeadKeyEnterState isEqualToString:tabIdentifier]) {
		return kHandleDeadKeyEnterState;
	}
	NSLog(@"Unknown tab identifier %@", tabIdentifier);
	return kHandleDeadKeyEnterState;
}

- (void)beginInteractionWithWindow:(NSWindow *)parentWindow
						  document:(UkeleleKeyboardObject *)theDocument
						  forState:(NSString *)theState
						 nextState:(NSString *)nextState
				   completionBlock:(void (^)(NSDictionary *))callback {
	completionBlock = callback;
	NSString *terminator = [theDocument terminatorForState:nextState];
	NSString *formatString = @"Currently it goes to state \"%@\", which has terminator \"%@\"";
	[self.infoField setStringValue:[NSString stringWithFormat:formatString, nextState, terminator]];
	[self.terminatorField setStringValue:terminator];
	NSMutableArray *stateNames = [[theDocument stateNamesExcept:kStateNameNone] mutableCopy];
	[stateNames removeObjectIdenticalTo:theState];
	[stateNames removeObjectIdenticalTo:nextState];
	[self.statePopup removeAllItems];
	[self.statePopup addItemsWithObjectValues:[stateNames autorelease]];
	[self.statePopup selectItemWithObjectValue:nextState];
	[NSApp beginSheet:[self window] modalForWindow:parentWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)acceptChoice:(id)sender {
#pragma unused(sender)
	HandleDeadKeyType choice = [self typeForTab:[[self.choiceTabView selectedTabViewItem] identifier]];
	NSMutableDictionary *dataDict = [NSMutableDictionary dictionaryWithCapacity:2];
	dataDict[kHandleDeadKeyType] = @(choice);
	switch (choice) {
		case kHandleDeadKeyChangeTerminator:
			dataDict[kHandleDeadKeyString] = [self.terminatorField stringValue];
			break;
			
		case kHandleDeadKeyChangeState:
			dataDict[kHandleDeadKeyString] = [self.statePopup stringValue];
			break;
			
		case kHandleDeadKeyChangeToOutput:
			dataDict[kHandleDeadKeyString] = [self.outputField stringValue];
			break;
			
		case kHandleDeadKeyEnterState:
				// No string to pass on
			break;
	}
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(dataDict);
}

- (IBAction)cancelChoice:(id)sender {
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(nil);
}

@end

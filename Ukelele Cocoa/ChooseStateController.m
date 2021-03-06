//
//  ChooseStateController.m
//  Ukelele 3
//
//  Created by John Brownie on 18/09/13.
//
//

#import "ChooseStateController.h"

@implementation ChooseStateController {
	void (^completionBlock)(NSString *);
}

- (instancetype)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"ChooseStateSheet" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
		completionBlock = nil;
		_stateNames = nil;
    }
    
    return self;
}

+ (ChooseStateController *)chooseStateController {
	return [[ChooseStateController alloc] initWithWindowNibName:@"ChooseStateSheet"];
}

- (void)askStateForWindow:(NSWindow *)parentWindow completionBlock:(void (^)(NSString *))callBack {
	completionBlock = callBack;
	[self.stateList removeAllItems];
	[self.stateList addItemsWithObjectValues:self.stateNames];
	[parentWindow beginSheet:[self window] completionHandler:^(NSModalResponse returnCode) {
#pragma unused(returnCode)
		return;
	}];
}

- (IBAction)acceptState:(id)sender {
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock([self.stateList stringValue]);
}

- (IBAction)cancelState:(id)sender {
#pragma unused(sender)
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	completionBlock(nil);
}

@end

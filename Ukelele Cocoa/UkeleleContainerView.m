//
//  UkeleleContainerView.m
//  Ukelele 3
//
//  Created by John Brownie on 10/02/13.
//
//

#import "UkeleleContainerView.h"
#import "UKKeyboardController.h"

@implementation UkeleleContainerView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		_passEvents = NO;
    }
    
    return self;
}

- (void)flagsChanged:(NSEvent *)theEvent {
	if (self.passEvents) {
		UKKeyboardController *theDocumentWindow = [[self window] windowController];
		[theDocumentWindow messageModifiersChanged:[theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask];
	}
}

- (void)keyDown:(NSEvent *)theEvent {
	if (self.passEvents) {
		UKKeyboardController *theDocumentWindow = [[self window] windowController];
		[theDocumentWindow messageKeyDown:[theEvent keyCode]];
	}
}

- (void)keyUp:(NSEvent *)theEvent {
	if (self.passEvents) {
		UKKeyboardController *theDocumentWindow = [[self window] windowController];
		[theDocumentWindow messageKeyUp:[theEvent keyCode]];
	}
}

@end

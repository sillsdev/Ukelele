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
    }
    
    return self;
}

- (void)flagsChanged:(NSEvent *)theEvent {
	UKKeyboardController *theDocumentWindow = [[self window] windowController];
	[theDocumentWindow messageModifiersChanged:[theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask];
}

- (void)keyDown:(NSEvent *)theEvent {
	UKKeyboardController *theDocumentWindow = [[self window] windowController];
	[theDocumentWindow messageKeyDown:[theEvent keyCode]];
}

- (void)keyUp:(NSEvent *)theEvent {
	UKKeyboardController *theDocumentWindow = [[self window] windowController];
	[theDocumentWindow messageKeyUp:[theEvent keyCode]];
}

@end

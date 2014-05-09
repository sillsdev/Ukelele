//
//  UkeleleContainerView.m
//  Ukelele 3
//
//  Created by John Brownie on 10/02/13.
//
//

#import "UkeleleContainerView.h"
#import "UkeleleDocument.h"

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
	UkeleleDocument *theDocument = [[[self window] windowController] document];
	[theDocument messageModifiersChanged:[theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask];
}

- (void)keyDown:(NSEvent *)theEvent {
	UkeleleDocument *theDocument = [[[self window] windowController] document];
	[theDocument messageKeyDown:[theEvent keyCode]];
}

- (void)keyUp:(NSEvent *)theEvent {
	UkeleleDocument *theDocument = [[[self window] windowController] document];
	[theDocument messageKeyUp:[theEvent keyCode]];
}

@end

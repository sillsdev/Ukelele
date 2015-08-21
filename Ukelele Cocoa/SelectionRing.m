//
//  SelectionRing.m
//  Ukelele 3
//
//  Created by John Brownie on 15/11/13.
//
//

#import "SelectionRing.h"

@implementation SelectionRing

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    if (self.selected) {
			// Only draw if selected
		[[NSColor blueColor] set];
		[NSBezierPath fillRect:dirtyRect];
	}
}

- (void)setSelected:(BOOL)selected {
	_selected = selected;
	[self setNeedsDisplay:YES];
}

@end

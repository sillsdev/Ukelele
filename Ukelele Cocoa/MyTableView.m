//
//  MyTableView.m
//  Ukelele 3
//
//  Created by John Brownie on 30/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "MyTableView.h"


@implementation MyTableView

- (void)keyDown:(NSEvent *)theEvent
{
	[self.windowController keyDown:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
	[self.windowController keyUp:theEvent];
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	[self.windowController flagsChanged:theEvent];
}

@end

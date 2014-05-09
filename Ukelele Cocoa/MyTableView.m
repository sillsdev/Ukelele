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
	[_windowController keyDown:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent
{
	[_windowController keyUp:theEvent];
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	[_windowController flagsChanged:theEvent];
}

@end

//
//  InspectorPanelController.m
//  Ukelele 3
//
//  Created by John Brownie on 24/02/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import "InspectorPanelController.h"

static InspectorPanelController *sController = nil;

@implementation InspectorPanelController

static NSString *windowName = @"InfoInspector";
static NSString *frameLabel = @"InspectorPanel";

+ (InspectorPanelController *)getInstance
{
	if (sController == nil) {
		sController = [[InspectorPanelController alloc] initWithWindowNibName:windowName];
	}
	return sController;
}

- (id)init
{
	self = [super init];
	if (self) {
		stateStack = nil;
	}
	return self;
}

- (void)windowDidLoad
{
	[(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];
	[[self window] setFrameUsingName:frameLabel];
	[stateStackTable setDelegate:self];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
#pragma unused(aTableView)
	NSLog(@"Asking whether to select row %ld", (long)rowIndex);
	return NO;
}

- (void)showHideView:(NSView *)theView
{
	NSWindow *theWindow = [self window];
	BOOL hidden = [theView isHidden];
	NSRect viewFrame = [theView frame];
	float  viewTop = viewFrame.origin.y;
	if (!hidden) {
		viewTop += viewFrame.size.height;
	}
	float vertMove = viewFrame.size.height;
	if (!hidden) {
		vertMove = -vertMove;
	}
	NSView *contentView = [theWindow contentView];
	NSArray *allViews = [contentView subviews];
	NSUInteger viewCount = [allViews count];
	NSUInteger i;
	for (i = 0; i < viewCount; i++) {
		NSView *subView = (NSView *)allViews[i];
		viewFrame = [subView frame];
		if (viewFrame.origin.y <=  viewTop) {
			viewFrame.origin.y -= vertMove;
			[subView setFrame:viewFrame];
		}
	}
	[theView setHidden:!hidden];
	[contentView setNeedsDisplay:YES];
	viewFrame = [theWindow frame];
	viewFrame.size.height += vertMove;
	viewFrame.origin.y -= vertMove;
	[theWindow setFrame:viewFrame display:YES animate:YES];
}

- (IBAction)showHideOutput:(id)sender
{
#pragma unused(sender)
	[self showHideView:outputBox];
}

- (IBAction)showHideStateStack:(id)sender
{
#pragma unused(sender)
	[self showHideView:stateStackScroll];
}

- (NSArray *)stateStack
{
	return stateStack;
}

- (void)setStateStack:(NSArray *)newStack
{
	stateStack = newStack;
	[stateStackController setContent:stateStack];
	[stateStackController setSelectionIndex:[stateStack count] - 1];
}

- (void)setOutput:(NSString *)newOutput
{
	[outputField setStringValue:newOutput];
	[outputField setNeedsDisplay:YES];
}

- (void)setKeyCode:(NSString *)newKeyCode
{
	[keyCodeField setStringValue:newKeyCode];
	[keyCodeField setNeedsDisplay:YES];
}

@end

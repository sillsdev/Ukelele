//
//  UKProgressWindow.m
//  Ukelele
//
//  Created by John Brownie on 11/10/2015.
//  Copyright © 2015 John Brownie. All rights reserved.
//

#import "UKProgressWindow.h"

@interface UKProgressWindow ()

@end

@implementation UKProgressWindow

- (instancetype)initWithWindowNibName:(NSString *)windowNibName owner:(id)owner {
	[[NSBundle mainBundle] loadNibNamed:@"ProgressWindow" owner:self topLevelObjects:nil];
	self = [super initWithWindowNibName:windowNibName owner:owner];
	return self;
}

+ (UKProgressWindow *)progressWindow {
	return [[UKProgressWindow alloc] initWithWindowNibName:@"ProgressWindow" owner:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end

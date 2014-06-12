//
//  BundleVersionSheet.m
//  Ukelele 3
//
//  Created by John Brownie on 7/09/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "UkeleleBundleVersionSheet.h"

@interface UkeleleBundleVersionSheet ()

@end

@implementation UkeleleBundleVersionSheet

@synthesize bundleNameField;
@synthesize bundleVersionField;
@synthesize buildVersionField;
@synthesize sourceVersionField;

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[[NSBundle mainBundle] loadNibNamed:@"UkeleleBundleVersionSheet" owner:self topLevelObjects:nil];
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        // Initialization code here.
		callBack = nil;
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

+ (UkeleleBundleVersionSheet *)bundleVersionSheet {
	return [[UkeleleBundleVersionSheet alloc] initWithWindowNibName:@"UkeleleBundleVersionSheet"];
}

- (void)beginSheetWithBundleName:(NSString *)theBundleName
				   bundleVersion:(NSString *)theBundleVersion
					buildVersion:(NSString *)theBuildVersion
				   sourceVersion:(NSString *)theSourceVersion
					   forWindow:(NSWindow *)theWindow
						callBack:(void (^)(UkeleleBundleVersionSheet *))theCallBack {
	[bundleNameField setStringValue:theBundleName];
	[bundleVersionField setStringValue:theBundleVersion];
	[buildVersionField setStringValue:theBuildVersion];
	[sourceVersionField setStringValue:theSourceVersion];
	callBack = theCallBack;
	[NSApp beginSheet:[self window] modalForWindow:theWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)acceptEdit:(id)sender {
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(self);
}

- (IBAction)cancel:(id)sender {
	[[self window] orderOut:self];
	[NSApp endSheet:[self window]];
	callBack(nil);
}

@end
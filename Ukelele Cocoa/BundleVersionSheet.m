//
//  BundleVersionSheet.m
//  Ukelele 3
//
//  Created by John Brownie on 7/09/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "BundleVersionSheet.h"

@interface BundleVersionSheet ()

@end

@implementation BundleVersionSheet

@synthesize bundleNameField;
@synthesize bundleVersionField;
@synthesize buildVersionField;
@synthesize sourceVersionField;

- (id)initWithWindowNibName:(NSString *)windowNibName
{
	[NSBundle loadNibNamed:@"BundleVersionSheet" owner:self];
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

+ (BundleVersionSheet *)bundleVersionSheet {
	return [[BundleVersionSheet alloc] initWithWindowNibName:@"BundleVersionSheet"];
}

- (void)beginSheetWithBundleName:(NSString *)theBundleName
				   bundleVersion:(NSString *)theBundleVersion
					buildVersion:(NSString *)theBuildVersion
				   sourceVersion:(NSString *)theSourceVersion
					   forWindow:(NSWindow *)theWindow
						callBack:(void (^)(BundleVersionSheet *))theCallBack {
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

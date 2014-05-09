//
//  BundleVersionSheet.h
//  Ukelele 3
//
//  Created by John Brownie on 7/09/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BundleVersionSheet : NSWindowController {
	NSWindow *parentWindow;
	void (^callBack)(BundleVersionSheet *);
}

@property (weak, readonly) IBOutlet NSTextField *bundleNameField;
@property (weak, readonly) IBOutlet NSTextField *bundleVersionField;
@property (weak, readonly) IBOutlet NSTextField *buildVersionField;
@property (weak, readonly) IBOutlet NSTextField *sourceVersionField;

- (IBAction)acceptEdit:(id)sender;

+ (BundleVersionSheet *)bundleVersionSheet;
- (void)beginSheetWithBundleName:(NSString *)theBundleName
				   bundleVersion:(NSString *)theBundleVersion
					buildVersion:(NSString *)theBuildVersion
				   sourceVersion:(NSString *)theSourceVersion
					   forWindow:(NSWindow *)theWindow
						callBack:(void (^)(BundleVersionSheet *))theCallBack;

@end

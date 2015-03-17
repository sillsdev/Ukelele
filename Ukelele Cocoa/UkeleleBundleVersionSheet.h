//
//  BundleVersionSheet.h
//  Ukelele 3
//
//  Created by John Brownie on 7/09/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface UkeleleBundleVersionSheet : NSWindowController {
	NSWindow *parentWindow;
	void (^callBack)(UkeleleBundleVersionSheet *);
}

@property (strong) IBOutlet NSTextField *bundleNameField;
@property (strong) IBOutlet NSTextField *bundleVersionField;
@property (strong) IBOutlet NSTextField *buildVersionField;
@property (strong) IBOutlet NSTextField *sourceVersionField;

- (IBAction)acceptEdit:(id)sender;

+ (UkeleleBundleVersionSheet *)bundleVersionSheet;
- (void)beginSheetWithBundleName:(NSString *)theBundleName
				   bundleVersion:(NSString *)theBundleVersion
					buildVersion:(NSString *)theBuildVersion
				   sourceVersion:(NSString *)theSourceVersion
					   forWindow:(NSWindow *)theWindow
						callBack:(void (^)(UkeleleBundleVersionSheet *))theCallBack;

@end

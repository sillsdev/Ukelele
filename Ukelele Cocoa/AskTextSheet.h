//
//  AskTextSheet.h
//  Ukelele 3
//
//  Created by John Brownie on 30/04/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "UkeleleConstants.h"

@interface AskTextSheet : NSWindowController {
	IBOutlet NSWindow *askTextSheet;
	IBOutlet NSTextField *askTextMajorText;
	IBOutlet NSTextField *askTextMinorText;
	IBOutlet NSTextField *askTextField;
	UKSheetCompletionBlock askTextCallBack;
}

- (IBAction)acceptAskText:(id)sender;
- (IBAction)cancelAskText:(id)sender;

+ (AskTextSheet *)askTextSheet;

- (void)beginAskText:(NSString *)theMajorText
		   minorText:(NSString *)theMinorText
		 initialText:(NSString *)theInitialText
		   forWindow:(NSWindow *)parentWindow
			callBack:(UKSheetCompletionBlock)theCallBack;	// Callback will be invoked with the returned text or nil
- (void)beginAskValidatedText:(NSString *)theMajorText
				   notFromSet:(NSSet *)stopList
					errorText:(NSString *)errorText
				  initialText:(NSString *)theInitialText
					forWindow:(NSWindow *)parentWindow
					 callBack:(UKSheetCompletionBlock)theCallBack;

@end

//
//  UnlinkModifiersController.h
//  Ukelele 3
//
//  Created by John Brownie on 10/05/13.
//
//

#import <Cocoa/Cocoa.h>

@interface UnlinkModifiersController : NSWindowController {
	NSWindow *parentWindow;
	void (^callback)(NSNumber *);
}

@property (strong) IBOutlet NSButton *leftShift;
@property (strong) IBOutlet NSButton *rightShift;
@property (strong) IBOutlet NSButton *leftOption;
@property (strong) IBOutlet NSButton *rightOption;
@property (strong) IBOutlet NSButton *command;
@property (strong) IBOutlet NSButton *capsLock;
@property (strong) IBOutlet NSButton *leftControl;
@property (strong) IBOutlet NSButton *rightControl;
@property (strong) IBOutlet NSTextField *textField;

- (IBAction)acceptModifiers:(id)sender;
- (IBAction)cancelModifiers:(id)sender;

+ (UnlinkModifiersController *)unlinkModifiersController;
- (void)beginDialogWithWindow:(NSWindow *)window callback:(void (^)(NSNumber *))theCallback;
- (void)beginDialogWithWindow:(NSWindow *)window isSimplified:(BOOL)isSimplified callback:(void (^)(NSNumber *))theCallback;

- (void)setText:(NSString *)infoText;
- (void)setUsesSimplifiedModifiers:(BOOL)useSimplified;

@end

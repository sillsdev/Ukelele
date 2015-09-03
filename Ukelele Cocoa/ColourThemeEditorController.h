//
//  ColourThemeEditorController.h
//  Ukelele 3
//
//  Created by John Brownie on 14/11/13.
//
//

#import <Cocoa/Cocoa.h>
#import "KeyCapView.h"
#import "SelectionRing.h"

@interface ColourThemeEditorController : NSWindowController<UKKeyCapClick, NSWindowDelegate, NSPopoverDelegate>

@property (strong) IBOutlet NSPopUpButton *themeList;
@property (strong) IBOutlet KeyCapView *normalUp;
@property (strong) IBOutlet SelectionRing *normalUpSelection;
@property (strong) IBOutlet KeyCapView *normalDown;
@property (strong) IBOutlet SelectionRing *normalDownSelection;
@property (strong) IBOutlet KeyCapView *deadKeyUp;
@property (strong) IBOutlet SelectionRing *deadKeyUpSelection;
@property (strong) IBOutlet KeyCapView *deadKeyDown;
@property (strong) IBOutlet SelectionRing *deadKeyDownSelection;
@property (strong) IBOutlet KeyCapView *selectedUp;
@property (strong) IBOutlet SelectionRing *selectedUpSelection;
@property (strong) IBOutlet KeyCapView *selectedDown;
@property (strong) IBOutlet SelectionRing *selectedDownSelection;
@property (strong) IBOutlet KeyCapView *selectedDeadUp;
@property (strong) IBOutlet SelectionRing *selectedDeadUpSelection;
@property (strong) IBOutlet KeyCapView *selectedDeadDown;
@property (strong) IBOutlet SelectionRing *selectedDeadDownSelection;
@property (strong) IBOutlet NSMatrix *gradientType;
@property (strong) IBOutlet NSColorWell *outerColour;
@property (strong) IBOutlet NSColorWell *innerColour;
@property (strong) IBOutlet NSColorWell *textColour;
@property (strong) IBOutlet NSTextField *outerColourLabel;
@property (strong) IBOutlet NSTextField *innerColourLabel;
@property (strong) IBOutlet NSButton *deleteButton;

- (IBAction)acceptColourTheme:(id)sender;
- (IBAction)revertColourThemes:(id)sender;
- (IBAction)changeOuterColour:(id)sender;
- (IBAction)changeInnerColour:(id)sender;
- (IBAction)changeTextColour:(id)sender;
- (IBAction)newColourTheme:(id)sender;
- (IBAction)deleteColourTheme:(id)sender;
- (IBAction)renameColourTheme:(id)sender;
- (IBAction)selectColourTheme:(id)sender;
- (IBAction)setGradient:(id)sender;

+ (ColourThemeEditorController *)colourThemeEditorController;

- (void)showColourThemesWithWindow:(NSWindow *)parentWindow completionBlock:(void (^)(NSString *))theBlock;

@end

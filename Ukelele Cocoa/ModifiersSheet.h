//
//  ModifiersSheet.h
//  Ukelele 3
//
//  Created by John Brownie on 18/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ModifierConstants.h"

enum {
	kModifiersNewIndex = 0,
	kModifiersSameIndex = 1
};

@interface ModifiersInfo : NSObject<NSCopying>

@property (nonatomic) NSInteger keyMapIndex;
@property (nonatomic) NSInteger keyMapSubindex;
@property (nonatomic) NSInteger shiftValue;
@property (nonatomic) NSInteger capsLockValue;
@property (nonatomic) NSInteger optionValue;
@property (nonatomic) NSInteger commandValue;
@property (nonatomic) NSInteger controlValue;
@property (nonatomic) NSInteger existingOrNewValue;

- (BOOL)modifiersAreEqualTo:(ModifiersInfo *)compareTo;

@end


@interface ModifiersSheet : NSWindowController {
	void (^callBack)(ModifiersInfo *);
}

    // Regular sheet
@property (nonatomic, weak, readonly) IBOutlet NSMatrix *shiftTogether;
@property (nonatomic, weak, readonly) IBOutlet NSMatrix *shiftLeft;
@property (nonatomic, weak, readonly) IBOutlet NSMatrix *shiftRight;
@property (nonatomic, weak, readonly) IBOutlet NSMatrix *capsLock;
@property (nonatomic, weak, readonly) IBOutlet NSMatrix *optionTogether;
@property (nonatomic, weak, readonly) IBOutlet NSMatrix *optionLeft;
@property (nonatomic, weak, readonly) IBOutlet NSMatrix *optionRight;
@property (nonatomic, weak, readonly) IBOutlet NSMatrix *command;
@property (nonatomic, weak, readonly) IBOutlet NSMatrix *controlTogether;
@property (nonatomic, weak, readonly) IBOutlet NSMatrix *controlLeft;
@property (nonatomic, weak, readonly) IBOutlet NSMatrix *controlRight;
@property (nonatomic, weak, readonly) IBOutlet NSMatrix *existingOrNewIndex;
    // Simplified sheet
@property (nonatomic, weak, readonly) IBOutlet NSPopUpButton *shiftPopup;
@property (nonatomic, weak, readonly) IBOutlet NSPopUpButton *capsLockPopup;
@property (nonatomic, weak, readonly) IBOutlet NSPopUpButton *optionPopup;
@property (nonatomic, weak, readonly) IBOutlet NSPopUpButton *commandPopup;
@property (nonatomic, weak, readonly) IBOutlet NSPopUpButton *controlPopup;
@property (nonatomic, weak, readonly) IBOutlet NSMatrix *existingOrNewIndexSimplified;
@property (nonatomic, weak, readonly) IBOutlet NSWindow *simplifiedWindow;
@property (nonatomic, readwrite) BOOL isSimplified;

- (IBAction)shiftTogetherChoice:(id)sender;
- (IBAction)optionTogetherChoice:(id)sender;
- (IBAction)controlTogetherChoice:(id)sender;
- (IBAction)acceptModifiers:(id)sender;
- (IBAction)cancelModifiers:(id)sender;

+ (ModifiersSheet *)modifiersSheet:(ModifiersInfo *)modifierInfo;
+ (ModifiersSheet *)simplifiedModifiersSheet:(ModifiersInfo *)modifierInfo;

- (void)beginModifiersSheetWithCallback:(void (^)(ModifiersInfo *))theCallback
								  isNew:(BOOL)creatingNew
						 canBeSameIndex:(BOOL)canBeSame
							  forWindow:(NSWindow *)parentWindow;
- (void)beginSimplifiedModifiersSheetWithCallback:(void (^)(ModifiersInfo *))theCallback
											isNew:(BOOL)creatingNew
								   canBeSameIndex:(BOOL)canBeSame
										forWindow:(NSWindow *)parentWindow;

@end

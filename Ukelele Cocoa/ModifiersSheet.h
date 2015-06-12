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
@property (nonatomic, strong, readonly) IBOutlet NSMatrix *shiftTogether;
@property (nonatomic, strong, readonly) IBOutlet NSMatrix *shiftLeft;
@property (nonatomic, strong, readonly) IBOutlet NSMatrix *shiftRight;
@property (nonatomic, strong, readonly) IBOutlet NSMatrix *capsLock;
@property (nonatomic, strong, readonly) IBOutlet NSMatrix *optionTogether;
@property (nonatomic, strong, readonly) IBOutlet NSMatrix *optionLeft;
@property (nonatomic, strong, readonly) IBOutlet NSMatrix *optionRight;
@property (nonatomic, strong, readonly) IBOutlet NSMatrix *command;
@property (nonatomic, strong, readonly) IBOutlet NSMatrix *controlTogether;
@property (nonatomic, strong, readonly) IBOutlet NSMatrix *controlLeft;
@property (nonatomic, strong, readonly) IBOutlet NSMatrix *controlRight;
@property (nonatomic, strong, readonly) IBOutlet NSMatrix *existingOrNewIndex;
    // Simplified sheet
@property (nonatomic, strong, readonly) IBOutlet NSPopUpButton *shiftPopup;
@property (nonatomic, strong, readonly) IBOutlet NSPopUpButton *capsLockPopup;
@property (nonatomic, strong, readonly) IBOutlet NSPopUpButton *optionPopup;
@property (nonatomic, strong, readonly) IBOutlet NSPopUpButton *commandPopup;
@property (nonatomic, strong, readonly) IBOutlet NSPopUpButton *controlPopup;
@property (nonatomic, strong, readonly) IBOutlet NSMatrix *existingOrNewIndexSimplified;
@property (nonatomic, strong, readonly) IBOutlet NSWindow *simplifiedWindow;
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

//
//  UkeleleDocument+Modifiers.h
//  Ukelele Cocoa
//
//  Created by John Brownie on 21/05/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import "UkeleleDocument.h"

@interface UkeleleDocument (Modifiers)

- (IBAction)addModifiers:(id)sender;
- (IBAction)removeModifiers:(id)sender;
- (IBAction)doubleClickRow:(id)sender;
- (IBAction)setDefaultIndex:(id)sender;
- (IBAction)simplifyModifiers:(id)sender;
- (IBAction)unlinkModifierSet:(id)sender;

- (void)setDefaultModifierIndex:(NSUInteger)defaultIndex;
- (void)changeModifiersIndex:(NSInteger)index
					subIndex:(NSInteger)subindex
					   shift:(NSInteger)newShift
					  option:(NSInteger)newOption
					capsLock:(NSInteger)newCapsLock
					 command:(NSInteger)newCommand
					 control:(NSInteger)newControl;
- (void)removeModifierElement:(NSInteger)keyboardID index:(NSInteger)index subindex:(NSInteger)subindex;
- (void)addModifierElement:(NSInteger)keyboardID
					 index:(NSInteger)index
				  subIndex:(NSInteger)subindex
					 shift:(NSInteger)newShift
				  capsLock:(NSInteger)newCapsLock
					option:(NSInteger)newOption
				   command:(NSInteger)newCommand
				   control:(NSInteger)newControl;
- (void)removeKeyMap:(NSInteger)index forKeyboard:(NSInteger)keyboardID newDefaultIndex:(NSInteger)newDefaultIndex;
- (void)replaceKeyMap:(NSInteger)index
		  forKeyboard:(NSInteger)keyboardID
		 defaultIndex:(NSInteger)defaultIndex
		 keyMapSelect:(void *)keyMapSelect
	   keyMapElements:(void *)deletedKeyMapElements;
- (void)modifierMapDidChangeImplementation;
- (void)setupDataSource;
- (void)updateModifiers;

@end

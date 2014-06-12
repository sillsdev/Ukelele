//
//  UKKeyboardWindow+Housekeeping.h
//  Ukelele Cocoa
//
//  Created by John Brownie on 12/06/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import "UKKeyboardWindow.h"

@interface UKKeyboardWindow (Housekeeping)

- (IBAction)removeUnusedStates:(id)sender;
- (IBAction)removeUnusedActions:(id)sender;
- (IBAction)changeStateName:(id)sender;
- (IBAction)changeActionName:(id)sender;
- (IBAction)addSpecialKeyOutput:(id)sender;
- (IBAction)askKeyboardIdentifiers:(id)sender;
- (IBAction)colourThemes:(id)sender;

- (void)changeKeyboardName:(NSString *)newName;
- (void)changeKeyboardScript:(NSInteger)newScriptCode;
- (void)changeKeyboardID:(NSInteger)newID;

+ (BOOL)isValidStateName:(NSString *)stateName;

@end

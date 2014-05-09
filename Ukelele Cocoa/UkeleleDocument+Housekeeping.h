//
//  UkeleleDocument+Housekeeping.h
//  Ukelele 3
//
//  Created by John Brownie on 12/06/12.
//  Copyright (c) 2012 SIL. All rights reserved.
//

#import "UkeleleDocument.h"

@interface UkeleleDocument (Housekeeping)

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

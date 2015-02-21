//
//  UKKeyboardPrintView.h
//  Ukelele Cocoa
//
//  Created by John Brownie on 21/02/2015.
//  Copyright (c) 2015 John Brownie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

	// Container for print information
@interface UKKeyboardPrintInfo : NSObject

@property (strong) NSMutableDictionary *viewDict;
@property (nonatomic) NSUInteger stateCount;
@property (nonatomic) NSUInteger modifierCount;
@property (strong) NSArray *stateList;
@property (strong) NSMutableArray *modifierList;
@property (nonatomic) NSUInteger viewHeight;
@property (nonatomic) NSUInteger availablePageHeight;
@property (nonatomic) NSUInteger viewsPerPage;

@end

@interface UKKeyboardPrintView : NSView

@property (nonatomic) BOOL allStates;
@property (nonatomic) BOOL allModifiers;
@property (nonatomic) NSString *currentState;
@property (nonatomic) NSUInteger currentModifierIndex;
@property (strong) UKKeyboardPrintInfo *printingInfo;

@end

//
//  ModifiersDataSource.h
//  Ukelele 3
//
//  Created by John Brownie on 14/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class UkeleleKeyboardObject;

#define ModifiersTableDragType @"ModifiersTableDragType"

@interface ModifiersDataSource : NSObject<NSTableViewDataSource> {
	NSMutableArray *rowArray;
	UkeleleKeyboardObject *keyboardLayout;
	NSMutableDictionary *indexDictionary;
}

- (id)initWithKeyboardObject:(UkeleleKeyboardObject *)keyboard;
- (UkeleleKeyboardObject *)keyboard;
- (void)setKeyboard:(UkeleleKeyboardObject *)keyboard;
- (void)updateKeyboard;
- (NSInteger)modifierValueForRow:(NSInteger)rowNumber column:(NSString *)columnLabel;
- (NSInteger)indexForRow:(NSInteger)rowNumber;
- (NSInteger)subindexForRow:(NSInteger)rowNumber;

@end

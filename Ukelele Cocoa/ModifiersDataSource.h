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

@interface ModifiersDataSource : NSObject<NSTableViewDataSource>

@property (NS_NONATOMIC_IOSONLY, copy) UkeleleKeyboardObject *keyboard;

- (instancetype)initWithKeyboardObject:(UkeleleKeyboardObject *)keyboard NS_DESIGNATED_INITIALIZER;
- (void)updateKeyboard;
- (NSInteger)modifierValueForRow:(NSInteger)rowNumber column:(NSString *)columnLabel;
- (NSInteger)indexForRow:(NSInteger)rowNumber;
- (NSInteger)subindexForRow:(NSInteger)rowNumber;
- (NSString *)tableView:(NSTableView *)tableView accessibilityTextForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;

@end

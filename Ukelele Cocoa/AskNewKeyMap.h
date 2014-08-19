//
//  AskNewKeyMap.h
//  Ukelele 3
//
//  Created by John Brownie on 24/05/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NewKeyMapInfo : NSObject

@property (nonatomic) NSInteger keyMapTypeSelection;
@property (nonatomic) NSInteger standardKeyMapSelection;
@property (nonatomic) NSInteger copyKeyMapSelection;
@property (nonatomic) BOOL isUnlinked;

@end

enum {
	kNewKeyMapEmpty = 0,
	kNewKeyMapStandard = 1,
	kNewKeyMapCopy = 2
};

@interface AskNewKeyMap : NSWindowController {
	IBOutlet NSButton *unlinkedCheckBox;
	void (^callBack)(NewKeyMapInfo *);
}

@property (weak, readonly) IBOutlet NSTextField *infoText;
@property (weak, readonly) IBOutlet NSMatrix *keyMapType;
@property (weak, readonly) IBOutlet NSPopUpButton *standardKeyMaps;
@property (weak, readonly) IBOutlet NSPopUpButton *makeCopyKeyMaps;

- (IBAction)selectKeyMapType:(id)sender;
- (IBAction)acceptNewKeyMap:(id)sender;
- (IBAction)cancelNewKeyMap:(id)sender;

+ (AskNewKeyMap *)askNewKeyMap;
- (void)beginNewKeyMapWithText:(NSString *)informationText
				   withKeyMaps:(NSArray *)keyMaps
					 forWindow:(NSWindow *)parentWindow
					  callBack:(void (^)(NewKeyMapInfo *))theCallBack;

@end

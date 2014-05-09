//
//  UkeleleDocumentDelegate.h
//  Ukelele 3
//
//  Created by John Brownie on 21/09/11.
//  Copyright 2011 SIL. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol UkeleleDocumentDelegate <NSObject>

- (void)modifierMapDidChange;
- (void)documentDidChange;

@end

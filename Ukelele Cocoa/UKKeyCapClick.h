//
//  UKKeyCapClick.h
//  Ukelele 3
//
//  Created by John Brownie on 14/11/13.
//
//

#import <Cocoa/Cocoa.h>

@class KeyCapView;

@protocol UKKeyCapClick <NSObject>

- (void)handleKeyCapClick:(KeyCapView *)keyCapView clickCount:(NSInteger)clickCount;

@end

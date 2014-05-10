//
//  Common.h
//  Ukelele 3
//
//  Created by John Brownie on 8/01/14.
//
//

// Common implements some code that's needed by both the app and the helper tool.

#import <Foundation/Foundation.h>

@interface Common : NSObject

+ (NSString *)authorizationRightForCommand:(SEL)command;
    // For a given command selector, return the associated authorization right name.

+ (void)setupAuthorizationRights:(AuthorizationRef)authRef;
    // Set up the default authorization rights in the authorization database.

@end

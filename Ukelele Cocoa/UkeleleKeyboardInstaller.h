//
//  UkeleleKeyboardInstaller.h
//  Ukelele 3
//
//  Created by John Brownie on 3/01/14.
//
//

#import <Foundation/Foundation.h>

@interface UkeleleKeyboardInstaller : NSObject

+ (UkeleleKeyboardInstaller *)defaultInstaller;

- (BOOL)installForCurrentUser:(NSURL *)sourceFile error:(NSError **)installError;
- (BOOL)installForAllUsers:(NSURL *)sourceFile error:(NSError **)installError;

@end

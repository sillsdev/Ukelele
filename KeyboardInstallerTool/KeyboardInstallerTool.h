//
//  KeyboardInstallerTool.h
//  Ukelele 3
//
//  Created by John Brownie on 13/01/14.
//
//

#import <Foundation/Foundation.h>

// kHelperToolMachServiceName is the Mach service name of the helper tool.  Note that the value
// here has to match the value in the MachServices dictionary in "KeyboardInstallerTool-Launchd.plist".

#define kHelperToolMachServiceName @"org.sil.Ukelele.KeyboardInstallerTool"

@protocol KeyboardInstallerProtocol

@required

- (void)getVersionWithReply:(void(^)(NSString * version))reply;

- (void)installFile:(NSURL *)sourceFile authorization:(NSData *)authData withReply:(void (^)(NSError *error))reply;

- (void)uninstallToolWithAuthorization:(NSData *)authData withReply:(void (^)(NSError *error))reply;

@end

@interface KeyboardInstallerTool : NSObject

- (instancetype)init;
- (void)run;

@end

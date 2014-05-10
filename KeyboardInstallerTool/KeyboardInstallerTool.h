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

#define kHelperToolMachServiceName @"org.sil.KeyboardInstallerTool"

@protocol KeyboardInstallerProtocol

@required

- (void)createFolder:(NSURL *)folderURL authorization:(NSData *)authData withReply:(void (^)(NSError *error))reply;

- (void)copyFile:(NSURL *)sourceURL toFile:(NSURL *)targetURL authorization:(NSData *)authData withReply:(void (^)(NSError *error))reply;

@end

@interface KeyboardInstallerTool : NSObject

- (id)init;
- (void)run;

@end

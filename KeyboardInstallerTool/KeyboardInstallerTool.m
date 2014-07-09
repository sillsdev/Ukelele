//
//  KeyboardInstallerTool.m
//  Ukelele 3
//
//  Created by John Brownie on 13/01/14.
//
//

#import "KeyboardInstallerTool.h"
#import "Common.h"

@interface KeyboardInstallerTool () <NSXPCListenerDelegate, KeyboardInstallerProtocol>

@property (atomic, strong, readwrite) NSXPCListener *listener;

@end

@implementation KeyboardInstallerTool

- (id)init
{
    self = [super init];
    if (self != nil) {
			// Set up our XPC listener to handle requests on our Mach service.
        self->_listener = [[NSXPCListener alloc] initWithMachServiceName:kHelperToolMachServiceName];
        self->_listener.delegate = self;
    }
    return self;
}

- (void)run
{
		// Tell the XPC listener to start processing requests.
	
    [self.listener resume];
    
		// Run the run loop forever.
    
    [[NSRunLoop currentRunLoop] run];
}

- (NSError *)checkAuthorization:(NSData *)authData command:(SEL)command
// Check that the client denoted by authData is allowed to run the specified command.
// authData is expected to be an NSData with an AuthorizationExternalForm embedded inside.
{
    NSError *                   error;
    OSStatus                    err;
    OSStatus                    junk;
    AuthorizationRef            authRef;
	
    assert(command != nil);
    
    authRef = NULL;
	
		// First check that authData looks reasonable.
    
    error = nil;
    if ( (authData == nil) || ([authData length] != sizeof(AuthorizationExternalForm)) ) {
        error = [NSError errorWithDomain:NSOSStatusErrorDomain code:paramErr userInfo:nil];
    }
    
		// Create an authorization ref from that the external form data contained within.
    
    if (error == nil) {
        err = AuthorizationCreateFromExternalForm([authData bytes], &authRef);
        
			// Authorize the right associated with the command.
        
        if (err == errAuthorizationSuccess) {
            AuthorizationItem   oneRight = { NULL, 0, NULL, 0 };
            AuthorizationRights rights   = { 1, &oneRight };
			
            oneRight.name = [[Common authorizationRightForCommand:command] UTF8String];
            assert(oneRight.name != NULL);
            
            err = AuthorizationCopyRights(
										  authRef,
										  &rights,
										  NULL,
										  kAuthorizationFlagExtendRights | kAuthorizationFlagInteractionAllowed,
										  NULL
										  );
        }
        if (err != errAuthorizationSuccess) {
            error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
        }
    }
	
    if (authRef != NULL) {
        junk = AuthorizationFree(authRef, 0);
        assert(junk == errAuthorizationSuccess);
    }
	
    return error;
}

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
	assert(listener == self.listener);
	assert(newConnection != nil);
	
	newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(KeyboardInstallerProtocol)];
	newConnection.exportedObject = self;
	[newConnection resume];
	return YES;
}

- (void)copyFile:(NSURL *)sourceURL toFile:(NSURL *)targetURL authorization:(NSData *)authData withReply:(void (^)(NSError *))reply {
	NSError *error = [self checkAuthorization:authData command:_cmd];
	if (error == nil) {
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSURL *parentDirectory = [targetURL URLByDeletingLastPathComponent];
		BOOL successs = [fileManager createDirectoryAtURL:parentDirectory withIntermediateDirectories:YES attributes:nil error:&error];
		NSAssert(successs, @"Should be able to create the directory");
		[fileManager copyItemAtURL:sourceURL toURL:targetURL error:&error];
	}
	reply(error);
}

@end

//
//  main.m
//  KeyboardInstallerTool
//
//  Created by John Brownie on 10/05/2014.
//  Copyright (c) 2014 John Brownie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KeyboardInstallerTool.h"

int main(int argc, const char * argv[])
{
#pragma unused(argc)
#pragma unused(argv)

	@autoreleasepool {
	    
	    KeyboardInstallerTool *tool = [[KeyboardInstallerTool alloc] init];
		[tool run];
	    
	}
    return 0;
}


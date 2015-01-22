#!/bin/sh

#  UninstallHelperTool.sh
#  Ukelele Cocoa
#
#	Remove the installer helper tool
#
#  Created by John Brownie on 22/01/2015.
#  Copyright (c) 2015 John Brownie. All rights reserved.

sudo launchctl unload /Library/LaunchDaemons/org.sil.Ukelele.KeyboardInstallerTool.plist
sudo rm /Library/LaunchDaemons/org.sil.Ukelele.KeyboardInstallerTool.plist
sudo rm /Library/PrivilegedHelperTools/org.sil.Ukelele.KeyboardInstallerTool

sudo security -q authorizationdb remove "org.sil.ukelele.installKeyboardLayout"
sudo security -q authorizationdb remove "org.sil.ukelele.uninstallHelperTool"

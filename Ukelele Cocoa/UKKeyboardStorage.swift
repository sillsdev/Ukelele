//
//  UKKeyboardStorage.swift
//  Ukelele
//
//  Created by John Brownie on 20/11/17.
//  Copyright © 2017 John Brownie. All rights reserved.
//

import Foundation

let systemsKeyboardPath = "/Library/Keyboard Layouts"
let libraryName = "Library"
let keyboardLayoutsName = "Keyboard Layouts"
let uninstalledFolderDefault = "~/Documents"
let uninstalledFolderDefaultKey = "UninstalledKeyboardLayoutsFolder"

class UKKeyboardStorage {
	let systemKeyboards = UKKeyboardCollection(folder: URL.init(fileURLWithPath: systemsKeyboardPath, isDirectory: true))
	let userKeyboards: UKKeyboardCollection
	var uninstalledKeyboards: UKKeyboardCollection
	
	static let sharedInstance = UKKeyboardStorage()
	
	init() {
		let fileManager = FileManager.default
		var userHome: URL
		if #available(OSX 10.12, *) {
			userHome = fileManager.homeDirectoryForCurrentUser
		} else {
			// Fallback on earlier versions
			userHome = URL.init(fileURLWithPath: NSHomeDirectory())
		}
		let userKeyboardsURL = userHome.appendingPathComponent(libraryName).appendingPathComponent(keyboardLayoutsName)
		userKeyboards = UKKeyboardCollection(folder: userKeyboardsURL)
		// Get the default location for the uninstalled keyboard layouts folder
		let theDefaults = UserDefaults.standard
		let theFolderPath = ((theDefaults.string(forKey: uninstalledFolderDefaultKey) ?? uninstalledFolderDefault) as NSString).expandingTildeInPath
		let theFolder = URL.init(fileURLWithPath: theFolderPath, isDirectory: true)
		uninstalledKeyboards = UKKeyboardCollection(folder: theFolder)
	}
	
	func changeUninstalledFolder(to newFolder: URL) {
		uninstalledKeyboards = UKKeyboardCollection(folder: newFolder)
		// Update the defaults
		let theDefaults = UserDefaults.standard
		theDefaults.set(newFolder.path, forKey: uninstalledFolderDefaultKey)
	}
}

//
//  UKKeyboardStorage.swift
//  Ukelele
//
//  Created by John Brownie on 20/11/17.
//  Copyright © 2017 John Brownie. All rights reserved.
//

import Cocoa

let systemsKeyboardPath = "/Library/Keyboard Layouts"
let libraryName = "Library"
let keyboardLayoutsName = "Keyboard Layouts"
let uninstalledFolderDefault = "~/Documents"
let uninstalledFolderDefaultKey = "UninstalledKeyboardLayoutsFolder"

class UKUserLibrary: NSObject {
	
	@objc func userLibrary(completion:(URL?) -> Void) {
		if let libraryURL: URL = UKFileUtilities.userLibrary() {
			let keyboardLayoutsURL = libraryURL.appendingPathComponent(keyboardLayoutsName)
			completion(keyboardLayoutsURL)
		}
		else {
			completion(nil)
		}
	}
}

class UKKeyboardStorage {
	let systemKeyboards = UKKeyboardCollection(folder: URL(fileURLWithPath: systemsKeyboardPath, isDirectory: true))
	let userKeyboards: UKKeyboardCollection
	var uninstalledKeyboards: UKKeyboardCollection
	
	static let sharedInstance = UKKeyboardStorage()
	
	init() {
		if let userLibrary = UKFileUtilities.userLibrary() {
			let userKeyboardsURL = userLibrary.appendingPathComponent(keyboardLayoutsName)
			userKeyboards = UKKeyboardCollection(folder: userKeyboardsURL)
		}
		else {
			// Really should not get here...
			let fileManager = FileManager.default
			userKeyboards = UKKeyboardCollection(folder: fileManager.homeDirectoryForCurrentUser)
		}
		// Get the default location for the uninstalled keyboard layouts folder
		let theDefaults = UserDefaults.standard
		let theFolderPath = ((theDefaults.string(forKey: uninstalledFolderDefaultKey) ?? uninstalledFolderDefault) as NSString).expandingTildeInPath
		let theFolder = URL(fileURLWithPath: theFolderPath, isDirectory: true)
		uninstalledKeyboards = UKKeyboardCollection(folder: theFolder)
	}
	
	func changeUninstalledFolder(to newFolder: URL) {
		uninstalledKeyboards = UKKeyboardCollection(folder: newFolder)
		// Update the defaults
		let theDefaults = UserDefaults.standard
		theDefaults.set(newFolder.path, forKey: uninstalledFolderDefaultKey)
	}
	
	func resetUninstalledFolder() {
		let theFolderPath = (uninstalledFolderDefault as NSString).expandingTildeInPath
		let theFolder = URL(fileURLWithPath: theFolderPath, isDirectory: true)
		changeUninstalledFolder(to: theFolder)
	}
}

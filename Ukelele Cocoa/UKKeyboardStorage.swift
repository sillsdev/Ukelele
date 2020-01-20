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
	var bookmarkData: Data?
	
	@objc func userLibrary(completion:@escaping (URL?) -> Void) {
		if let bookmarkData = bookmarkData {
			var isStale = false
			do {
				let bookmarkURL = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
				if !isStale {
					// Success, we have a valid bookmark URL
					completion(bookmarkURL)
					return
				}
			} catch {
				// Fall through
			}
		}
		let baseURL = URL(fileURLWithPath: "~/Library/Keyboard Layouts")
		let theURL = baseURL.standardizedFileURL
		let openPanel = NSOpenPanel()
		openPanel.canChooseDirectories = true
		openPanel.canChooseFiles = false
		openPanel.directoryURL = theURL
		openPanel.message = "Please locate the Keyboard Layouts folder in the Library folder of your home folder"
		openPanel.begin { (response) in
			if response == .OK {
				// Got the URL, so save it as well
				if let libraryURL = openPanel.directoryURL {
					do {
						let testFile = libraryURL.appendingPathComponent("testFile.keylayout")
						let fileManager = FileManager.default
						let result = fileManager.createFile(atPath: testFile.path, contents: nil, attributes: nil)
						if !result {
							return
						}
						self.bookmarkData = try libraryURL.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
						if self.bookmarkData != nil {
							completion(libraryURL)
						}
					} catch {
						NSApp.presentError(error)
					}
				}
				// Failure somewhere
				completion(nil)
			}
			else {
				// User cancelled
				completion(nil)
			}
		}
	}
}

class UKKeyboardStorage {
	let systemKeyboards = UKKeyboardCollection(folder: URL(fileURLWithPath: systemsKeyboardPath, isDirectory: true))
	let userKeyboards: UKKeyboardCollection
	var uninstalledKeyboards: UKKeyboardCollection
	
	static let sharedInstance = UKKeyboardStorage()
	
	init() {
		let fileManager = FileManager.default
		var userHome: URL
		userHome = fileManager.homeDirectoryForCurrentUser
		let userKeyboardsURL = userHome.appendingPathComponent(libraryName).appendingPathComponent(keyboardLayoutsName)
		userKeyboards = UKKeyboardCollection(folder: userKeyboardsURL)
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

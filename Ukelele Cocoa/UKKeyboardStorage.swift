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

class UKKeyboardStorage {
	let systemKeyboards = UKKeyboardCollection(folder: URL(fileURLWithPath: systemsKeyboardPath, isDirectory: true), isSecurityScoped: false)
	let userKeyboards: UKKeyboardCollection
	var uninstalledKeyboards: UKKeyboardCollection
	var uninstalledFolderBookmark: Data?
	var uninstalledIsSecurityScoped = false
	
	static let sharedInstance = UKKeyboardStorage()
	
	init() {
		if let userLibrary = UKFileUtilities.userLibrary() {
			let userKeyboardsURL = userLibrary.appendingPathComponent(keyboardLayoutsName)
			userKeyboards = UKKeyboardCollection(folder: userKeyboardsURL, isSecurityScoped: false)
		}
		else {
			// Really should not get here...
			let fileManager = FileManager.default
			userKeyboards = UKKeyboardCollection(folder: fileManager.homeDirectoryForCurrentUser, isSecurityScoped: false)
		}
		// Get the default location for the uninstalled keyboard layouts folder
		let theDefaults = UserDefaults.standard
		if let theBookmark = theDefaults.data(forKey: uninstalledFolderDefaultKey) {
			uninstalledFolderBookmark = theBookmark
			do {
				var isStale = false
				let uninstalledURL = try URL(resolvingBookmarkData: theBookmark, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)
				if isStale {
					uninstalledFolderBookmark = try uninstalledURL.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
				}
				let result = uninstalledURL.startAccessingSecurityScopedResource()
				assert(result, "Must be able to access the selected folder")
				// At this point we have a valid URL for the folder, so we can use it
				uninstalledKeyboards = UKKeyboardCollection(folder: uninstalledURL, isSecurityScoped: true)
				uninstalledIsSecurityScoped = true
				return
			} catch {
				uninstalledFolderBookmark = nil
			}
		}
		let theFolderPath = (uninstalledFolderDefault as NSString).expandingTildeInPath
		uninstalledIsSecurityScoped = false
		let theFolder = URL(fileURLWithPath: theFolderPath, isDirectory: true)
		uninstalledKeyboards = UKKeyboardCollection(folder: theFolder, isSecurityScoped: uninstalledIsSecurityScoped)
	}
	
	func changeUninstalledFolder(to newFolder: URL) {
		setUninstalledFolder(to: newFolder, isSecurityScoped: true)
	}
	
	func resetUninstalledFolder() {
		let theFolderPath = (uninstalledFolderDefault as NSString).expandingTildeInPath
		let theFolder = URL(fileURLWithPath: theFolderPath, isDirectory: true)
		setUninstalledFolder(to: theFolder, isSecurityScoped: false)
	}
	
	private func setUninstalledFolder(to newFolder: URL, isSecurityScoped: Bool) {
		uninstalledIsSecurityScoped = isSecurityScoped
		if isSecurityScoped {
			// Update the defaults
			do {
				uninstalledFolderBookmark = try newFolder.bookmarkData(options: [.withSecurityScope], includingResourceValuesForKeys: nil, relativeTo: nil)
				let theDefaults = UserDefaults.standard
				theDefaults.set(uninstalledFolderBookmark, forKey: uninstalledFolderDefaultKey)
			} catch let error {
				// Nothing to do if we can't create the bookmark
				NSLog("%@", error.localizedDescription)
				return
			}
		}
		uninstalledKeyboards = UKKeyboardCollection(folder: newFolder, isSecurityScoped: uninstalledIsSecurityScoped)
	}
}

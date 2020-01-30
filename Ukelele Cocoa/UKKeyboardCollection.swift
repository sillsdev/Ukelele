//
//  UKKeyboardCollection.swift
//  Ukelele
//
//  Created by John Brownie on 20/11/17.
//  Copyright © 2017 John Brownie. All rights reserved.
//

import Cocoa

let keyboardLayoutExtension = "keylayout"
let iconExtension = "icns"
let bundleExtension = "bundle"

struct KeyboardLayoutInformation {
	var keyboardLayoutName: String {
		get {
			return (fileName as NSString).deletingPathExtension
		}
	}
	var fileName = ""
	var isCollection = false
}

class UKKeyboardCollection {
	var folderURL: URL
	var collection: [KeyboardLayoutInformation]
	var collectionSize: Int { get { return collection.count } }
	var requiresAuthentication: Bool
	var isSecurityScoped: Bool
	
	init(folder: URL, isSecurityScoped scoped: Bool) {
		folderURL = folder
		collection = []
		requiresAuthentication = folderURL.absoluteString.hasPrefix("file:///Library/")
		isSecurityScoped = scoped
		
		enumerateFolder()
	}
	
	deinit {
		if isSecurityScoped {
			folderURL.stopAccessingSecurityScopedResource()
		}
	}
	
	func scanFolder() {
		collection.removeAll()
		enumerateFolder()
	}
	
	private func enumerateFolder() {
		let fileManager = FileManager.default
		do {
			let contents = try fileManager.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.skipsHiddenFiles)
			for fileURL in contents {
				// Look for appropriate files
				if fileURL.pathExtension == keyboardLayoutExtension || fileURL.pathExtension == bundleExtension {
					collection.append(KeyboardLayoutInformation(fileName: fileURL.lastPathComponent, isCollection: fileURL.pathExtension == bundleExtension))
				}
			}
			// Get them in alphabetical order
			collection.sort(by: { $0.keyboardLayoutName.compare($1.keyboardLayoutName, options: .caseInsensitive) == .orderedAscending })
		} catch let error {
			// Failed to get contents
			NSApp.presentError(error)
			collection = []
		}
	}
}

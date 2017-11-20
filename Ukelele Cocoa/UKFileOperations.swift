//
//  UKFileOperations.swift
//  Ukelele
//
//  Created by John Brownie on 20/11/17.
//  Copyright © 2017 John Brownie. All rights reserved.
//

import Foundation

let toolName = "UKFileCopier"

struct UKFileOperations {
	static func copy(from source: URL, to destination: URL, completion handler:((Bool, NSError?) -> Void)) {
		let fileManager = FileManager.default
		do {
			try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
			// Necessary while the bug noted below is present
			if fileManager.fileExists(atPath: destination.path) {
				try fileManager.removeItem(at: destination)
			}
			try fileManager.copyItem(at: source, to: destination)
			/// DANGER WILL ROBINSON -- the above call can fail to return an
			/// error when the file is not copied.  radar filed and
			/// closed as a DUPLICATE OF 30350792 which is still open.
			/// As a result I must verify that the copied file exists
			if !fileManager.fileExists(atPath: destination.path) {
				// Copy failed
				authenticatedCopy(from: source, to: destination, completion: handler)
			}
			handler(true, nil)
		}
		catch let theError as NSError {
			if theError.code == NSFileWriteNoPermissionError {
				// No permission, so we try authenticated
				authenticatedCopy(from: source, to: destination, completion: handler)
			}
			else {
				handler(false, theError)
			}
		}
		catch {
			handler(false, NSError(domain: kUKDomain, code: errorFileOperationError.code, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
		}
	}
	
	static func authenticatedCopy(from source: URL, to destination: URL, completion handler:((Bool, NSError?) -> Void)) {
		if let toolPath = Bundle.main.url(forAuxiliaryExecutable: toolName)?.path {
			let sourcePath = source.path
			let destPath = destination.path
			let scriptString = "do shell script quoted form of \"\(toolPath)\" & \" \" & quoted form of \"\(sourcePath)\" & \" \" & quoted form of \"\(destPath)\" with administrator privileges"
			let appleScript = NSAppleScript.init(source: scriptString)
			var errorDict: NSDictionary? = NSDictionary.init()
			appleScript?.executeAndReturnError(&errorDict)
			handler(true, nil)
		}
		else {
			handler(false, NSError(domain: kUKDomain, code: errorFileOperationError.code, userInfo: [NSLocalizedDescriptionKey: errorFileOperationError.localizedDescription]))
		}
	}
}

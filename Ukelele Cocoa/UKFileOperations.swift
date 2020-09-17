//
//  UKFileOperations.swift
//  Ukelele
//
//  Created by John Brownie on 20/11/17.
//  Copyright © 2017 John Brownie. All rights reserved.
//

import Cocoa

let toolName = "UKFileCopier"

struct UKFileOperations {
	static func move(from source: URL, to destination: URL, completion handler: @escaping ((Bool, NSError?) -> Void)) {
		let fileManager = FileManager.default
		do {
			try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
			// Necessary while the bug noted below is present
			if fileManager.fileExists(atPath: destination.path) {
				try fileManager.removeItem(at: destination)
			}
			try fileManager.moveItem(at: source, to: destination)
			/// DANGER WILL ROBINSON -- the above call can fail to return an
			/// error when the file is not copied.  radar filed and
			/// closed as a DUPLICATE OF 30350792 which is still open.
			/// As a result I must verify that the copied file exists
			if !fileManager.fileExists(atPath: destination.path) {
				// Copy failed
				authenticatedMove(from: source, to: destination, completion: handler)
			}
			handler(true, nil)
		}
		catch let theError as NSError {
			if theError.code == NSFileWriteNoPermissionError {
				// No permission, so we try authenticated
				authenticatedMove(from: source, to: destination, completion: handler)
			}
			else {
				handler(false, theError)
			}
		}
		catch {
			handler(false, NSError(domain: kUKDomain, code: errorFileOperationError.code, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
		}
	}
	
	static func authenticatedMove(from source: URL, to destination: URL, completion handler: @escaping ((Bool, NSError?) -> Void)) {
		if #available(OSX 10.14, *) {
			// The NSWorkspace authorizations are available
			let workspace = NSWorkspace.shared
			workspace.requestAuthorization(to: .replaceFile) { (auth, error) in
				if let authorization = auth {
					let fileManager = FileManager(authorization: authorization)
					do {
						try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
						if (try fileManager.replaceItemAt(destination, withItemAt: source)) != nil {
							// Success
							handler(true, nil)
						}
						else {
							handler(false, NSError(domain: kUKDomain, code: errorFileOperationError.code, userInfo: [:]))
						}
					} catch {
						handler(false, NSError(domain: kUKDomain, code: errorFileOperationError.code, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
					}
				}
				else {
					handler(false, error as NSError?)
				}
			}
			return
		}
		if let toolPath = Bundle.main.url(forAuxiliaryExecutable: toolName)?.path {
			let sourcePath = source.path
			let destPath = destination.path
			let scriptString = "do shell script quoted form of \"\(toolPath)\" & \" \" & quoted form of \"\(sourcePath)\" & \" \" & quoted form of \"\(destPath)\" with administrator privileges"
			let appleScript = NSAppleScript(source: scriptString)
			var errorDict: NSDictionary? = NSDictionary()
			_ = appleScript?.executeAndReturnError(&errorDict)
			handler(true, nil)
		}
		else {
			handler(false, NSError(domain: kUKDomain, code: errorFileOperationError.code, userInfo: [NSLocalizedDescriptionKey: errorFileOperationError.localizedDescription]))
		}
	}
}

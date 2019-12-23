//
//  UKFileOperations.swift
//  Ukelele
//
//  Created by John Brownie on 20/11/17.
//  Copyright © 2017 John Brownie. All rights reserved.
//

import Cocoa

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
		let workspace = NSWorkspace.shared
		workspace.requestAuthorization(to: .replaceFile) { (authorisation, error) in
			if let authorisation = authorisation {
				let fileManager = FileManager(authorization: authorisation)
				do {
					try fileManager.moveItem(at: source, to: destination)
					handler(true, nil)
				}
				catch {
					handler(false, NSError(domain: kUKDomain, code: errorFileOperationError.code, userInfo: [NSLocalizedDescriptionKey: errorFileOperationError.localizedDescription]))
				}
			}
			else {
				// Failure to get authorisation
				handler(false, NSError(domain: kUKDomain, code: errorFileOperationError.code, userInfo: [NSLocalizedDescriptionKey: errorFileOperationError.localizedDescription]))
			}
		}
	}
}

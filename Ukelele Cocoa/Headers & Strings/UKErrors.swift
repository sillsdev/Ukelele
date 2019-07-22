//
//  UKErrors.swift
//  Ukelele
//
//  Created by John Brownie on 20/11/17.
//  Copyright © 2017 John Brownie. All rights reserved.
//

import Foundation

let kUKDomain = "org.sil.UK"

// Recipe 6-1 from The Swift Developer's Cookbook
public protocol ExplanatoryErrorType: Error, CustomDebugStringConvertible {
	var reason: String {get}
	var debugDescription: String {get}
}

public extension ExplanatoryErrorType {
	var debugDescription: String {
		// Adjust for however you want the error to print
		return "\(type(of: self)): \(reason)"
	}
}

public struct UKError: ExplanatoryErrorType {
	public let reason: String
}

public struct UKErrorCode: ExplanatoryErrorType {
	public let reason: String
	public let code: Int
}

let errorFileOperationError = UKErrorCode(reason: "File operation error", code: 1)
let errorInstallOpenKeyboardError = UKErrorCode(reason: "Cannot install open key code", code: -30)

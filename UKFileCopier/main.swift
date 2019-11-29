//
//  main.swift
//  UKFileCopier
//
//  Created by John Brownie on 23/11/17.
//  Copyright © 2017 John Brownie. All rights reserved.
//

import Foundation

let argumentCount = CommandLine.argc
let argumentList = CommandLine.arguments
assert(argumentCount == 3, "Usage: \(argumentList[0]) <source file> <destination folder>")

let sourcePath = argumentList[1]
let sourceURL = URL(fileURLWithPath: sourcePath)

let destinationPath = argumentList[2]
let destinationURL = URL(fileURLWithPath: destinationPath)

let fileManager = FileManager.default
do {
	try fileManager.moveItem(at: sourceURL, to: destinationURL)
} catch {
	// Don't worry about errors at this point
}

//
//  UKOrganiserController.swift
//  Ukelele
//
//  Created by John Brownie on 21/11/17.
//  Copyright © 2017 John Brownie. All rights reserved.
//

import Cocoa

let keyboardLayoutColumnID = "KeyboardLayout"
let kindColumnID = "Kind"
let keyboardIconName = "Keyboard"
let uninstalledContextMenu = "Uninstall"
let allUsersContextMenu = "AllUsers"
let currentUserContextMenu = "CurrentUser"
let organiserDefaultKey = "OrganiserWindowLocation"

enum MenuItems: Int {
	case Uninstall = 1
	case InstallForAllUsers = 2
	case InstallForCurrentUser = 3
	case ResetUninstalledFolder = 4
}

class UKOrganiserController: NSWindowController, NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate {

	@IBOutlet var uninstalledTable: NSTableView!
	@IBOutlet var allUsersTable: NSTableView!
	@IBOutlet var currentUserTable: NSTableView!
	
	var eventStream: FSEventStreamRef? = nil
	
	override func windowDidLoad() {
        super.windowDidLoad()
		
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
		uninstalledTable.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: kUTTypeURL as String as String)])
		allUsersTable.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: kUTTypeURL as String as String)])
		currentUserTable.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: kUTTypeURL as String as String)])
		uninstalledTable.setDraggingSourceOperationMask(NSDragOperation.move, forLocal: false)
		allUsersTable.setDraggingSourceOperationMask(NSDragOperation.move, forLocal: false)
		currentUserTable.setDraggingSourceOperationMask(NSDragOperation.move, forLocal: false)
		
		// Create the monitor
		setupMonitor()
		
		// Restore the position if possible
		let theDefaults = UserDefaults.standard
		if let frameData = theDefaults.array(forKey: organiserDefaultKey) as? [Double] {
			let theFrame = NSRect(x: frameData[0], y: frameData[1], width: frameData[2], height: frameData[3])
			self.window?.setFrame(theFrame, display: false)
		}
    }

	func setupMonitor() {
		if let currentStream = eventStream {
			// Need to remove the old event stream
			FSEventStreamStop(currentStream)
			FSEventStreamUnscheduleFromRunLoop(currentStream, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
			FSEventStreamRelease(currentStream)
			eventStream = nil
		}
		let theStorage = UKKeyboardStorage.sharedInstance
		let scanTarget = [theStorage.uninstalledKeyboards.folderURL.path, theStorage.systemKeyboards.folderURL.path, theStorage.userKeyboards.folderURL.path]
		let scanCallback: FSEventStreamCallback = { (streamRef: ConstFSEventStreamRef, context: UnsafeMutableRawPointer?, count: Int, streamPtrs: UnsafeMutableRawPointer, flags: UnsafePointer<FSEventStreamEventFlags>, eventIDs: UnsafePointer<FSEventStreamEventId>) in
			// Here we will force a scan
			let theController = Unmanaged<UKOrganiserController>.fromOpaque(context!).takeUnretainedValue()
			// Could limit this to only the folder changed, if necessary
			theController.reloadTableData()
		}
		var theContext = FSEventStreamContext(version: 0, info: UnsafeMutableRawPointer(Unmanaged<UKOrganiserController>.passUnretained(self).toOpaque()), retain: nil, release: nil, copyDescription: nil)
		let scanInterval: CFTimeInterval = 2.0
		let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagIgnoreSelf)
		eventStream = FSEventStreamCreate(nil, scanCallback, &theContext, scanTarget as CFArray, FSEventStreamEventId(kFSEventStreamEventIdSinceNow), scanInterval, flags)
	}
	
	func reloadTableData() {
		let theStorage = UKKeyboardStorage.sharedInstance
		// Try to preserve selections
		let uninstalledSelectedItem = uninstalledTable.selectedRow == -1 ? nil : theStorage.uninstalledKeyboards.collection[uninstalledTable.selectedRow].keyboardLayoutName
		let allUsersSelectedItem = allUsersTable.selectedRow == -1 ? nil : theStorage.systemKeyboards.collection[allUsersTable.selectedRow].keyboardLayoutName
		let currentUserSelectedItem = currentUserTable.selectedRow == -1 ? nil : theStorage.systemKeyboards.collection[currentUserTable.selectedRow].keyboardLayoutName
		theStorage.uninstalledKeyboards.scanFolder()
		theStorage.systemKeyboards.scanFolder()
		theStorage.userKeyboards.scanFolder()
		uninstalledTable.reloadData()
		allUsersTable.reloadData()
		currentUserTable.reloadData()
		// Reset selections
		resetSelection(uninstalledTable, collection: theStorage.uninstalledKeyboards, selection: uninstalledSelectedItem)
		resetSelection(allUsersTable, collection: theStorage.systemKeyboards, selection: allUsersSelectedItem)
		resetSelection(currentUserTable, collection: theStorage.userKeyboards, selection: currentUserSelectedItem)
	}
	
	private func resetSelection(_ table: NSTableView!, collection collectionName: UKKeyboardCollection, selection: String?) {
		if let selectedText = selection {
			let index = collectionName.collection.index(where: { (info: KeyboardLayoutInformation) -> Bool in
				return info.keyboardLayoutName == selectedText
			})
			if index != nil {
				table.selectRowIndexes(IndexSet.init(integer: index!), byExtendingSelection: false)
			}
		}
	}
	
	override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		switch menuItem.tag {
		case MenuItems.Uninstall.rawValue:
			// Uninstall
			if allUsersTable.clickedRow != -1 || currentUserTable.clickedRow != -1 {
				return true
			}
			if self.window?.firstResponder == uninstalledTable {
				// Uninstalled table
				return false
			}
			else if self.window?.firstResponder == allUsersTable {
				return allUsersTable.selectedRow != -1
			}
			else if self.window?.firstResponder == currentUserTable {
				return currentUserTable.selectedRow != -1
			}
			return false
			
		case MenuItems.InstallForAllUsers.rawValue:
			// Install for all users
			if uninstalledTable.clickedRow != -1 || currentUserTable.clickedRow != -1 {
				return true
			}
			if self.window?.firstResponder == uninstalledTable {
				// Uninstalled table
				return uninstalledTable.selectedRow != -1
			}
			else if self.window?.firstResponder == allUsersTable {
				return false
			}
			else if self.window?.firstResponder == currentUserTable {
				return currentUserTable.selectedRow != -1
			}
			return false
			
		case MenuItems.InstallForCurrentUser.rawValue:
			// Install for current user
			if uninstalledTable.clickedRow != -1 || allUsersTable.clickedRow != -1 {
				return true
			}
			if self.window?.firstResponder == uninstalledTable {
				// Uninstalled table
				return uninstalledTable.selectedRow != -1
			}
			else if self.window?.firstResponder == allUsersTable {
				return allUsersTable.selectedRow != -1
			}
			else if self.window?.firstResponder == currentUserTable {
				return false
			}
			return false
			
		case MenuItems.ResetUninstalledFolder.rawValue:
			return true
			
		default:
			return false
		}
	}
	
	// MARK: Actions
	
	@IBAction func selectFolder(sender: Any) {
		selectUninstalledFolder()
	}
	
	func selectUninstalledFolder() {
		// Open an open panel for the folder
		let thePanel = NSOpenPanel.init()
		thePanel.canChooseDirectories = true
		thePanel.canChooseFiles = false
		thePanel.message = "Select the folder where uninstalled keyboard layouts are kept"
		thePanel.canCreateDirectories = true
		let theURL = UKKeyboardStorage.sharedInstance.uninstalledKeyboards.folderURL
		thePanel.directoryURL = theURL
		thePanel.beginSheetModal(for: self.window!) { (result: NSApplication.ModalResponse) in
			if result == NSApplication.ModalResponse.OK {
				// Got the folder
				UKKeyboardStorage.sharedInstance.changeUninstalledFolder(to: thePanel.directoryURL!)
				self.setupMonitor()
				self.reloadTableData()
			}
		}
	}
	
	@IBAction func resetUninstalledFolder(sender: Any) {
		let theStorage = UKKeyboardStorage.sharedInstance
		theStorage.resetUninstalledFolder()
	}
	
	@IBAction func uninstallKeyboardLayout(sender: Any) {
		// Need to find what is selected
		if let menuItem = sender as? NSMenuItem {
			if let menu = menuItem.menu {
				let theStorage = UKKeyboardStorage.sharedInstance
				var sourceBase: URL? = nil
				var fileName: String? = nil
				if menu.identifier == NSUserInterfaceItemIdentifier(rawValue: allUsersContextMenu) {
					// We're coming from the contextual menu in the all users table
					sourceBase = theStorage.systemKeyboards.folderURL
					fileName = theStorage.systemKeyboards.collection[allUsersTable.clickedRow].fileName
				}
				else if menu.identifier == NSUserInterfaceItemIdentifier(rawValue: currentUserContextMenu) {
					// We're coming from the contextual menu in the current user table
					sourceBase = theStorage.userKeyboards.folderURL
					fileName = theStorage.userKeyboards.collection[currentUserTable.clickedRow].fileName
				}
				else if menu.title == "File" {
					// We're coming from the main menu
					if self.window?.firstResponder == allUsersTable {
						sourceBase = theStorage.systemKeyboards.folderURL
						fileName = theStorage.systemKeyboards.collection[allUsersTable.selectedRow].fileName
					}
					else if self.window?.firstResponder == currentUserTable {
						sourceBase = theStorage.userKeyboards.folderURL
						fileName = theStorage.userKeyboards.collection[currentUserTable.selectedRow].fileName
					}
				}
				if let sourceBase = sourceBase, let fileName = fileName {
					let sourceURL = sourceBase.appendingPathComponent(fileName)
					let destinationURL = theStorage.uninstalledKeyboards.folderURL.appendingPathComponent(fileName)
					moveKeyboard(from: sourceURL, to: destinationURL, installing: false)
				}
			}
		}
	}
	
	@IBAction func installForAllUsers(sender: Any) {
		if let menuItem = sender as? NSMenuItem {
			if let menu = menuItem.menu {
				let theStorage = UKKeyboardStorage.sharedInstance
				var sourceBase: URL? = nil
				var fileName: String? = nil
				if menu.identifier == NSUserInterfaceItemIdentifier(rawValue: uninstalledContextMenu) {
					// We're coming from the contextual menu in the uninstalled table
					sourceBase = theStorage.uninstalledKeyboards.folderURL
					fileName = theStorage.uninstalledKeyboards.collection[uninstalledTable.clickedRow].fileName
				}
				else if menu.identifier == NSUserInterfaceItemIdentifier(rawValue: currentUserContextMenu) {
					// We're coming from the contextual menu in the current user table
					sourceBase = theStorage.userKeyboards.folderURL
					fileName = theStorage.userKeyboards.collection[currentUserTable.clickedRow].fileName
				}
				else if menu.title == "File" {
					// We're coming from the main menu
					if self.window?.firstResponder == uninstalledTable {
						sourceBase = theStorage.uninstalledKeyboards.folderURL
						fileName = theStorage.uninstalledKeyboards.collection[uninstalledTable.selectedRow].fileName
					}
					else if self.window?.firstResponder == currentUserTable {
						sourceBase = theStorage.userKeyboards.folderURL
						fileName = theStorage.userKeyboards.collection[currentUserTable.selectedRow].fileName
					}
				}
				if let sourceBase = sourceBase, let fileName = fileName {
					let sourceURL = sourceBase.appendingPathComponent(fileName)
					let destinationURL = theStorage.systemKeyboards.folderURL.appendingPathComponent(fileName)
					moveKeyboard(from: sourceURL, to: destinationURL, installing: true)
				}
			}
		}
	}
	
	@IBAction func installForCurrentUser(sender: Any) {
		if let menuItem = sender as? NSMenuItem {
			if let menu = menuItem.menu {
				let theStorage = UKKeyboardStorage.sharedInstance
				var sourceBase: URL? = nil
				var fileName: String? = nil
				if menu.identifier == NSUserInterfaceItemIdentifier(rawValue: uninstalledContextMenu) {
					// We're coming from the contextual menu in the uninstalled table
					sourceBase = theStorage.uninstalledKeyboards.folderURL
					fileName = theStorage.uninstalledKeyboards.collection[uninstalledTable.clickedRow].fileName
				}
				else if menu.identifier == NSUserInterfaceItemIdentifier(rawValue: allUsersContextMenu) {
					// We're coming from the contextual menu in the all users table
					sourceBase = theStorage.systemKeyboards.folderURL
					fileName = theStorage.systemKeyboards.collection[allUsersTable.clickedRow].fileName
				}
				else if menu.title == "File" {
					// We're coming from the main menu
					if self.window?.firstResponder == uninstalledTable {
						sourceBase = theStorage.uninstalledKeyboards.folderURL
						fileName = theStorage.uninstalledKeyboards.collection[uninstalledTable.selectedRow].fileName
					}
					else if self.window?.firstResponder == allUsersTable {
						sourceBase = theStorage.systemKeyboards.folderURL
						fileName = theStorage.systemKeyboards.collection[allUsersTable.selectedRow].fileName
					}
				}
				if let sourceBase = sourceBase, let fileName = fileName {
					let sourceURL = sourceBase.appendingPathComponent(fileName)
					let destinationURL = theStorage.userKeyboards.folderURL.appendingPathComponent(fileName)
					moveKeyboard(from: sourceURL, to: destinationURL, installing: true)
				}
			}
		}
	}
	
	func moveKeyboard(from source: URL, to destination: URL, installing: Bool) {
		if installing {
			// Close the file if required
			if !closeFileIfNecessary(theFile: source as NSURL) {
				// Could not close
				return
			}
		}
		let fileName = source.lastPathComponent
		if fileName.hasSuffix(keyboardLayoutExtension) {
			// Look for an icon file
			let iconFileName = fileName.replacingOccurrences(of: ".\(keyboardLayoutExtension)", with: ".\(iconExtension)")
			let iconSource = source.deletingLastPathComponent().appendingPathComponent(iconFileName)
			if FileManager.default.fileExists(atPath: iconSource.path) {
				let iconDestination = destination.deletingLastPathComponent().appendingPathComponent(iconFileName)
				moveFile(from: iconSource, to: iconDestination) { (success, theError) in
					if success {
						reloadTableData()
					}
					else {
						NSApp.presentError(theError!)
					}
				}
			}
		}
		moveFile(from: source, to: destination) { (success, error) in
			if success {
				reloadTableData()
				if installing {
					recommendLogout()
				}
			}
			else {
				NSApp.presentError(error!)
			}
		}
	}
	
	@objc func moveFile(from source: URL, to destination: URL, completion: (Bool, NSError?) -> Void) {
		UKFileOperations.move(from: source, to: destination, completion: completion)
	}
	
	func closeFileIfNecessary(theFile: NSURL) -> Bool {
		let docController = NSDocumentController.shared
		for document in docController.documents {
			if (document as NSDocument).fileURL?.absoluteString == theFile.absoluteString {
				// Close the document
				let errorString = "The keyboard layout \(String(describing: (document as NSDocument).fileURL?.lastPathComponent)) is open. Do you want to close it or cancel?"
				let theError = NSError(domain: "org.sil.Ukelele", code: errorInstallOpenKeyboardError.code, userInfo: [NSLocalizedDescriptionKey: errorString])
				let theAlert = NSAlert.init(error: theError)
				theAlert.addButton(withTitle: "Close")
				theAlert.addButton(withTitle: "Cancel")
				theAlert.informativeText = "A keyboard layout that has been installed must not be edited, as it may cause the system to crash"
				switch(theAlert.runModal()) {
				case NSApplication.ModalResponse.alertFirstButtonReturn:
					document.close()
					return true
				default:
					return false
				}
			}
		}
		return true
	}
	
	// MARK: User interaction
	
	func recommendLogout() {
		let infoString = "Your should log out"
		let theError = NSError(domain: "org.sil.Ukelele", code: 0, userInfo: [NSLocalizedDescriptionKey: infoString])
		let theAlert = NSAlert.init(error: theError)
		theAlert.alertStyle = .informational
		theAlert.addButton(withTitle: "OK")
		theAlert.informativeText = "After installing a keyboard layout, it is recommended that you log out and log in again, or restart your computer."
		_ = theAlert.runModal()
	}
	
	// MARK: Data source methods
	
	func numberOfRows(in tableView: NSTableView) -> Int {
		let theStorage = UKKeyboardStorage.sharedInstance
		switch tableView {
		case uninstalledTable:
			return theStorage.uninstalledKeyboards.collectionSize
		case allUsersTable:
			return theStorage.systemKeyboards.collectionSize
		case currentUserTable:
			return theStorage.userKeyboards.collectionSize
		default:
			return 0
		}
	}
	
	func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
		let theStorage = UKKeyboardStorage.sharedInstance
		switch tableView {
		case uninstalledTable:
			return theStorage.uninstalledKeyboards.collection[row].keyboardLayoutName
		case allUsersTable:
			return theStorage.systemKeyboards.collection[row].keyboardLayoutName
		case currentUserTable:
			return theStorage.userKeyboards.collection[row].keyboardLayoutName
		default:
			return nil
		}
	}
	
	// MARK: Drag and Drop support
	
	func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
		// Put appropriate data onto the pasteboard
		let theStorage = UKKeyboardStorage.sharedInstance
		let theCollection = tableView == uninstalledTable ? theStorage.uninstalledKeyboards : tableView == allUsersTable ? theStorage.systemKeyboards : theStorage.userKeyboards
		let baseURL = tableView == uninstalledTable ? theStorage.uninstalledKeyboards.folderURL : tableView == allUsersTable ? theStorage.systemKeyboards.folderURL : theStorage.userKeyboards.folderURL
		var theData: [NSURL] = []
		for theIndex in rowIndexes {
			theData.append(baseURL.appendingPathComponent(theCollection.collection[theIndex].fileName) as NSURL)
		}
		pboard.writeObjects(theData)
		return true
	}
	
	func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
		if (info.draggingSource() as? NSTableView) == tableView {
			// Cannot drag within a table
			return []
		}
		if dropOperation == .on {
			// Do not accept drops onto rows
			return []
		}
		// Other types of drag should be OK, as long as the file type is correct
		var validFile = false
		info.enumerateDraggingItems(options: [], for: self.window?.contentView, classes: [NSURL.self], searchOptions: [:]) { (theItem, _, _) in
			if let sourceURL = theItem.item as? NSURL {
				if sourceURL.pathExtension == bundleExtension || sourceURL.pathExtension == keyboardLayoutExtension {
					validFile = true
				}
			}
		}
		return validFile ? .move : []
	}
	
	func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
		let theStorage = UKKeyboardStorage.sharedInstance
		let baseURL = tableView == uninstalledTable ? theStorage.uninstalledKeyboards.folderURL : tableView == allUsersTable ? theStorage.systemKeyboards.folderURL : theStorage.userKeyboards.folderURL
		var fileMoved = false
		info.enumerateDraggingItems(options: [], for: self.window?.contentView, classes: [NSURL.self], searchOptions: [:]) { (theItem, _, _) in
			if let sourceURL = theItem.item as? NSURL {
				// If the source is the working folder, we need to check whether the file is open in Ukelele, and close it if so
				if (tableView != self.uninstalledTable) {
					if (!self.closeFileIfNecessary(theFile: sourceURL)) {
						// Cancel
						return
					}
				}
				if sourceURL.pathExtension == bundleExtension || sourceURL.pathExtension == keyboardLayoutExtension {
					fileMoved = true
					let destURL = baseURL.appendingPathComponent(sourceURL.lastPathComponent!)
					self.moveKeyboard(from: sourceURL as URL, to: destURL, installing: tableView != self.uninstalledTable)
				}
			}
		}
		return fileMoved
	}
	
	func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
		reloadTableData()
	}
	
	// MARK: Delegate methods
	
	func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
		if tableView == uninstalledTable || tableView == allUsersTable || tableView == currentUserTable {
			let theStorage = UKKeyboardStorage.sharedInstance
			let theCollection = tableView == uninstalledTable ? theStorage.uninstalledKeyboards : tableView == allUsersTable ? theStorage.systemKeyboards : theStorage.userKeyboards
			if tableColumn?.identifier.rawValue == keyboardLayoutColumnID {
				var myView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: keyboardLayoutColumnID), owner: self)
				if myView == nil {
					myView = NSTableCellView.init(frame: NSMakeRect(0.0, 0.0, tableColumn!.width, 20.0))
					myView?.identifier = NSUserInterfaceItemIdentifier(rawValue: keyboardLayoutColumnID)
				}
				(myView as! NSTableCellView).textField?.stringValue = theCollection.collection[row].keyboardLayoutName
				return myView
			}
			else if tableColumn?.identifier.rawValue == kindColumnID {
				var imageView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: kindColumnID), owner: self)
				if imageView == nil {
					imageView = NSTableCellView.init(frame: NSMakeRect(0.0, 0.0, tableColumn!.width, 20.0))
					imageView?.identifier = NSUserInterfaceItemIdentifier(rawValue: kindColumnID)
				}
				let theImage = NSImage.init(named: theCollection.collection[row].isCollection ? NSImage.Name.folder : NSImage.Name(keyboardIconName))
				(imageView as! NSTableCellView).imageView?.image = theImage
				return imageView
			}
			else {
				return nil
			}
		}
		else {
			return nil
		}
	}
	
	func windowDidMove(_ notification: Notification) {
		if let theWindow = self.window {
			let newFrame = theWindow.frame
			let theDefaults = UserDefaults.standard
			theDefaults.set([newFrame.origin.x, newFrame.origin.y, newFrame.size.width, newFrame.size.height], forKey: organiserDefaultKey)
		}
	}
}

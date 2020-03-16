//
//  UKTroubleShootingController.swift
//  Ukelele
//
//  Created by John Brownie on 10/2/20.
//  Copyright © 2020 John Brownie. All rights reserved.
//

import Cocoa
import WebKit

class UKTroubleShootingController: NSWindowController {
	@IBOutlet var webContentView: WKWebView!
	
    override func windowDidLoad() {
        super.windowDidLoad()
		guard let troubleShootingURL = Bundle.main.url(forResource: "Troubleshooting", withExtension: "html"),
			troubleShootingURL.isFileURL else { return }
		let fileManager = FileManager.default
		let htmlString = String(bytes: fileManager.contents(atPath: troubleShootingURL.path) ?? Data(), encoding: .utf8) ?? ""
		webContentView.loadHTMLString(htmlString, baseURL: nil)
    }
}

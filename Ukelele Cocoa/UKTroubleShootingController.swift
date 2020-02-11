//
//  UKTroubleShootingController.swift
//  Ukelele
//
//  Created by John Brownie on 10/2/20.
//  Copyright © 2020 John Brownie. All rights reserved.
//

import Cocoa

class UKTroubleShootingController: NSWindowController, NSUserInterfaceValidations {
	@IBOutlet var contentView: NSView!
	@IBOutlet var goBackButton: NSButton!
	@IBOutlet var goForwardButton: NSButton!
	
	var webView: UKWebView?
	var canGoBack: Bool { get {
		guard let webView = webView else { return false }
		return webView.canGoBack()
		}
	}
	var canGoForward: Bool { get {
		guard let webView = webView else { return false }
		return webView.canGoForward()
		}
	}
	
    override func windowDidLoad() {
        super.windowDidLoad()
		let frame = contentView.frame
		if #available(OSX 10.10, *) {
			webView = UKWebViewWebKit(frame: frame)
		}
		else {
			webView = UKWebViewLegacy(frame: frame)
		}
		guard let webView = webView else { return }
		contentView.addSubview(webView)
		contentView.addConstraints([NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0.0), NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1.0, constant: 0.0), NSLayoutConstraint(item: webView, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1.0, constant: 0.0), NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0.0)])
		guard let troubleShootingURL = Bundle.main.url(forResource: "Troubleshooting", withExtension: "html") else { return }
		webView.loadFileURL(url: troubleShootingURL)
    }
	
	func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
		if item.action == #selector(goBack(_:)) {
			return canGoBack
		}
		if item.action == #selector(goForward(_:)) {
			return canGoForward
		}
		return false
	}
	
	@IBAction func goBack(_ sender: Any) {
		guard let webView = webView else { return }
		webView.goBack()
	}
	
	@IBAction func goForward(_ sender: Any) {
		guard let webView = webView else { return }
		webView.goForward()
	}
}

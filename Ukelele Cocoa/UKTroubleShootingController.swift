//
//  UKTroubleShootingController.swift
//  Ukelele
//
//  Created by John Brownie on 10/2/20.
//  Copyright © 2020 John Brownie. All rights reserved.
//

import Cocoa

class UKTroubleShootingController: NSWindowController {
	@IBOutlet var webContentView: NSView!
	
	var webView: UKWebView?
	
    override func windowDidLoad() {
        super.windowDidLoad()
		let frame = webContentView.frame
		if #available(OSX 10.10, *) {
			webView = UKWebViewWebKit(frame: frame)
		}
		else {
			webView = UKWebViewLegacy(frame: frame)
		}
		guard let webView = webView else { return }
		webContentView.addSubview(webView)
		webContentView.translatesAutoresizingMaskIntoConstraints = false
		webView.translatesAutoresizingMaskIntoConstraints = false
		let variableBindings = ["webView": webView]
		let constraints1 = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[webView]-0-|", options: [], metrics: nil, views: variableBindings)
		let constraints2 = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[webView]-0-|", options: [], metrics: nil, views: variableBindings)
		if #available(OSX 10.10, *) {
			NSLayoutConstraint.activate(constraints1)
			NSLayoutConstraint.activate(constraints2)
		} else {
			// Fallback on earlier versions
			webContentView.addConstraints(constraints1)
			webContentView.addConstraints(constraints2)
		}
		guard let troubleShootingURL = Bundle.main.url(forResource: "Troubleshooting", withExtension: "html") else { return }
		webView.loadFileURL(url: troubleShootingURL)
    }
}

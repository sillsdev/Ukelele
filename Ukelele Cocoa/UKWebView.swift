//
//  UKWebView.swift
//  Ukelele
//
//  Created by John Brownie on 10/2/20.
//  Copyright © 2020 John Brownie. All rights reserved.
//

import Cocoa
import WebKit

class UKWebView: NSView {
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}
	
	func loadFileURL(url: URL) {
		// Do nothing in default implementation
	}
}

@available(OSX 10.10, *)
class UKWebViewWebKit: UKWebView {
	var view: WKWebView?
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		let configuration = WKWebViewConfiguration()
		view = WKWebView(frame: frameRect, configuration: configuration)
		guard let webView = view else { return }
		addSubview(webView)
		webView.translatesAutoresizingMaskIntoConstraints = false
		let variableBindings = ["webView": webView]
		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[webView]-0-|", options: [], metrics: nil, views: variableBindings))
		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[webView]-0-|", options: [], metrics: nil, views: variableBindings))
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		view = WKWebView(coder: coder)
	}
	
	override func loadFileURL(url: URL) {
		guard let webView = view, url.isFileURL else { return }
		let fileManager = FileManager.default
		let htmlString = String(bytes: fileManager.contents(atPath: url.path) ?? Data(), encoding: .utf8) ?? ""
		webView.loadHTMLString(htmlString, baseURL: nil)
	}
}

//@available(OSX, introduced: 10.2, unavailable, deprecated: 10.14)
class UKWebViewLegacy: UKWebView {
	var view: WebView?
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		view = WebView(frame: frameRect)
		guard let view = view else { return }
		addSubview(view)
		let variableBindings = ["webView": view]
		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-5-[webView]-5-|", options: [], metrics: nil, views: variableBindings))
		addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[webView]-5-|", options: [], metrics: nil, views: variableBindings))
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		view = WebView(coder: coder)
	}
	
	override func loadFileURL(url: URL) {
		guard let webView = view else { return }
		webView.mainFrame.load(URLRequest(url: url))
	}
}

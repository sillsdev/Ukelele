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
    
	func canGoBack() -> Bool {
		return false
	}
	
	func canGoForward() -> Bool {
		return false
	}
	
	func goBack() {
		// Do nothing
	}
	
	func goForward() {
		// Do nothing
	}
}

@available(OSX 10.10, *)
class UKWebViewWebKit: UKWebView {
	var view: WKWebView?
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		let configuration = WKWebViewConfiguration()
		view = WKWebView(frame: frameRect, configuration: configuration)
		guard let view = view else { return }
		addSubview(view)
		addConstraints([NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0), NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0), NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0), NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)])
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
	
	override func canGoBack() -> Bool {
		guard let webView = view else { return false }
		return webView.canGoBack
	}
	
	override func canGoForward() -> Bool {
		guard let webView = view else { return false }
		return webView.canGoForward
	}
	
	override func goBack() {
		guard let webView = view else { return }
		webView.goBack()
	}
	
	override func goForward() {
		guard let webView = view else { return }
		webView.goForward()
	}
}

//@available(OSX, introduced: 10.2, unavailable, deprecated: 10.10)
class UKWebViewLegacy: UKWebView {
	var view: WebView?
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		view = WebView(frame: frameRect)
		guard let view = view else { return }
		addSubview(view)
		addConstraints([NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0), NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0), NSLayoutConstraint(item: view, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0), NSLayoutConstraint(item: view, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)])
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		view = WebView(coder: coder)
	}
	
	override func loadFileURL(url: URL) {
		guard let webView = view else { return }
		webView.mainFrame.load(URLRequest(url: url))
	}
	
	override func canGoBack() -> Bool {
		guard let webView = view else { return false }
		return webView.canGoBack
	}
	
	override func canGoForward() -> Bool {
		guard let webView = view else { return false }
		return webView.canGoForward
	}
	
	override func goBack() {
		guard let webView = view else { return }
		webView.goBack()
	}
	
	override func goForward() {
		guard let webView = view else { return }
		webView.goForward()
	}
}

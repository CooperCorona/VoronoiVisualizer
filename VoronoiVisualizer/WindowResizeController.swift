//
//  WindowResizeController.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 9/17/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Cocoa

protocol ResizableViewController {
    func viewDidResize()
}

class WindowResizeController: NSWindowController, NSWindowDelegate {

    override func windowDidLoad() {
        self.window?.acceptsMouseMovedEvents = true
    }
    
    func windowDidResize(_ notification: Notification) {
        (self.contentViewController as? ResizableViewController)?.viewDidResize()
    }
    
}

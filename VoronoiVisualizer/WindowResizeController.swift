//
//  WindowResizeController.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 9/17/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Cocoa

class WindowResizeController: NSWindowController, NSWindowDelegate {

    func windowDidResize(_ notification: Notification) {
        (self.contentViewController as? ViewController)?.viewDidResize()
    }
    
}

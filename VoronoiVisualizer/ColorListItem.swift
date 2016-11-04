//
//  ColorListItem.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 11/2/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Cocoa

class ColorListItem: NSControl {

    var color = NSColor.white {
        didSet {
            self.layer?.backgroundColor = self.color.cgColor
        }
    }
    var isSelected:Bool = false {
        didSet {
            if self.isSelected {
                self.layer?.borderColor = NSColor.white.cgColor
            } else {
                self.layer?.borderColor = NSColor.black.cgColor
            }
        }
    }
    unowned let owner:ColorList
    
    init(frame frameRect: NSRect, color:NSColor, owner:ColorList) {
        self.owner = owner
        self.color = color
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.backgroundColor = self.color.cgColor
        self.layer?.borderColor = NSColor.black.cgColor
        self.layer?.borderWidth = 1.0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func mouseDown(with event: NSEvent) {
        self.owner.itemSelected(item: self)
    }
    
}

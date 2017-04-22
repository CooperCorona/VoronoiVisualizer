//
//  ColorAnchors.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 4/20/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Cocoa
import CoronaConvenience
import CoronaStructures

class ColorAnchors: NSObject {

    // MARK: - Types
    
    struct ColorAnchor {
        var point:CGPoint
        var color:SCVector4
        var mobile:Bool
        weak var view:NSView? = nil
    }
    
    // MARK: - Properties
    
    private var anchors:[ColorAnchor] = []
    private var selectedAnchorIndex:Int? = nil
    private var initialMousePosition:CGPoint? = nil
    var gradient:LightSourceGradient<SCVector4> {
        var gradient = LightSourceGradient(zero: SCVector4())
        for anchor in self.anchors {
            gradient.add(value: anchor.color, at: anchor.point / self.viewSize)
        }
        return gradient
    }
    var viewSize:CGSize {
        didSet {
            self.anchors = self.anchors.map() {
                var val = $0
                val.point = $0.point * self.viewSize / oldValue
                if let view = val.view {
                    view.frame.center = view.frame.width / 2.0 + val.point
                }
                return val
            }
        }
    }
    
    // MARK: - Setup
    
    init(viewSize:CGSize) {
        self.viewSize = viewSize
        super.init()
    }
    
    // MARK: - Logic
    
    func add(point:CGPoint, color: SCVector4, view:NSView, mobile:Bool = true) {
        self.anchors.append(ColorAnchor(point: point, color: color, mobile: mobile, view: view))
        view.frame.center = point + view.frame.width / 2.0
        view.layer?.backgroundColor = NSColor(vector4: color).cgColor
    }
    
    func add(point:CGPoint, view:NSView, mobile:Bool = true) {
        let color = self.gradient.color(at: point / viewSize)
        self.add(point: point, color: color, view: view, mobile: mobile)
    }
    
    func remove(point:CGPoint) {
        for anchor in self.anchors.filter({ $0.point == point }) {
            anchor.view?.removeFromSuperview()
        }
        self.anchors = self.anchors.filter() { $0.point != point }
    }
    
    func removeSelected() {
        guard let index = self.selectedAnchorIndex else {
            return
        }
        self.selectedAnchorIndex = nil
        self.anchors[index].view?.removeFromSuperview()
        self.anchors.remove(at: index)
    }
    
    func set(color:NSColor) {
        guard let index = self.selectedAnchorIndex else {
            return
        }
        guard self.anchors[index].mobile else {
            return
        }
        self.anchors[index].color = color.getVector4()
        self.anchors[index].view?.layer?.backgroundColor = color.cgColor
    }
    
    // MARK: - Mouse Actions
    
    private func select(view:NSView) {
        view.layer?.borderColor = NSColor.white.cgColor
    }
    
    private func select(index:Int?) {
        if let index = index, let view = self.anchors[index].view {
            self.select(view: view)
        }
    }
    
    private func unselect(view:NSView) {
        view.layer?.borderColor = NSColor.black.cgColor
    }
    
    private func unselect(index:Int?) {
        if let index = index, let view = self.anchors[index].view {
            self.unselect(view: view)
        }
    }
    
    private func anchorIndex(at point:CGPoint) -> Int? {
        for (i, anchor) in self.anchors.enumerated() {
            if let view = anchor.view, view.frame.center.distanceFrom(point + view.frame.width / 2.0) <= view.frame.size.width / 2.0 {
                return i
            }
        }
        return nil
    }
    
    func mouseDown(at:CGPoint) -> ColorAnchor? {
        self.unselect(index: self.selectedAnchorIndex)
        guard let index = self.anchorIndex(at: at) else {
            self.selectedAnchorIndex = nil
            self.initialMousePosition = nil
            return nil
        }
        self.initialMousePosition = at
        self.selectedAnchorIndex = index
        if let view = self.anchors[index].view {
            self.select(view: view)
        }
        return self.anchors[index]
    }
    
    func mouseDragged(at:CGPoint) {
        guard let selectedIndex = self.selectedAnchorIndex, self.anchors[selectedIndex].mobile else {
            return
        }
        guard let oldMouse = self.initialMousePosition else {
            return
        }
        self.anchors[selectedIndex].point += at - oldMouse
        
        if self.anchors[selectedIndex].point.x < 0.0 {
            self.anchors[selectedIndex].point.x = 0.0
        } else if self.anchors[selectedIndex].point.x > self.viewSize.width {
            self.anchors[selectedIndex].point.x = self.viewSize.width
        }
        if self.anchors[selectedIndex].point.y < 0.0 {
            self.anchors[selectedIndex].point.y = 0.0
        } else if self.anchors[selectedIndex].point.y > self.viewSize.height {
            self.anchors[selectedIndex].point.y = self.viewSize.height
        }
        
        if let view = self.anchors[selectedIndex].view {
            view.frame.center = self.anchors[selectedIndex].point + view.frame.width / 2.0
        }
        self.initialMousePosition = at
    }
    
}

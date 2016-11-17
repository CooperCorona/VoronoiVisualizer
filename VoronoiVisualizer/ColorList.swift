//
//  ColorList.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 11/2/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Cocoa
import CoronaConvenience
import CoronaStructures

protocol ColorListDelegate: class {
    
    func selected(color:NSColor)
    
}

class ColorList: NSObject {

    private(set) var views:[ColorListItem] = []
    private(set) var selectedViewIndex:Int? = nil
    var selectedItem:ColorListItem? {
        if let index = self.selectedViewIndex {
            return self.views[index]
        } else {
            return nil
        }
    }
    var selectedColor:NSColor? {
        if let selectedIndex = self.selectedViewIndex {
            return self.views[selectedIndex].color
        } else {
            return nil
        }
    }
    var originTopLeft = NSPoint.zero
    let viewSize:CGFloat
    
    weak var plusButton:NSButton? = nil
    weak var minusButton:NSButton? = nil
    weak var delegate:ColorListDelegate? = nil
    
    init(viewSize:CGFloat, colors:[NSColor]) {
        self.viewSize = viewSize
        super.init()
        self.views = colors.map() { ColorListItem(frame: NSRect(square: viewSize), color: $0, owner: self) }
        self.views.first?.isSelected = true
        if self.views.count > 0 {
            self.selectedViewIndex = 0
        }
    }
    
    func layout(viewWidth:CGFloat) {
        
        var x = self.originTopLeft.x
        var y = self.originTopLeft.y
        
        func increment() {
            x += self.viewSize
            if x + self.viewSize > viewWidth {
                x = self.originTopLeft.x
                y -= self.viewSize
            }
        }
        
        self.minusButton?.frame.origin = NSPoint(x: x, y: y - self.viewSize)
        increment()
        
        for view in self.views {
            view.frame.origin = NSPoint(x: x, y: y - self.viewSize)
            increment()
        }
        self.plusButton?.frame.origin = NSPoint(x: x, y: y - self.viewSize)
    }
    
    func itemSelected(item:ColorListItem) {
        guard let index = self.views.index(where: { $0 === item }) else {
            return
        }
        if let lastIndex = self.selectedViewIndex {
            self.views[lastIndex].isSelected = false
        }
        self.selectedViewIndex = index
        self.views[index].isSelected = true
        
        self.delegate?.selected(color: self.views[index].color)
    }
    
    func add(color:NSColor) -> ColorListItem {
        let view = ColorListItem(frame: NSRect(square: self.viewSize), color: color, owner: self)
        self.views.append(view)
        
        self.selectedItem?.isSelected = false
        self.selectedViewIndex = self.views.count - 1
        self.selectedItem?.isSelected = true
        
        return view
    }
    
    func set(colors:[NSColor]) -> Bool {
        guard colors.count >= 2 else {
            return false
        }
        self.views = colors.map() { ColorListItem(frame: NSRect(square: self.viewSize), color: $0, owner: self) }
        self.selectedViewIndex = 0
        self.views.first?.isSelected = true
        return true
    }
    
    func setCurrent(color:NSColor) -> Bool {
        if let index = self.selectedViewIndex {
            self.views[index].color = color
            return true
        }
        return false
    }
    
    func deleteSelectedItem() -> Int? {
        if let index = self.selectedViewIndex {
            let oldView = self.views.remove(at: index)
            oldView.removeFromSuperview()
            
            if self.views.count == 0 {
                self.selectedViewIndex = nil
                return nil
            }
            let nextIndex:Int
            if index == self.views.count {
                nextIndex = index - 1
            } else {
                nextIndex = index
            }
            self.views[nextIndex].isSelected = true
            self.selectedViewIndex = nextIndex
            self.delegate?.selected(color: self.views[nextIndex].color)
            return self.selectedViewIndex
        }
        self.selectedViewIndex = nil
        return nil
    }
    
}

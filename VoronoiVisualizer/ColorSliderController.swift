//
//  ColorSliderController.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 10/23/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Cocoa
import CoronaConvenience
import CoronaStructures

class ColorSliderController: NSViewController, NSTextFieldDelegate, ColorListDelegate, ResizableViewController, ColorChooserDelegate, ColoringSchemeViewController {

    @IBOutlet weak var plusButton: NSButton!
    @IBOutlet weak var minusButton: NSButton!
    lazy var colorList:ColorList = ColorList(viewSize: 32.0, colors: SCVector4.rainbowColors.map() { NSColor(vector4: $0) })
    weak var colorChooserController:ColorChooserController? = nil
    
    var displayColorList = true
    var initialColor = NSColor.white
    
    var dismissHandler:((VoronoiViewColoringScheme) -> Void)? = nil
    
    override func viewDidLoad() {
        if self.displayColorList {
            self.colorList.delegate = self
            self.colorList.plusButton = self.plusButton
            self.colorList.minusButton = self.minusButton
            self.colorList.originTopLeft = NSPoint(x: 0.0, y: self.view.frame.height)
            for view in self.colorList.views {
                self.view.addSubview(view)
            }
            self.colorList.layout(viewWidth: self.view.frame.width)
        } else {
            self.plusButton.isHidden  = true
            self.minusButton.isHidden = true
            let comps = self.initialColor.getComponents()
//            self.colorChanged(red: comps[0], green: comps[1], blue: comps[2], alpha: comps[3])
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    func viewDidResize() {
        self.colorList.originTopLeft = NSPoint(x: 0.0, y: self.view.frame.height)
        self.colorList.layout(viewWidth: self.view.frame.width)
    }
    
    func selected(color:NSColor) {
        self.colorChooserController?.set(color: color)
        self.becomeFirstResponder()
    }
    
    func set(colors: [SCVector4]) {
        self.colorList.set(colors: colors.map() { NSColor(vector4: $0) })
        self.colorList.layout(viewWidth: self.view.frame.width)
    }
    
    @IBAction func plusButtonPressed(_ sender: Any) {
        guard let color = self.colorList.selectedColor else {
            return
        }
        let view = self.colorList.add(color: color)
        self.view.addSubview(view)
        self.colorList.layout(viewWidth: self.view.frame.width)
    }
    
    @IBAction func minusButtonPressed(_ sender: Any) {
        //Doesn't make sense to have less than 2 colors.
        guard self.colorList.views.count > 2 else {
            return
        }
        let _ = self.colorList.deleteSelectedItem()
        if let newColor = self.colorList.selectedColor {
            self.colorChooserController?.set(color: newColor)
        }
        self.colorList.layout(viewWidth: self.view.frame.width)
    }
    
    func color(changedTo color: NSColor) {
        self.colorList.setCurrent(color: color)
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.dismissHandler?(DiscreteColoringScheme(colors: self.colorList.views.map() { $0.color.getVector4() }))
        self.parent?.parent?.dismiss(self)
    }
    
}

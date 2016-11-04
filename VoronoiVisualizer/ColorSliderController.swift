//
//  ColorSliderController.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 10/23/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Cocoa
import CoronaConvenience

class ColorSliderController: NSViewController, NSTextFieldDelegate, ColorWheelViewDelegate, ColorListDelegate, ResizableViewController {

//    @IBOutlet weak var colorWheel: ColorWheelView!
    @IBOutlet weak var colorWheelWrapper: ColorWheelViewWrapper!
    @IBOutlet weak var brightnessSlider: NSSlider!
    @IBOutlet weak var redTextField: NSTextField!
    @IBOutlet weak var greenTextField: NSTextField!
    @IBOutlet weak var blueTextField: NSTextField!
    @IBOutlet weak var alphaTextField: NSTextField!
    @IBOutlet weak var plusButton: NSButton!
    @IBOutlet weak var minusButton: NSButton!
    lazy var colorList:ColorList = ColorList(viewSize: 32.0, colors: [
        NSColor(red: 0.50, green: 0.50, blue: 0.50, alpha: 1.0),
        NSColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0),
        NSColor(red: 0.40, green: 0.40, blue: 0.40, alpha: 1.0),
        NSColor(red: 0.35, green: 0.35, blue: 0.35, alpha: 1.0)
    ])
    
    var lastRedValue    = "255"
    var lastGreenValue  = "255"
    var lastBlueValue   = "255"
    var lastAlphaValue  = "255"
    
    var dismissHandler:(([NSColor]) -> Void)? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.redTextField.delegate      = self
        self.greenTextField.delegate    = self
        self.blueTextField.delegate     = self
        self.alphaTextField.delegate    = self
        self.colorWheelWrapper.delegate = self
        
        self.colorWheelWrapper.set(red: 0.5, green: 0.5, blue: 0.5)
        self.colorList.delegate = self
        self.colorList.plusButton = self.plusButton
        self.colorList.minusButton = self.minusButton
        self.colorList.originTopLeft = NSPoint(x: 0.0, y: self.view.frame.height)
        for view in self.colorList.views {
            self.view.addSubview(view)
        }
        self.colorList.layout(viewWidth: self.view.frame.width)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.colorWheelWrapper.colorWheel.display()
    }
    
    func viewDidResize() {
        self.colorList.originTopLeft = NSPoint(x: 0.0, y: self.view.frame.height)
        self.colorList.layout(viewWidth: self.view.frame.width)
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else {
            return
        }
        guard textField.stringValue.matchesRegex("^\\d+$") else {
            switch textField {
            case self.redTextField:
                textField.stringValue = self.lastRedValue
            case self.greenTextField:
                textField.stringValue = self.lastGreenValue
            case self.blueTextField:
                textField.stringValue = self.lastBlueValue
            case self.alphaTextField:
                textField.stringValue = self.lastAlphaValue
            default:
                break
            }
            return
        }
        let value = textField.integerValue
        //We don't have to check negative values
        //because the regex won't allow minus signs.
        if value > 255 {
            textField.stringValue = "255"
        }
        
        self.lastRedValue   = self.redTextField.stringValue
        self.lastGreenValue = self.greenTextField.stringValue
        self.lastBlueValue  = self.blueTextField.stringValue
        self.lastAlphaValue = self.alphaTextField.stringValue
        
        let red     = CGFloat(self.redTextField.doubleValue) / 255.0
        let green   = CGFloat(self.greenTextField.doubleValue) / 255.0
        let blue    = CGFloat(self.blueTextField.doubleValue) / 255.0
        let alpha   = CGFloat(self.alphaTextField.doubleValue) / 255.0
        self.colorWheelWrapper.set(red: red, green: green, blue: blue, alpha: alpha)
        self.brightnessSlider.doubleValue = Double(self.colorWheelWrapper.colorWheel.brightness)
        self.colorWheelWrapper.colorWheel.display()
        
        self.colorList.setCurrent(color: NSColor(red: red, green: green, blue: blue, alpha: alpha))
    }
    
    @IBAction func brightnessSliderChanged(_ sender: Any) {
        self.colorWheelWrapper.brightness = CGFloat(self.brightnessSlider.doubleValue)
        self.colorWheelWrapper.colorWheel.display()
    }
    
    func colorChanged(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        self.brightnessSlider.doubleValue = Double(brightness)
    }
    
    func colorChanged(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.redTextField.stringValue   = "\(Int(255.0 * red))"
        self.greenTextField.stringValue = "\(Int(255.0 * green))"
        self.blueTextField.stringValue  = "\(Int(255.0 * blue))"
        self.colorList.setCurrent(color: NSColor(red: red, green: green, blue: blue, alpha: alpha))
    }
    
    func selected(color:NSColor) {
        let rgba = color.getComponents()
        self.colorWheelWrapper.set(red: rgba[0], green: rgba[1], blue: rgba[2])
        self.colorWheelWrapper.wheelAlpha = rgba[3]
        self.brightnessSlider.doubleValue = Double(self.colorWheelWrapper.brightness)
        self.colorChanged(red: rgba[0], green: rgba[1], blue: rgba[2], alpha: rgba[3])
        self.colorWheelWrapper.display()
        self.becomeFirstResponder()
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
            let rgba = newColor.getComponents()
            self.colorWheelWrapper.set(red: rgba[0], green: rgba[1], blue: rgba[2], alpha: rgba[3])
            self.brightnessSlider.doubleValue = Double(self.colorWheelWrapper.brightness)
        }
        self.colorList.layout(viewWidth: self.view.frame.width)
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.dismissHandler?(self.colorList.views.map() { $0.color })
        self.dismiss(nil)
    }
    
}

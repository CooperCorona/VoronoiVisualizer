//
//  ColorSliderController.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 10/23/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Cocoa

class ColorSliderController: NSViewController, NSTextFieldDelegate {

    @IBOutlet weak var colorWheel: ColorWheelView!
    @IBOutlet weak var brightnessSlider: NSSlider!
    @IBOutlet weak var redTextField: NSTextField!
    @IBOutlet weak var greenTextField: NSTextField!
    @IBOutlet weak var blueTextField: NSTextField!
    @IBOutlet weak var alphaTextField: NSTextField!
    
    @IBOutlet weak var redSlider: NSSlider!
    @IBOutlet weak var greenSlider: NSSlider!
    @IBOutlet weak var blueSlider: NSSlider!
    var dismissHandler:((NSColor) -> Void)? = nil
    
    var color:NSColor {
        return NSColor(red: CGFloat(self.redSlider.floatValue), green: CGFloat(self.greenSlider.floatValue), blue: CGFloat(self.blueSlider.floatValue), alpha: 1.0)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.redTextField.delegate      = self
        self.greenTextField.delegate    = self
        self.blueTextField.delegate     = self
        self.alphaTextField.delegate    = self
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.colorWheel.display()
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else {
            return
        }
        guard textField.stringValue.matchesRegex("^\\d+$") else {
            textField.stringValue = "0"
            return
        }
        let value = textField.integerValue
        //We don't have to check negative values
        //because the regex won't allow minus signs.
        if value > 255 {
            textField.stringValue = "255"
        }
        let red     = CGFloat(self.redTextField.doubleValue) / 255.0
        let green   = CGFloat(self.greenTextField.doubleValue) / 255.0
        let blue    = CGFloat(self.blueTextField.doubleValue) / 255.0
        let alpha   = CGFloat(self.alphaTextField.doubleValue) / 255.0
        self.colorWheel.set(red: red, green: green, blue: blue, alpha: alpha)
        self.brightnessSlider.doubleValue = Double(self.colorWheel.brightness)
        self.colorWheel.display()
        
        switch textField {
        case self.redTextField:
            break
        case self.greenTextField:
            break
        case self.blueTextField:
            break
        case self.alphaTextField:
            break
        default:
            break
        }
    }
    
    @IBAction func brightnessSliderChanged(_ sender: Any) {
        self.colorWheel.brightness = CGFloat(self.brightnessSlider.doubleValue)
        self.colorWheel.display()
    }
    
    @IBAction func doneButtonPressed(_ sender: AnyObject) {
        self.dismissHandler?(self.color)
        self.dismiss(nil)
    }
    
}

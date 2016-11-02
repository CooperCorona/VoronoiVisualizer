//
//  ColorSliderController.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 10/23/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Cocoa

class ColorSliderController: NSViewController, NSTextFieldDelegate, ColorWheelViewDelegate {

//    @IBOutlet weak var colorWheel: ColorWheelView!
    @IBOutlet weak var colorWheelWrapper: ColorWheelViewWrapper!
    @IBOutlet weak var brightnessSlider: NSSlider!
    @IBOutlet weak var redTextField: NSTextField!
    @IBOutlet weak var greenTextField: NSTextField!
    @IBOutlet weak var blueTextField: NSTextField!
    @IBOutlet weak var alphaTextField: NSTextField!
    
    var lastRedValue    = "255"
    var lastGreenValue  = "255"
    var lastBlueValue   = "255"
    var lastAlphaValue  = "255"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.redTextField.delegate      = self
        self.greenTextField.delegate    = self
        self.blueTextField.delegate     = self
        self.alphaTextField.delegate    = self
        self.colorWheelWrapper.delegate = self
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.colorWheelWrapper.colorWheel.display()
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
    }
    
    @IBAction func brightnessSliderChanged(_ sender: Any) {
        self.colorWheelWrapper.brightness = CGFloat(self.brightnessSlider.doubleValue)
        self.colorWheelWrapper.colorWheel.display()
    }
    
    @IBAction func doneButtonPressed(_ sender: AnyObject) {
        self.dismiss(nil)
    }
    
    func colorChanged(hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        self.brightnessSlider.doubleValue = Double(brightness)
    }
    
    func colorChanged(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.redTextField.stringValue   = "\(Int(255.0 * red))"
        self.greenTextField.stringValue = "\(Int(255.0 * green))"
        self.blueTextField.stringValue  = "\(Int(255.0 * blue))"
    }
    
}

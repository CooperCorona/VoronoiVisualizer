//
//  ColorChooserController.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 4/20/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Cocoa
import CoronaConvenience

protocol ColorChooserDelegate: class {
    
    func color(changedTo color:NSColor)
    
}

class ColorChooserController: NSViewController, ColorWheelViewDelegate {

    // MARK: - Properties
    
    weak var colorChooserDelegate:ColorChooserDelegate? = nil
    
    private(set) var color = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    @IBOutlet weak var colorWheel: ColorWheelViewWrapper!
    @IBOutlet weak var brightnessSlider: NSSlider!
    @IBOutlet weak var redTextField: NSTextField!
    @IBOutlet weak var greenTextField: NSTextField!
    @IBOutlet weak var blueTextField: NSTextField!
    @IBOutlet weak var alphaTextField: NSTextField!
    
    // MARK: - Setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.colorWheel.delegate = self
    }
    
    func set(color:NSColor) {
        let comps = color.getComponents()
        self.colorWheel.set(red: comps[0], green: comps[1], blue: comps[2], alpha: comps[3])
        self.redTextField.integerValue = Int(comps[0] * 255.0)
        self.greenTextField.integerValue = Int(comps[1] * 255.0)
        self.blueTextField.integerValue = Int(comps[2] * 255.0)
        self.alphaTextField.integerValue = Int(comps[3] * 255.0)
        self.brightnessSlider.doubleValue = Double(self.colorWheel.brightness)
        self.colorWheel.display()
    }
    
    // MARK: - Actions
    
    @IBAction func brightnessSliderChanged(_ sender: Any) {
        self.colorWheel.brightness = CGFloat(self.brightnessSlider.doubleValue)
        self.colorWheel.display()
    }
    
    @IBAction func redTextFieldChanged(_ sender: Any) {
        self.colorTextFieldChanged(channel: .red)
    }
    
    @IBAction func greenTextFieldChanged(_ sender: Any) {
        self.colorTextFieldChanged(channel: .green)
    }
    
    @IBAction func blueTextFieldChanged(_ sender: Any) {
        self.colorTextFieldChanged(channel: .blue)
    }
    
    @IBAction func alphaTextFieldChanged(_ sender: Any) {
        self.colorTextFieldChanged(channel: .alpha)
    }
    
    func colorTextField(for channel:ColorChannel) -> NSTextField {
        switch channel {
        case .red:
            return self.redTextField
        case .green:
            return self.greenTextField
        case .blue:
            return self.blueTextField
        case .alpha:
            return self.alphaTextField
        }
    }
    
    private func updateColorWheel() {
        self.colorWheel.set(red: self.color[.red], green: self.color[.green], blue: self.color[.blue], alpha: self.color[.alpha])
        self.brightnessSlider.doubleValue = Double(self.colorWheel.brightness)
        self.colorWheel.display()
    }
    
    func colorTextFieldChanged(channel:ColorChannel) {
        let textField = self.colorTextField(for: channel)
        guard textField.stringValue.characterCount > 0 else {
            //We don't want to, say, set it to zero if there's
            //no element. We just don't want to do any computations.
            return
        }
        guard textField.stringValue.matchesRegex("^\\d+$") else {
            textField.stringValue = "\(self.color.int(for: channel))"
            return
        }
        let value = textField.stringValue.getIntegerValue()
        //Because we only allow numerical values,
        //we can't have a negative number.
        guard value <= 255 else {
            textField.stringValue = "255"
            self.color = self.color.with(value: 255, for: channel)
            self.updateColorWheel()
            self.colorChanged()
            return
        }
        self.color = self.color.with(value: value, for: channel)
        self.updateColorWheel()
        self.colorChanged()
    }
    
    func colorChanged() {
        self.colorChooserDelegate?.color(changedTo: self.color)
    }
    
    @IBAction func minimumBrightnessButtonPressed(_ sender: Any) {
        self.brightnessSlider.doubleValue = 0.0
        self.colorWheel.brightness = 0.0
        self.colorWheel.display()
    }
    
    @IBAction func maximumBrightnessButtonPressed(_ sender: Any) {
        self.brightnessSlider.doubleValue = 1.0
        self.colorWheel.brightness = 1.0
        self.colorWheel.display()
    }
    
    func colorChanged(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        self.color = NSColor(red: red, green: green, blue: blue, alpha: alpha)
        self.redTextField.integerValue = Int(red * 255.0)
        self.greenTextField.integerValue = Int(green * 255.0)
        self.blueTextField.integerValue = Int(blue * 255.0)
        self.alphaTextField.integerValue = Int(alpha * 255.0)
        self.colorChanged()
    }
}

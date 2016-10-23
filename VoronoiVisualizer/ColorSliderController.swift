//
//  ColorSliderController.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 10/23/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Cocoa

class ColorSliderController: NSViewController {

    @IBOutlet weak var redSlider: NSSlider!
    @IBOutlet weak var greenSlider: NSSlider!
    @IBOutlet weak var blueSlider: NSSlider!
    var dismissHandler:((NSColor) -> Void)? = nil
    
    var color:NSColor {
        return NSColor(red: CGFloat(self.redSlider.floatValue), green: CGFloat(self.greenSlider.floatValue), blue: CGFloat(self.blueSlider.floatValue), alpha: 1.0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = self.color.cgColor
    }
    
    @IBAction func sliderChanged(_ sender: AnyObject) {
        self.view.layer?.backgroundColor = self.color.cgColor
    }
    
    @IBAction func doneButtonPressed(_ sender: AnyObject) {
        self.dismissHandler?(self.color)
        self.dismiss(nil)
    }
    
}

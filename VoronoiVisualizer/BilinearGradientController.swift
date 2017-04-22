//
//  BilinearGradientController.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 4/20/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Cocoa
import CoronaConvenience
import CoronaStructures

class BilinearGradientController: NSViewController, ColorChooserDelegate {
    
    private var anchors = ColorAnchors(viewSize: CGSize(square: 1.0))
    private var knobs:[NSView] = []
    
    @IBOutlet weak var gradientView: BilinearGradientView!
    @IBOutlet weak var knobView: NSView!
    @IBOutlet weak var deleteButton: NSButton!
    
    weak var colorChooserController:ColorChooserController? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.anchors.add(point: CGPoint(x: 0.0, y: 0.0), color: SCVector4.redColor, view: self.makeKnob(), mobile: false)
        self.anchors.add(point: CGPoint(x: 1.0, y: 0.0), color: SCVector4.blueColor, view: self.makeKnob(), mobile: false)
        self.anchors.add(point: CGPoint(x: 0.0, y: 1.0), color: SCVector4.yellowColor, view: self.makeKnob(), mobile: false)
        self.anchors.add(point: CGPoint(x: 1.0, y: 1.0), color: SCVector4.greenColor, view: self.makeKnob(), mobile: false)
        self.gradientView.gradient = self.anchors.gradient
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        self.anchors.viewSize = self.gradientView.frame.size
    }
    
    func makeKnob() -> NSView {
        let knobImage = NSView(frame: NSRect(square: 12.0))
        knobImage.wantsLayer = true
        knobImage.layer?.backgroundColor = NSColor.white.cgColor
        knobImage.layer?.cornerRadius = knobImage.frame.width / 2.0
        knobImage.layer?.borderColor = NSColor.black.cgColor
        knobImage.layer?.borderWidth = 1.0
        self.knobs.append(knobImage)
        self.knobView.addSubview(knobImage)
        return knobImage
    }
    
    func color(changedTo color: NSColor) {
        self.anchors.set(color: color)
        self.gradientView.gradient = self.anchors.gradient
        self.gradientView.display()
    }
    
    override func mouseDown(with event: NSEvent) {
        var point = self.view.convert(event.locationInWindow, from: nil)
        point = self.gradientView.convert(point, from: self.view)
        guard self.gradientView.bounds.contains(point) else {
            return
        }
        let selectedAnchor = self.anchors.mouseDown(at: point)
        if let anchor = selectedAnchor {
            self.deleteButton.isHidden = !anchor.mobile
            self.colorChooserController?.set(color: NSColor(vector4: anchor.color))
        } else {
            self.anchors.add(point: point, view: self.makeKnob())
            //We've just added a point at this exact spot,
            //so we know there's going to be one.
            let color = self.anchors.mouseDown(at: point)!.color
            self.colorChooserController?.set(color: NSColor(vector4: color))
            self.deleteButton.isHidden = false
        }
        
    }
    
    override func mouseDragged(with event: NSEvent) {
        var point = self.view.convert(event.locationInWindow, from: nil)
        point = self.gradientView.convert(point, from: self.view)
        self.anchors.mouseDragged(at: point)
        self.gradientView.gradient = self.anchors.gradient
    }
    
    override func mouseUp(with event: NSEvent) {
        self.gradientView.display()
    }
    
    func deleteAnchor() {
        self.anchors.removeSelected()
        self.gradientView.gradient = self.anchors.gradient
        self.gradientView.display()
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        self.deleteAnchor()
    }
    
}

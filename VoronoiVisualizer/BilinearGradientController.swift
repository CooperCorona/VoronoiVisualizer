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

class BilinearGradientController: NSViewController, ColorChooserDelegate, ColoringSchemeViewController {
    
    private lazy var anchors:ColorAnchors = {
        var anchors = ColorAnchors(viewSize: CGSize(square: 1.0))
        anchors.add(point: CGPoint(x: 0.0, y: 0.0), color: SCVector4.redColor, view: self.makeKnob(), mobile: false)
        anchors.add(point: CGPoint(x: 1.0, y: 0.0), color: SCVector4.blueColor, view: self.makeKnob(), mobile: false)
        anchors.add(point: CGPoint(x: 0.0, y: 1.0), color: SCVector4.yellowColor, view: self.makeKnob(), mobile: false)
        anchors.add(point: CGPoint(x: 1.0, y: 1.0), color: SCVector4.greenColor, view: self.makeKnob(), mobile: false)
        return anchors
    }()
    private var knobs:[NSView] = []
    
    @IBOutlet weak var gradientView: BilinearGradientView!
    @IBOutlet weak var knobView: NSView!
    @IBOutlet weak var deleteButton: NSButton!
    
    weak var colorChooserController:ColorChooserController? = nil
    var dismissHandler:((VoronoiViewColoringScheme) -> Void)? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.gradientView.gradient = self.anchors.gradient
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        //It's possible for the knobView to be nil
        //in makeKnob, so we just add the views to
        //the knobs array without adding them to
        //the view. If so, we'll add them all here.
        //If that didn't occur, the knobs array
        //will contain no elements anyways.
        for knob in self.knobs {
            self.knobView.addSubview(knob)
        }
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
        //When instantiating the color split controller,
        //we set the gradient (thus calling this method)
        //before the outlets have been loaded, so it's
        //possible for the knob view to be nil at this point.
        if let knobView = self.knobView {
            self.knobView.addSubview(knobImage)
        }
        return knobImage
    }
    
    func color(changedTo color: NSColor) {
        self.anchors.set(color: color)
        self.gradientView.gradient = self.anchors.gradient
        self.gradientView.display()
    }
    
    func set(gradient:LightSourceGradient<SCVector4>) {
        let anchors = ColorAnchors(viewSize: CGSize(square: 1.0))
        for light in gradient.lights {
            anchors.add(point: light.point, color: light.value, view: self.makeKnob())
        }
        for knob in self.knobs {
            knob.removeFromSuperview()
        }
        self.anchors = anchors
    }
    
    override func mouseDown(with event: NSEvent) {
        var point = self.view.convert(event.locationInWindow, from: nil)
        point = self.gradientView.convert(point, from: self.view)
        let selectedAnchor = self.anchors.mouseDown(at: point)
        if let anchor = selectedAnchor {
            self.deleteButton.isHidden = !anchor.mobile
            self.colorChooserController?.set(color: NSColor(vector4: anchor.color))
        } else {
            guard self.gradientView.bounds.contains(point) else {
                return
            }
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
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.dismissHandler?(LightSourceGradientColoringScheme(gradient: self.anchors.gradient))
        self.parent?.parent?.dismiss(self)
    }
    
}

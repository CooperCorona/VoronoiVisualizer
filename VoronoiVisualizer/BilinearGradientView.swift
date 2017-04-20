//
//  BilinearGradientView.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 4/18/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Cocoa
import CoronaConvenience
import CoronaStructures

class BilinearGradientView: NSView {
    
//    var gradient = BilinearGradient()
    var gradient = LightSourceGradient(zero: SCVector4())

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current()?.cgContext else {
            return
        }
        for j in 0..<Int(self.frame.height) {
            for i in 0..<Int(self.frame.width) {
                let x = CGFloat(i) / (self.frame.width - 1.0)
                let y = CGFloat(j) / (self.frame.height - 1.0)
                context.setFillColor(NSColor(vector4: self.gradient.color(at: CGPoint(x: x, y: y))).cgColor)
                context.fill(CGRect(x: CGFloat(i), y: CGFloat(j), width: 1.0, height: 1.0))
            }
        }
    }
    
}

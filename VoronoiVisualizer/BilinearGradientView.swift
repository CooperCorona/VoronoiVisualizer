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
    
    var gradient = LightSourceGradient(zero: SCVector4())
    var granularity:Int = 2 {
        didSet {
            if self.granularity <= 0 {
                self.granularity = 1
            }
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else {
            return
        }
        let fGranularity = CGFloat(self.granularity)
        for j in 0..<Int(self.frame.height / fGranularity) {
            for i in 0..<Int(self.frame.width / fGranularity) {
                let x = CGFloat(i) / (self.frame.width - 1.0) * fGranularity
                let y = CGFloat(j) / (self.frame.height - 1.0) * fGranularity
                context.setFillColor(NSColor(vector4: self.gradient.color(at: CGPoint(x: x, y: y))).cgColor)
                context.fill(CGRect(x: CGFloat(i) * fGranularity, y: CGFloat(j) * fGranularity, width: fGranularity, height: fGranularity))
            }
        }
    }
    
}

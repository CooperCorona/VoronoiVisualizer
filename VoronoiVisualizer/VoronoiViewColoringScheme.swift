//
//  VoronoiViewColoringScheme.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 4/22/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Foundation
import CoronaConvenience
import CoronaStructures

protocol VoronoiViewColoringScheme {
    
    func color(for cell:VoronoiCellSprite) -> (SCVector4, Int?)
    
}

struct DiscreteColoringScheme: VoronoiViewColoringScheme {
    
    var colors:[SCVector4]
    
    func color(for cell: VoronoiCellSprite) -> (SCVector4, Int?) {
        let indices = Set(array: cell.neighbors.map() { $0.colorIndex })
        let validIndices = Set(array: array(from: 0, to: self.colors.count)).subtracting(indices)
        let index:Int
        if validIndices.count > 0 {
            index = validIndices.randomElement()!
        } else {
            index = Int(arc4random() & ~(1 << 31)) % colors.count
        }
        return (self.colors[index], index)
    }
    
}

struct LightSourceGradientColoringScheme: VoronoiViewColoringScheme {
    
    var gradient:LightSourceGradient<SCVector4>
    
    func color(for cell:VoronoiCellSprite) -> (SCVector4, Int?) {
        let point = cell.cell.voronoiPoint / cell.cell.boundaries
        var x = remainder(point.x + 1.0, 1.0)
        var y = remainder(point.y + 1.0, 1.0)
        while x < 0.0 {
            x += 1.0
        }
        while y < 0.0 {
            y += 1.0
        }
        return (self.gradient.color(at: CGPoint(x: x, y: y)), nil)
    }
    
}

//
//  LightSourceGradient.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 4/20/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Cocoa
import CoronaConvenience
import CoronaStructures

public struct LightSource<T: Interpolatable> {
    public var point:CGPoint
    public var value:T
    
    fileprivate func distance(from point:CGPoint) -> LightSourceDistance<T> {
        return LightSourceDistance(value: value, distance: self.point.distanceFrom(point))
    }
}

private struct LightSourceDistance<T: Interpolatable> {
    var value:T
    var distance:CGFloat
    
    func with(distance:CGFloat) -> LightSourceDistance {
        return LightSourceDistance(value: self.value, distance: distance)
    }
}

public struct LightSourceGradient<T: Interpolatable> {

    private(set) var lights:[LightSource<T>] = []
    public let zero:T
    
    public init(zero:T) {
        self.zero = zero
    }
    
    public mutating func add(value:T, at point:CGPoint, strength:CGFloat = 1.0) {
        self.lights.append(LightSource(point: point, value: value))
    }
    
//    mutating func remove(at: CGPoint, color: SCVector4) ->
    
    public func color(at:CGPoint) -> T {
        let distances = self.lights.map() { $0.distance(from: at) }
        if let atPoint = distances.find({ $0.distance == 0.0 }) {
            return atPoint.value
        }
        let power:CGFloat = 2.0
        let weights = distances.map() { 1.0 / pow($0.distance, power) }
        let totalWeight = weights.reduce(0.0) { $0 + $1 }
        let color = array(from: 0, to: distances.count).reduce(self.zero) { $0 + (weights[$1] / totalWeight) * distances[$1].value }
        return color
    }
}

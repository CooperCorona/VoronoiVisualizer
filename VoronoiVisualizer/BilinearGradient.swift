//
//  BilinearGradient.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 4/17/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Cocoa
import CoronaConvenience
import CoronaStructures

struct BilinearGradient {

    private(set) var colors:[CGPoint:SCVector4] = [:]
    private(set) var xPoints = SortedArray<CGPoint>(comparator: {
        if $0.x < $1.x {
            return -1
        } else if $0.x > $1.x {
            return 1
        } else {
            return 0
        }
    })
    private(set) var yPoints = SortedArray<CGPoint>(comparator: {
        if $0.y < $1.y {
            return -1
        } else if $0.y > $1.y {
            return 1
        } else {
            return 0
        }
    })
    
    mutating func add(point:CGPoint, color:SCVector4) {
        if self.colors[point] != nil {
            return
        }
        self.colors[point] = color
        self.xPoints.add(element: point)
        self.yPoints.add(element: point)
    }
    
    mutating func remove(point:CGPoint) {
        guard self.colors[point] != nil else {
            return
        }
        self.colors[point] = nil
        let (xIndexL, xIndexU) = self.xPoints.indices(adjacentTo: point)
        guard xIndexL == xIndexU else {
            return
        }
        self.xPoints.remove(at: xIndexL)
        let (yIndexL, yIndexU) = self.yPoints.indices(adjacentTo: point)
        guard yIndexL == yIndexU else {
            return
        }
        self.yPoints.remove(at: yIndexL)
    }
    
    func nearestThreePoints(to point:CGPoint) -> (first:CGPoint, second:CGPoint, third:CGPoint) {
        /*
        let keys = self.colors.keys.map() { $0 } as [CGPoint]
        var first = keys[0]
        var firstDist = first.distanceFrom(point)
        var second = keys[1]
        var secondDist = second.distanceFrom(point)
        var third = keys[2]
        var thirdDist = third.distanceFrom(point)
        print("\(keys) \(keys.dropFirst(3))")
        for key in keys.dropFirst(3) {
            let dist = point.distanceFrom(key)
            if dist < firstDist {
                third = second
                thirdDist = secondDist
                second = first
                secondDist = firstDist
                first = key
                firstDist = dist
            } else if dist < secondDist {
                third = second
                thirdDist = secondDist
                second = key
                secondDist = dist
            } else if dist < thirdDist {
                third = key
                thirdDist = dist
            }
        }
        return (first, second, third)
        */
        let keys = self.colors.keys.sorted() { $0.distanceFrom(point) < $1.distanceFrom(point) }
        return (keys[0], keys[1], keys[2])
    }
    
    func color(at:CGPoint) -> SCVector4 {
        let (first, second, third) = self.nearestThreePoints(to: at)
        return triangularlyInterpolate(mid: at, vertex1: first, value1: self.colors[first]!, vertex2: second, value2: self.colors[second]!, vertex3: third, value3: self.colors[third]!)
        /*
        let (xl, xu) = self.xPoints.indices(adjacentTo: at)
        let (yl, yu) = self.yPoints.indices(adjacentTo: at)
        let x:CGFloat
        let y:CGFloat
        if xl == xu {
            x = 0.0
        } else {
            x = (at.x - self.xPoints[xl].x) / (self.xPoints[xu].x - self.xPoints[xl].x)
        }
        if yl == yu {
            y = 0.0
        } else {
            y = (at.y - self.yPoints[yl].y) / (self.yPoints[yu].y - self.yPoints[yl].y)
        }
        let bottomLeft = CGPoint(x: self.xPoints[xl].x, y: self.yPoints[yl].y)
        let bottomRight = CGPoint(x: self.xPoints[xu].x, y: self.yPoints[yl].y)
        let topLeft = CGPoint(x: self.xPoints[xl].x, y: self.yPoints[yu].y)
        let topRight = CGPoint(x: self.xPoints[xu].x, y: self.yPoints[yu].y)
        return bilinearlyInterpolate(CGPoint(x: x, y: y), leftBelow: self.colors[bottomLeft]!, rightBelow: self.colors[bottomRight]!, leftAbove: self.colors[topLeft]!, rightAbove: self.colors[topRight]!)
        */
    }
    
}

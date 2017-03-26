//
//  GLSPolygonSprite.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 3/13/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Cocoa
import CoronaConvenience
import CoronaGL

open class GLSPolygonSprite: GLSSprite {

    open let polygonVertices:[CGPoint]
    open let polygonBoundaries:CGRect
    private let originalOrigin:CGPoint
    
    
    /**
     Initiates a GLSPolygonSprite with the given vertices. The
     texture anchors are determined by the boundary rect.
     - polygonVertices: The vertices of the polygon. Must define a convex polygon.
     Must contain 3 or more vertices.
     - boundaris: The boundaries used to determine the texture coordinates.
     */
    public init(polygonVertices:[CGPoint], boundaries:CGRect) {
        self.polygonVertices = polygonVertices
        self.polygonBoundaries = boundaries
        
        var uVertices:[UVertex] = []
        var c = UVertex()
        c.position = polygonVertices[0].getGLTuple()
        c.texture = ((polygonVertices[0] - boundaries.origin) / boundaries.size.getCGPoint()).getGLTuple()
        var minX = polygonVertices[0].x
        var minY = polygonVertices[0].y
        var maxX = polygonVertices[0].x
        var maxY = polygonVertices[0].y
        for i in 1..<polygonVertices.count - 1 {
            var l = UVertex()
            l.position = polygonVertices[i].getGLTuple()
            l.texture = ((polygonVertices[i] - boundaries.origin) / boundaries.size.getCGPoint()).getGLTuple()
            var r = UVertex()
            r.position = polygonVertices[i + 1].getGLTuple()
            r.texture = ((polygonVertices[i + 1] - boundaries.origin) / boundaries.size.getCGPoint()).getGLTuple()
            uVertices += [c, l, r]
            
            if polygonVertices[i].x < minX {
                minX = polygonVertices[i].x
            } else if polygonVertices[i].x > maxX {
                maxX = polygonVertices[i].x
            }
            if polygonVertices[i].y < minY {
                minY = polygonVertices[i].y
            } else if polygonVertices[i].y > maxY {
                maxY = polygonVertices[i].y
            }
        }
        let frame = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        self.originalOrigin = frame.origin
        super.init(position: frame.center, size: frame.size, texture: nil)
        self.vertices = uVertices.map() {
            var v = $0
            v.position = (v.position.0 - GLfloat(minX), v.position.1 - GLfloat(minY))
            return v
        }
    }
    
    override open func contentSizeChanged() {
        //Currently do nothing. Doesn't
        //make a ton of sense to change
        //the content size of a polygon sprite.
    }
    
    open override func setQuadForTexture() {
        let tFrame = (self.texture?.frame ?? CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)).inset(rect: self.textureFrame)
        for i in 0..<self.vertices.count {
            let p = CGPoint(tupleGL: self.vertices[i].position) + self.originalOrigin
            let t = ((p - self.polygonBoundaries.origin) / self.polygonBoundaries.size.getCGPoint())
            self.vertices[i].texture = tFrame.interpolate(t).getGLTuple()
        }
        self.verticesAreDirty = true
    }//set quad for texture
    
}

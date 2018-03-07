//
//  GLSVoronoiEdgeSprite.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 9/17/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Cocoa
import CoronaConvenience
import CoronaStructures
import CoronaGL
import Voronoi

enum EdgeRenderingMode: String {
    case none = "None"
    case edges = "Edges"
    case outline = "Outline"
}

class GLSVoronoiEdgeSprite: GLSNode {

    struct Vertex {
        var position:(GLfloat, GLfloat) = (0.0, 0.0)
        var color:(GLfloat, GLfloat, GLfloat, GLfloat) = (0.0, 0.0, 0.0, 0.0)
    }
    
    let edgeProgram = ShaderHelper.programDictionaryForString("Color Shader")!
    private(set) var edgeVertices:[Vertex]
    
    override var shadeColor: SCVector3 {
        didSet {
            for i in 0..<self.edgeVertices.count {
                self.edgeVertices[i].color = self.shadeColor.getGLTuple4(self.alpha)
            }
        }
    }
    override var alpha: CGFloat {
        didSet {
            for i in 0..<self.edgeVertices.count {
                self.edgeVertices[i].color.3 = GLfloat(self.alpha)
            }
        }
    }
    
    init(cell:VoronoiCell, color:SCVector3, thickness:CGFloat, antiAliasFactor:CGFloat, mode:EdgeRenderingMode = .edges) {
        let vertices = cell.makeVertexLoop()
        var edgeVertices:[Vertex] = []
        let rotate90 = SCMatrix4(rotation2D: CGFloat.pi / 2.0)
        for (i, vertex) in vertices.enumerated() {
            let next:CGPoint
            if i == vertices.count - 1 {
                next = vertices[0]
            } else {
                next = vertices[i + 1]
            }
            if mode != .outline {
                //If the mode is not outline, we don't want
                //to render edges on the actual edges of the
                //rectangle. Thus, we need to check if the edges
                //lie on the boundaries of the diagram.
                if vertex.x == 0.0 && next.x == 0.0 {
                    continue
                } else if vertex.x == cell.boundaries.width && next.x == cell.boundaries.width {
                    continue
                } else if vertex.y == 0.0 && next.y == 0.0 {
                    continue
                } else if vertex.y == cell.boundaries.height && next.y == cell.boundaries.height {
                    continue
                }
            }
            let normal = rotate90 * (next - vertex).unit()
            let tl = (vertex + normal * thickness) * antiAliasFactor
            let bl = (vertex - normal * thickness) * antiAliasFactor
            let tr = (next + normal * thickness) * antiAliasFactor
            let br = (next - normal * thickness) * antiAliasFactor
            var vs = [Vertex](repeating: Vertex(position: (0.0, 0.0), color: color.getGLTuple4()), count: 6)
            vs[0].position = tl.getGLTuple()
            vs[1].position = bl.getGLTuple()
            vs[2].position = tr.getGLTuple()
            vs[3].position = bl.getGLTuple()
            vs[4].position = tr.getGLTuple()
            vs[5].position = br.getGLTuple()
            edgeVertices += vs
        }
        self.edgeVertices = edgeVertices
        
        super.init(position: CGPoint.zero, size: CGSize.zero)
    }
    
    override func render(_ model: SCMatrix4) {
        if self.hidden {
            return
        }
        self.edgeProgram.use()
        glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<Vertex>.size * self.edgeVertices.count), self.edgeVertices, GLenum(GL_STATIC_DRAW))
        
        self.edgeProgram.uniformMatrix4fv("u_Projection", matrix: self.projection)
        
        self.edgeProgram.enableAttributes()
        self.edgeProgram.bridgeAttributesWithSizes([2, 4], stride: MemoryLayout<Vertex>.size)
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(self.edgeVertices.count))
        
        self.edgeProgram.disable()
        
        super.render(model)
    }
    
}

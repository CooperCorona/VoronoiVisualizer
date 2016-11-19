//
//  VoronoiView.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 11/6/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Cocoa
import CoronaConvenience
import CoronaStructures
import CoronaGL
import Voronoi
import GameKit

class VoronoiCellSprite: Hashable {
    let cell:VoronoiCell
    let sprite:GLSVoronoiSprite
    var neighbors:[VoronoiCellSprite] = []
    let hashValue:Int
    var colorIndex = -1
    
    init(cell:VoronoiCell, sprite:GLSVoronoiSprite, hash:Int) {
        self.cell = cell
        self.sprite = sprite
        self.hashValue = hash
    }
    
    func makeNeighbors(cells:[VoronoiCellSprite]) {
        self.neighbors = self.cell.neighbors.flatMap() { n in cells.find() { c in c.cell === n } }
    }

}

func ==(lhs:VoronoiCellSprite, rhs:VoronoiCellSprite) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

class VoronoiView: NSObject {

    weak var glView:OmniGLView2d? = nil
    var viewSize:CGSize { return self.glView?.frame.size ?? CGSize(square: 1.0) }
    var voronoiBuffer = GLSFrameBuffer(size: CGSize(square: 1.0))
    var tileBuffer = GLSFrameBuffer(size: CGSize(square: 1.0))
    var tileSprites:[GLSSprite] = []
    var pointContainer = GLSNode(position: CGPoint.zero, size: CGSize.zero)
    var edgeContainer = GLSNode(position: CGPoint.zero, size: CGSize.zero)
    let checkerBackground:GLSCheckerSprite
    private(set) var diagram:VoronoiDiagram? = nil
    var size = CGSize(square: 256.0) {
        didSet {
            
        }
    }
    var points:[CGPoint] = []
    private(set) var cells:[VoronoiCellSprite] = []
    var colors:[SCVector4] = [] {
        didSet {
            self.colorCells()
        }
    }
    var edgeColor = SCVector4.blackColor {
        didSet {
            self.colorEdges()
        }
    }
    var renderEdges = false {
        didSet {
            self.edgeContainer.hidden = !self.renderEdges
        }
    }
    var renderPoints = false {
        didSet {
            self.pointContainer.hidden = !self.renderPoints
        }
    }
    private var seed:UInt64 = 0
    private var random = GKMersenneTwisterRandomSource(seed: 0)
    
    var isTiled:Bool = false {
        didSet {
            if let diagram = self.diagram {
                self.calculate(diagram: diagram)
            }
        }
    }
    
    init(glView:OmniGLView2d?) {
        self.glView = glView
        
        self.checkerBackground = GLSCheckerSprite(off: SCVector4.lightGrayColor, on: SCVector4.whiteColor, size: NSSize(square: 48.0))
        self.checkerBackground.anchor = CGPoint.zero
        self.checkerBackground.position = CGPoint.zero
        self.glView?.addChild(self.checkerBackground)
        
        self.pointContainer.hidden = true
        self.edgeContainer.hidden  = true
    }
    
    func display() {
        self.glView?.display()
    }
    
    func viewDidResize() {
        self.checkerBackground.contentSize  = self.viewSize
        self.voronoiBuffer.position         = self.viewSize.center
        self.pointContainer.position        = self.viewSize.center - self.size.center
        self.pointContainer.contentSize     = self.size
        self.edgeContainer.position         = self.size.center
        self.edgeContainer.contentSize      = self.size
    }
    
    func calculateRandom(rows:Int, columns:Int) {
        let diagram = VoronoiDiagram.createWithSize(self.size, rows: rows, columns: columns, range: 1.0)
        self.points = diagram.points
        self.calculate(diagram: diagram)
    }
    
    func calculate() {
        let diagram = VoronoiDiagram(points: self.points, size: self.size)
        self.calculate(diagram: diagram)
    }
    
    private func calculate(diagram:VoronoiDiagram) {
        let _ = self.glView?.removeChild(self.voronoiBuffer)
        self.voronoiBuffer = GLSFrameBuffer(size: self.size)
        self.voronoiBuffer.position = self.viewSize.center
        self.tileBuffer = GLSFrameBuffer(size: self.size)
        self.glView?.addChild(self.voronoiBuffer)
        while let bufferCount = self.glView?.buffers.count, bufferCount > 0 {
            let _ = self.glView?.removeBuffer(at: 0)
        }
        self.glView?.add(buffer: self.tileBuffer)
        self.pointContainer.children.removeAll()
        self.edgeContainer.children.removeAll()
        //Moves it to front.
        let _ = self.glView?.removeChild(self.pointContainer)
        self.glView?.addChild(self.pointContainer)
        
        self.diagram = diagram
        let cells = diagram.sweep().cells
        
        self.cells = []
        for (i, cell) in cells.enumerated() {
            let s = GLSVoronoiSprite(cell: cell, boundaries: self.size)
            self.tileBuffer.addChild(s)
            
            let size = max(min(12.0, 36.0 / CGFloat(diagram.points.count) * 12.0), 6.0)
            let vs = GLSSprite(position: cell.voronoiPoint, size: CGSize(square: size), texture: "Outlined Circle")
            self.pointContainer.addChild(vs)
            
            let es = GLSVoronoiEdgeSprite(cell: cell, color: SCVector3.blackColor, thickness: 1.0)
            self.edgeContainer.addChild(es)
            
            self.cells.append(VoronoiCellSprite(cell: cell, sprite: s, hash: i))
        }
        self.tileBuffer.addChild(self.edgeContainer)
        
        if self.isTiled {
            let scales:[CGFloat] = [1.0, -1.0]
            for yScale in scales {
                for xScale in scales {
                    let tSprite = GLSSprite(size: self.size / 2.0, texture: self.tileBuffer.ccTexture)
                    tSprite.scaleX = xScale
                    tSprite.scaleY = yScale
                    tSprite.position = self.size.center - self.size.center * CGPoint(x: xScale, y: yScale) / 2.0
                    self.voronoiBuffer.addChild(tSprite)
                }
            }
        } else {
            let tSprite = GLSSprite(size: self.size, texture: self.tileBuffer.ccTexture)
            tSprite.anchor = CGPoint.zero
            self.voronoiBuffer.addChild(tSprite)
        }
        
        for cell in self.cells {
            cell.makeNeighbors(cells: self.cells)
        }
        
        self.colorCells()
        self.colorEdges()
    }
    
    func colorCells() {
        self.random = GKMersenneTwisterRandomSource(seed: self.seed)

        var indices:[Int] = []
        for i in 0..<self.colors.count {
            indices.append(i)
        }
        
        guard let first = self.cells.first else {
            return
        }
        
        //This algorithm is designed so that no 2 adjacent cells
        //have the same color. It doesn't work perfectly, but it
        //works for the majority of cells.
        var markedNodes = Set<VoronoiCellSprite>()
        var queue = Queue<VoronoiCellSprite>()
        queue.enqueue(first)
        
        while let top = queue.dequeue() {
            if markedNodes.contains(top) {
                continue
            }
            
            let validIndices = indices.filter() { i in !top.neighbors.contains() { n in n.colorIndex == i } }
            var index = indices[self.random.nextInt(upperBound: indices.count)]
            if let colorIndex = validIndices.objectAtIndex(self.random.nextInt(upperBound: validIndices.count)) {
                index = colorIndex
            }
            
            top.colorIndex = index
            top.sprite.shadeColor = self.colors[index].xyz
            top.sprite.alpha = self.colors[index].w
            markedNodes.insert(top)
            for neighbor in top.neighbors {
                queue.enqueue(neighbor)
            }
            
        }
        
    }
    
    func colorEdges() {
        for edge in self.edgeContainer.children {
            edge.shadeColor = self.edgeColor.xyz
            edge.alpha = self.edgeColor.w
        }
    }
    
    func regenerateSeed() {
        self.seed = UInt64(arc4random())
    }
    
}

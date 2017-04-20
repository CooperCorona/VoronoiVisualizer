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
    ///In tiled diagrams, cells can overlap opposite
    ///edges of the diagram. I don't want to change
    ///the meaning of the original ```neighbors```
    ///variable, so we now have ```allNeighbors```,
    ///which includes this cell's neighbors AND
    ///any of its potential opposite cells
    ///(represented by the ```observers``` array).
    var allNeighbors:[VoronoiCellSprite] {
        //The first flat map returns all the arrays
        //(filtering out nils), and the second flat
        //map literally flattens the 2d array into a 1d array.
        return self.neighbors + self.observers.flatMap() { $0.object?.neighbors } .flatMap() { $0 }
    }
    let hashValue:Int
    var colorIndex = -1
    ///Used in tiling. Sometimes, the oppositely edged
    ///sprite is found before the original tiled sprite,
    ///so we can't set the color index yet. We need to wait
    ///until that cell has its color set, then propogate
    ///that to all potential observers.
    var observers:[WeakReference<VoronoiCellSprite>] = []
    
    init(cell:VoronoiCell, sprite:GLSVoronoiSprite, hash:Int) {
        self.cell = cell
        self.sprite = sprite
        self.hashValue = hash
    }
    
    func makeNeighbors(cells:[VoronoiCellSprite]) {
        self.neighbors = self.cell.neighbors.flatMap() { n in cells.find() { c in c.cell === n } }
    }
    
    func set(colorIndex:Int, from colors:[SCVector4]) {
        self.colorIndex = colorIndex
        self.sprite.shadeColor = colors[colorIndex].xyz
        self.sprite.alpha = colors[colorIndex].a
        for observer in self.observers {
            observer.object?.set(colorIndex: colorIndex, from: colors)
        }
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
    var asTriangles = false
    private var seed:UInt64 = 0
    private var random = GKMersenneTwisterRandomSource(seed: 0)
    
    var isTiled:Bool = false {
        didSet {
            if let diagram = self.diagram {
                self.calculate(diagram: diagram)
            }
        }
    }
    var gradient = BilinearGradient()
    
    init(glView:OmniGLView2d?) {
        self.glView = glView
        
        self.checkerBackground = GLSCheckerSprite(off: SCVector4.lightGrayColor, on: SCVector4.whiteColor, size: NSSize(square: 48.0))
        self.checkerBackground.anchor = CGPoint.zero
        self.checkerBackground.position = CGPoint.zero
        self.glView?.addChild(self.checkerBackground)
        
        self.pointContainer.hidden = true
        self.edgeContainer.hidden  = true
        
        self.gradient.add(point: CGPoint(x: 0.0, y: 0.0), color: SCVector4.redColor)
        self.gradient.add(point: CGPoint(x: 0.0, y: 1.0), color: SCVector4.yellowColor)
        self.gradient.add(point: CGPoint(x: 1.0, y: 0.0), color: SCVector4.blueColor)
        self.gradient.add(point: CGPoint(x: 1.0, y: 1.0), color: SCVector4.greenColor)
        self.gradient.add(point: CGPoint(x: 0.5, y: 0.5), color: SCVector4.whiteColor)
    }
    
    func display() {
        self.renderToTexture()
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
        self.voronoiBuffer.renderChildren = false
        self.tileBuffer = GLSFrameBuffer(size: self.size)
        self.glView?.addChild(self.voronoiBuffer)
        while let bufferCount = self.glView?.buffers.count, bufferCount > 0 {
            let _ = self.glView?.removeBuffer(at: 0)
        }
        self.pointContainer.children.removeAll()
        self.edgeContainer.children.removeAll()
        //Moves it to front.
        let _ = self.glView?.removeChild(self.pointContainer)
        self.glView?.addChild(self.pointContainer)
        
        
        self.diagram = diagram
        let cells:[VoronoiCell]
        if self.isTiled {
            cells = diagram.sweep().tile().cells
        } else {
            cells = diagram.sweep().cells
        }
        
        self.cells = []
        for (i, cell) in cells.enumerated() {
            if self.asTriangles {
                let verts = cell.makeVertexLoop()
                let center = verts.reduce(CGPoint.zero) { $0 + $1 } / CGFloat(verts.count)
                let triangles = (0..<verts.count).map() { [center, verts[$0], verts[($0 + 1) % verts.count]] }
                for (j, triangle) in triangles.enumerated() {
                    let polygon = GLSPolygonSprite(polygonVertices: triangle, boundaries: CGRect(size: self.size))
                    polygon.texture = "White Tile"
                    if let c = self.colors.randomElement() {
                        polygon.shadeColor = c.xyz
                        polygon.alpha = c.a
                    }
                    self.tileBuffer.addChild(polygon)
                }
            } else {
                let s = GLSVoronoiSprite(cell: cell, boundaries: self.size)
                self.tileBuffer.addChild(s)
                self.cells.append(VoronoiCellSprite(cell: cell, sprite: s, hash: i))
            }
            
            let size = max(min(12.0, 36.0 / CGFloat(diagram.points.count) * 12.0), 6.0)
            let vs = GLSSprite(position: cell.voronoiPoint, size: CGSize(square: size), texture: "Outlined Circle")
            self.pointContainer.addChild(vs)
            
            let es = GLSVoronoiEdgeSprite(cell: cell, color: SCVector3.blackColor, thickness: 1.0)
            self.edgeContainer.addChild(es)
        }
        self.tileBuffer.addChild(self.edgeContainer)
        
        let tSprite = GLSSprite(size: self.size, texture: self.tileBuffer.ccTexture)
        tSprite.anchor = CGPoint.zero
        self.voronoiBuffer.addChild(tSprite)
        
        var dict:[UnsafeMutableRawPointer:VoronoiCellSprite] = [:]
        for cell in self.cells {
            dict[Unmanaged.passUnretained(cell.cell).toOpaque()] = cell
        }
        for cell in self.cells {
            cell.neighbors = cell.cell.neighbors.flatMap() { dict[Unmanaged.passUnretained($0).toOpaque()] }
        }
        
//        self.colorCells()
        /*
        print("\(self.gradient.color(at: CGPoint.zero, log: true))")
        print("\(self.gradient.color(at: CGPoint(x: 0.1)))")
        print("\(self.gradient.color(at: CGPoint(y: 0.1)))")
        print("\(self.gradient.color(at: CGPoint(xy: 0.1)))")
        */
        for cell in self.cells {
            let p = cell.cell.voronoiPoint * (1.0 / cell.cell.boundaries)
            let color = self.gradient.color(at: p)
            cell.sprite.shadeColor = color.xyz
            cell.sprite.alpha = color.a
        }
        self.colorEdges()
    }
    
    func colorCells() {
        guard let boundaries = self.diagram?.size else {
            return
        }
        
        //Reset the color indices, or else
        //pairing opposite cells with their
        //corresponding cells in tiled mode
        //uses old values, which will
        //either be incorrect or crash.
        for cell in self.cells {
            cell.colorIndex = -1
        }
        
        let frame = CGRect(size: boundaries)
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
            
            let validIndices = indices.filter() { i in !top.allNeighbors.contains() { n in n.colorIndex == i } }
            var index = indices[self.random.nextInt(upperBound: indices.count)]
            if let colorIndex = validIndices.objectAtIndex(self.random.nextInt(upperBound: validIndices.count)) {
                index = colorIndex
            }
            
            top.set(colorIndex: index, from: self.colors)
            markedNodes.insert(top)
            for neighbor in top.neighbors where frame.contains(neighbor.cell.voronoiPoint) {
                queue.enqueue(neighbor)
            }
            
            for neighbor in top.neighbors where !frame.contains(neighbor.cell.voronoiPoint) {
                guard let opposite = self.oppositeCell(for: neighbor, cells: self.cells) else {
                    continue
                }
                
                if opposite.colorIndex == -1 {
                    opposite.observers.append(WeakReference(object: neighbor))
                } else {
                    neighbor.set(colorIndex: opposite.colorIndex, from: self.colors)
                }
            }
            
        }
    }
    
    fileprivate func oppositeCell(for neighbor:VoronoiCellSprite, cells:[VoronoiCellSprite]) -> VoronoiCellSprite? {
        //TODO: Some cells originally touched both the left and right (or up and down)
        //boundaries, so I might need to return an array?
        var offset = CGPoint.zero
        if neighbor.cell.boundaryEdges.contains(.Left) {
            offset.x = +1.0
        }
        if neighbor.cell.boundaryEdges.contains(.Right) {
            offset.x = -1.0
        }
        if neighbor.cell.boundaryEdges.contains(.Down) {
            offset.y = +1.0
        }
        if neighbor.cell.boundaryEdges.contains(.Up) {
            offset.y = -1.0
        }
        let originalPoint = neighbor.cell.voronoiPoint + offset * neighbor.cell.boundaries
        if let cell = cells.find({ $0.cell.voronoiPoint ~= originalPoint && neighbor.cell.boundaries.contains(point: $0.cell.voronoiPoint) }) {
            return cell
        } else if let cell = cells.find({ $0.cell.voronoiPoint.x ~= originalPoint.x && neighbor.cell.boundaries.contains(point: $0.cell.voronoiPoint) }) {
            return cell
        } else if let cell = cells.find({ $0.cell.voronoiPoint.y ~= originalPoint.y && neighbor.cell.boundaries.contains(point: $0.cell.voronoiPoint) }) {
            return cell
        } else {
            return nil
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
    
    func renderToTexture() {
        GLSFrameBuffer.globalContext.makeCurrentContext()
        OmniGLView2d.setViewport(to: self.tileBuffer.contentSize)
        self.tileBuffer.renderToTexture()
        OmniGLView2d.setViewport(to: self.voronoiBuffer.contentSize)
        self.voronoiBuffer.renderToTexture()
        if let glView = self.glView {
            glView.openGLContext?.makeCurrentContext()
            OmniGLView2d.setViewport(to: glView.bounds.size)
        }
    }
    
}

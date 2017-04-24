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
    var edgeRenderingMode:EdgeRenderingMode = .edges {
        didSet {
            switch self.edgeRenderingMode {
            case .none:
                self.edgeContainer.hidden = true
            case .edges, .outline:
                self.edgeContainer.hidden = false
            }
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
    var coloringScheme:VoronoiViewColoringScheme = DiscreteColoringScheme(colors: SCVector4.rainbowColors)
    
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
        self.glView?.removeChild(self.pointContainer)
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
            let s = GLSVoronoiSprite(cell: cell, boundaries: self.size)
            self.tileBuffer.addChild(s)
            self.cells.append(VoronoiCellSprite(cell: cell, sprite: s, hash: i))
            
            let size = max(min(12.0, 36.0 / CGFloat(diagram.points.count) * 12.0), 6.0)
            let vs = GLSSprite(position: cell.voronoiPoint, size: CGSize(square: size), texture: "Outlined Circle")
            self.pointContainer.addChild(vs)
            
            let es = GLSVoronoiEdgeSprite(cell: cell, color: SCVector3.blackColor, thickness: 1.0, mode: self.edgeRenderingMode)
            self.edgeContainer.addChild(es)
        }
        
        let tSprite = GLSSprite(size: self.size, texture: self.tileBuffer.ccTexture)
        tSprite.anchor = CGPoint.zero
        self.voronoiBuffer.addChild(tSprite)
        self.voronoiBuffer.removeChild(self.edgeContainer)
        self.voronoiBuffer.addChild(self.edgeContainer)
//        self.glView?.removeChild(self.edgeContainer)
//        self.glView?.addChild(self.edgeContainer)
        
        var dict:[UnsafeMutableRawPointer:VoronoiCellSprite] = [:]
        for cell in self.cells {
            dict[Unmanaged.passUnretained(cell.cell).toOpaque()] = cell
        }
        for cell in self.cells {
            cell.neighbors = cell.cell.neighbors.flatMap() { dict[Unmanaged.passUnretained($0).toOpaque()] }
        }
        
        self.colorCells()
        self.colorEdges()
    }
    
    func colorCells() {
        guard let boundaries = self.diagram?.size else {
            return
        }
        let frame = CGRect(size: boundaries)
        
        for cell in self.cells where frame.contains(cell.cell.voronoiPoint) {
            guard cell.colorIndex == -1 else {
                continue
            }
            let (color, colorIndex) = self.coloringScheme.color(for: cell)
            if let index = colorIndex {
                cell.colorIndex = index
            }
            cell.sprite.shadeColor = color.xyz
            cell.sprite.alpha = color.a
        }
        for cell in self.cells where !frame.contains(cell.cell.voronoiPoint) {
            if let opposite = self.oppositeCell(for: cell, cells: self.cells) {
                cell.colorIndex = opposite.colorIndex
                cell.sprite.shadeColor = opposite.sprite.shadeColor
                cell.sprite.alpha = opposite.sprite.alpha
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

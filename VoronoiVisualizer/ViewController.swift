//
//  ViewController.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 9/16/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Foundation
import Cocoa
import CoronaConvenience
import CoronaStructures
import CoronaGL
import Voronoi

enum ParsePointError: Error {
    case Failed
}

extension CGPoint: Hashable {
    public var hashValue: Int {
        return (self.x.hashValue << 16) | (self.y.hashValue)
    }
}

class MonoColorVoronoiCell: Hashable {
    let cell:VoronoiCell
    let sprite:GLSNode
    let index:Int
    var neighbors:[MonoColorVoronoiCell] = []
    var colorIndex:Int? = nil
    var hashValue:Int { return self.index }
    
    init(cell:VoronoiCell, sprite:GLSNode, index:Int) {
        self.cell = cell
        self.sprite = sprite
        self.index = index
    }
    
}

func ==(lhs:MonoColorVoronoiCell, rhs:MonoColorVoronoiCell) -> Bool {
    //In practice, this wouldn't work,
    //but we always assign unique values
    //to the index property, so it's fine.
    return lhs.index == rhs.index
}

class ViewController: NSViewController {

    enum ColorMode {
        case Rainbow
        case Hover
        case Mono(SCVector3)
    }
    
    @IBOutlet weak var glView: OmniGLView2d!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var sizeLabel: NSTextField!
    @IBOutlet weak var rowTextField: NSTextField!
    @IBOutlet weak var columnTextField: NSTextField!
    
    var sprites:[GLSNode] = []
    var edgeSprites:[GLSNode] = []
    var pointSprites:[GLSSprite] = []
    var diagram:VoronoiDiagram? = nil
    var points:[CGPoint] = []
    var dragIndex:Int? = nil
    var initialMouseLocation = NSPoint.zero
    var initialDragPoint = NSPoint.zero
    var currentHoverCellIndex:Int? = nil
    
    var colorMode = ColorMode.Rainbow {
        didSet {
            self.colorSprites()
        }
    }
    
    var undoStack = Stack<[CGPoint]>()
    var redoStack = Stack<[CGPoint]>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GLSFrameBuffer.globalContext.makeCurrentContext()
        CCTextureOrganizer.sharedInstance.files = ["Atlases"]
        CCTextureOrganizer.sharedInstance.loadTextures()
        ShaderHelper.sharedInstance.loadPrograms([
            "Basic Shader":"BasicShader",
            "Color Shader":"ColorShader",
            "Color Wheel Shader":"ColorWheelShader"
        ])
        self.glView.clearColor = SCVector4.blackColor
        
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
        
    }

    @IBAction func randomizeButtonPressed(_ sender: AnyObject) {
        guard self.rowTextField.stringValue.matchesRegex("^\\d+$") else {
            self.displayAlert(text: "Rows must be an integer")
            return
        }
        guard self.columnTextField.stringValue.matchesRegex("^\\d+$") else {
            self.displayAlert(text: "Columns must be an integer")
            return
        }
        guard self.rowTextField.integerValue > 0 else {
            self.displayAlert(text: "Rows must be greater than 0.")
            return
        }
        guard self.columnTextField.integerValue > 0 else {
            self.displayAlert(text: "Column must be greater than 0.")
            return
        }
        let rows = self.rowTextField.integerValue
        let columns = self.columnTextField.integerValue
        guard rows * columns > 1 else {
            self.displayAlert(text: "Number of points must be greater than 1.")
            return
        }
        let diagram = VoronoiDiagram.createWithSize(self.glView.frame.size, rows: rows, columns: columns, range: 1.0)
        
        if let oldDiagram = self.diagram {
            //Add undo, remove all redos
            self.undoStack.push(oldDiagram.points)
            while self.redoStack.count > 0 {
                let _ = self.redoStack.pop()
            }
        }
        
        self.display(diagram: diagram)
    }
    
    func display(diagram:VoronoiDiagram) {
        for s in self.sprites {
            let _ = self.glView.removeChild(s)
        }
        self.sprites = []
        for s in self.edgeSprites {
            let _ = self.glView.removeChild(s)
        }
        self.edgeSprites = []
        for s in self.pointSprites {
            let _ = self.glView.removeChild(s)
        }
        self.pointSprites = []
        
        let result = diagram.sweep()
        
        for (i, cell) in result.cells.enumerated() {
            
            let s = GLSVoronoiSprite(cell: cell, boundaries: self.glView.frame.size)
            self.glView.container.addChild(s)
            self.sprites.append(s)
            
            let size = max(min(12.0, 36.0 / CGFloat(diagram.points.count) * 12.0), 4.0)
            let vs = GLSSprite(position: cell.voronoiPoint, size: CGSize(square: size), texture: "White Circle")
            self.glView.container.addChild(vs)
            self.pointSprites.append(vs)
            
            let es = GLSVoronoiEdgeSprite(cell: cell, color: SCVector3.blackColor, thickness: 1.0)
            self.glView.addChild(es)
            self.edgeSprites.append(es)
        }
        
        self.currentHoverCellIndex = nil
        self.colorSprites()
 
        
        self.textView.string = diagram.points.sorted() { $0.y < $1.y } .reduce("") { (a:String, b:CGPoint) in
            "\(a)\(b.clampDecimals(6))\n"
        }
        
        let _ = self.textView.string!.removeLast()
 
        /*
        for edge in diagram.edges {
            let distance = edge.startPoint.distanceFrom(edge.endPoint)
            let angle = edge.startPoint.angleTo(edge.endPoint)
            let s = GLSSprite(position: edge.startPoint, size: CGSize(width: distance, height: 4.0), texture: "White Tile")
            s.anchor = CGPoint(x: 0.0, y: 0.5)
            s.rotation = angle
            self.glView.addChild(s)
            self.sprites.append(s)
        }
        */
 
        self.glView.display()
        self.diagram = diagram
        self.points = diagram.points
    }
    
    func colorSprites() {
        switch self.colorMode {
        case .Rainbow:
            self.colorDiagramRainbow()
        case .Hover:
            self.colorDiagramHover()
        case let .Mono(color):
            self.colorDiagramMono(color: color)
        }
    }
    
    func colorDiagramRainbow() {
        for (i, sprite) in self.sprites.enumerated() {
            sprite.stopAnimations()
            sprite.shadeColor = SCVector3.rainbowColorAtIndex(i)
        }
        for point in self.pointSprites {
            point.hidden = false
        }
        for edge in self.edgeSprites {
            edge.shadeColor = SCVector3.blackColor
            edge.hidden = false
        }
    }
    
    func colorDiagramHover() {
        for sprite in self.sprites {
            sprite.stopAnimations()
            sprite.shadeColor = SCVector3.blackColor
        }
        for point in self.pointSprites {
            point.hidden = false
        }
        for edge in self.edgeSprites {
            edge.shadeColor = SCVector3.whiteColor * 0.1
            edge.hidden = false
        }
    }
    
    func colorDiagramMono(color:SCVector3) {
        let shades:[CGFloat] = [0.9, 0.933, 0.967, 1.0]
        let indices = [0, 1, 2, 3]
        
        guard let monoCells = self.getMonoCells() else {
            return
        }
        
        /*for sprite in self.sprites {
            sprite.shadeColor = color * shades.randomObject()!
        }*/
        for point in self.pointSprites {
            point.hidden = true
        }
        for edge in self.edgeSprites {
            edge.hidden = true
        }
        
        guard let first = monoCells.first else {
            return
        }
        
        //This algorithm is designed so that no 2 adjacent cells
        //have the same color. It doesn't work perfectly, but it
        //works for the majority of cells.
        var markedNodes = Set<MonoColorVoronoiCell>()
        var queue = Queue<MonoColorVoronoiCell>()
        queue.enqueue(first)
        
        while let top = queue.dequeue() {
            if markedNodes.contains(top) {
                continue
            }
            
            let validIndices = indices.filter() { i in !top.neighbors.contains() { n in n.colorIndex == i } }
            var index = indices.randomElement()!
            if let colorIndex = validIndices.randomElement() {
                index = colorIndex
            }
            
            top.colorIndex = index
//            top.sprite.shadeColor = SCVector3.rainbowColorAtIndex(index)
            top.sprite.shadeColor = color * shades[index]
            markedNodes.insert(top)
            for neighbor in top.neighbors {
                queue.enqueue(neighbor)
            }
        }
    }
    
    private func getMonoCells() -> [MonoColorVoronoiCell]? {
        
        guard let cells = self.diagram?.sweep().cells else {
            return nil
        }
        var monoCells:[MonoColorVoronoiCell] = []
        for (i, cell) in cells.enumerated() {
            monoCells.append(MonoColorVoronoiCell(cell: cell, sprite: self.getSpriteFor(cell: cell, in: cells)!, index: i))
        }
        for cell in monoCells {
            let cellNeighbors = cell.cell.neighbors
            cell.neighbors = monoCells.filter() { m in cellNeighbors.contains() { c in m.cell === c } }
        }
        return monoCells
    }
    
    func createDiagramFor(points:[CGPoint]) {
        let diagram = VoronoiDiagram(points: points, size: self.glView.frame.size)
        
        if let oldDiagram = self.diagram {
            //Add undo, remove all redos
            self.undoStack.push(oldDiagram.points)
            while self.redoStack.count > 0 {
                let _ = self.redoStack.pop()
            }
        }
        
        self.display(diagram: diagram)
    }

    func viewDidResize() {
        self.sizeLabel.stringValue = "Size: \(self.glView.frame.size)"
    }
    
    func split(string:String) -> [String] {
        var cur = ""
        var strs:[String] = []
        for i in 0..<string.characterCount {
            if string[i] == "\n" {
                strs.append(cur)
                cur = ""
            } else {
                cur = "\(cur)\(string[i]!)"
            }
        }
        strs.append(cur)
        return strs
    }
    
    func parsePoints() throws -> [CGPoint] {
        let lines = self.split(string: self.textView.string!).map() { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
        //This regex matches strings of the form (Number, Number)
        //where that is the only text in the string.
        guard let regex = NSRegularExpression(regex: "^\\([0-9]+\\.*[0-9]*,\\s[0-9]+\\.*[0-9]*\\)$") else {
            throw ParsePointError.Failed
        }
        
        var usedPoints = Set<CGPoint>()
        for (i, line) in lines.enumerated() where line != "" {
            if !line.matchesRegex(regex.pattern) {
                self.highlight(line: i)
                self.displayAlert(text: "This line is malformatted.")
                throw ParsePointError.Failed
            }
            let point = NSPointFromString(line)
            if usedPoints.contains(point) {
                self.highlight(line: i)
                self.displayAlert(text: "You've already used this point.")
                throw ParsePointError.Failed
            }
            if point.x <= 0.0 || point.x >= self.glView.frame.width || point.y <= 0.0 || point.y >= self.glView.frame.height {
                self.highlight(line: i)
                self.displayAlert(text: "This point is outside the bounds (0.0, 0.0) - \(self.glView.frame.size).")
                throw ParsePointError.Failed
            }
            
            usedPoints.insert(point)
        }
        guard usedPoints.count > 1 else {
            self.displayAlert(text: "More than 1 point is required.")
            throw ParsePointError.Failed
        }
        
        return usedPoints.toArray()
    }
    
    @IBAction func calculateButtonPressed(_ sender: AnyObject) {
        do {
            let points = try self.parsePoints()
            self.createDiagramFor(points: points)
        } catch {
            
        }
        
    }
    
    func displayAlert(text:String) {
        let alert = NSAlert()
        alert.alertStyle = NSAlertStyle.critical
        alert.messageText = text
        alert.addButton(withTitle: "Ok")
        alert.runModal()
    }
    
    func highlight(line:Int) {
        guard let string = self.textView.string else {
            return
        }
        var newlineCount = 0
        var newlineStart = 0
        var newlineEnd = string.characterCount
        for i in 0..<string.characterCount {
            if string[i..<i+1] == "\n" {
                newlineCount += 1
                if newlineCount == line {
                    newlineStart = i + 1
                } else if newlineCount == line + 1 {
                    newlineEnd = i
                    break
                }
            }
        }
        let nsrange = NSRange(location: newlineStart, length: newlineEnd - newlineStart)
        self.textView.scrollRangeToVisible(nsrange)
        self.textView.showFindIndicator(for: nsrange)
    }
    
    @IBAction func backButtonPressed(_ sender: AnyObject) {
        if let top = self.undoStack.pop() {
            if let oldDiagram = self.diagram {
                self.redoStack.push(oldDiagram.points)
            }
            let diagram = VoronoiDiagram(points: top, size: self.glView.frame.size)
            self.display(diagram: diagram)
        }
    }
    
    @IBAction func nextButtonPressed(_ sender: AnyObject) {
        if let top = self.redoStack.pop() {
            if let oldDiagram = self.diagram {
                self.undoStack.push(oldDiagram.points)
            }
            let diagram = VoronoiDiagram(points: top, size: self.glView.frame.size)
            self.display(diagram: diagram)
        }
    }
 
    func getGLLocation(event:NSEvent) -> NSPoint {
        return event.locationInWindow - self.glView.frame.origin
    }
    
    override func mouseMoved(with event: NSEvent) {
        switch self.colorMode {
        case .Hover:
            break
        default:
            return
        }
        guard let cells = self.diagram?.sweep().cells else {
            return
        }
        let location = self.getGLLocation(event: event)
        var lastIndex = self.currentHoverCellIndex
        if let cellIndex = cells.index(where: { $0.contains(point: location) }) {
            if let lastCellIndex = self.currentHoverCellIndex {
                self.sprites[lastCellIndex].shadeColor = SCVector3.blackColor
                let neighbors = cells[lastCellIndex].neighbors.flatMap() { self.getSpriteFor(cell: $0, in: cells) }
                for neighbor in neighbors {
                    neighbor.shadeColor = SCVector3.blackColor
                }
            }
            self.currentHoverCellIndex = cellIndex
            self.sprites[cellIndex].shadeColor = SCVector3.redColor * 0.75
            let neighbors = cells[cellIndex].neighbors.flatMap() { self.getSpriteFor(cell: $0, in: cells) }
            for neighbor in neighbors {
                neighbor.shadeColor = SCVector3.redColor * 0.5
            }
            if lastIndex != cellIndex {
                self.glView.display()
            }
        }
        
    }
    
    override func mouseDown(with event: NSEvent) {
        guard self.points.count <= 64 else {
            //Any more points, and the calculations become
            //unfeasibly slow to have nice dragging. The actual
            //number is probably higher than 64, but I don't
            //know what it is, so 64 is probably a good lower bound.
            return
        }
        self.dragIndex = nil
        let location = self.getGLLocation(event: event)
        for (i, point) in self.points.enumerated() {
            if point.distanceFrom(location) <= 16.0 {
                self.dragIndex = i
                break
            }
        }
        guard let dragIndex = self.dragIndex else {
            return
        }
        self.initialMouseLocation = location
        self.initialDragPoint = self.points[dragIndex]
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let dragIndex = self.dragIndex else {
            return
        }
        guard self.points.count <= 64 else {
            return
        }
        let location = self.getGLLocation(event: event)
        let delta = location - self.initialMouseLocation
        let newPoint = self.initialDragPoint + delta
        self.points[dragIndex] = newPoint
        self.createDiagramFor(points: points)
    }
    
    override func mouseUp(with event: NSEvent) {
        guard self.dragIndex == nil else {
            self.dragIndex = nil
            return
        }
        guard self.glView.frame.contains(event.locationInWindow) else {
            return
        }
        let location = self.getGLLocation(event: event)
        self.points.append(location)
        self.createDiagramFor(points: self.points)
    }
    
    @IBAction func colorModeChanged(_ sender: NSPopUpButton) {
        guard let title = sender.selectedItem?.title else {
            return
        }
        if title == "Rainbow" {
            self.colorMode = .Rainbow
        } else if title == "Hover" {
            self.colorMode = .Hover
        } else if title == "Mono" {
            let colorController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "colorSliderController") as! ColorSliderController
            self.presentViewControllerAsSheet(colorController)
            return
        }
        self.glView.display()
    }
    
    func getSpriteFor(cell:VoronoiCell, in cells:[VoronoiCell]) -> GLSNode? {
        for (i, sprite) in self.sprites.enumerated() {
            if cells[i] === cell {
                return sprite
            }
        }
        return nil
    }
    
}


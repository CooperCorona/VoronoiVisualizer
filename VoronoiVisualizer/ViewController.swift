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

class ViewController: NSViewController, ResizableViewController, NSTextFieldDelegate {

    enum TextFieldTag: Int, Hashable {
        case Rows       = 0
        case Columns    = 1
        case Width      = 2
        case Height     = 3
        
        var hashValue:Int { return self.rawValue }
    }
    
    @IBOutlet weak var glView: OmniGLView2d!
    lazy var voronoiView:VoronoiView = VoronoiView(glView: self.glView)
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var rowTextField: NSTextField!
    @IBOutlet weak var columnTextField: NSTextField!
    @IBOutlet weak var widthTextField: NSTextField!
    @IBOutlet weak var heightTextField: NSTextField!
    @IBOutlet weak var edgesCheckbox: NSButton!
    @IBOutlet weak var pointsCheckbox: NSButton!
    var previousText:[TextFieldTag:String] = [:]
    var bufferSize:CGSize {
        get { return CGSize(width: self.widthTextField.doubleValue, height: self.heightTextField.doubleValue) }
        set {
            self.widthTextField.doubleValue  = Double(newValue.width)
            self.heightTextField.doubleValue = Double(newValue.height)
        }
    }
    
    var points:[CGPoint] = []
    var dragIndex:Int? = nil
    var initialMouseLocation = NSPoint.zero
    var initialDragPoint = NSPoint.zero
    var currentHoverCellIndex:Int? = nil
    
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
            "Color Wheel Shader":"ColorWheelShader",
            "Checker Shader":"CheckerShader"
        ])
        self.glView.clearColor = SCVector4.blackColor

        self.rowTextField.delegate      = self
        self.columnTextField.delegate   = self
        self.widthTextField.delegate    = self
        self.heightTextField.delegate   = self
        self.previousText[.Rows]    = self.rowTextField.stringValue
        self.previousText[.Columns] = self.columnTextField.stringValue
        self.previousText[.Width]   = self.widthTextField.stringValue
        self.previousText[.Height]  = self.heightTextField.stringValue
        
        self.voronoiView.colors = SCVector4.rainbowColors
        self.voronoiView.viewDidResize()
    }
 
    override func viewWillAppear() {
        super.viewWillAppear()
        NotificationCenter.default.addObserver(self, selector: #selector(exportButtonPressed), name: Notification.Name(rawValue: AppDelegate.ExportImageNotification), object: nil)
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
        self.voronoiView.size = CGSize(width: self.widthTextField.doubleValue, height: self.heightTextField.doubleValue)
        self.voronoiView.calculateRandom(rows: rows, columns: columns)
        self.voronoiView.display()
        
        self.setPointText()
    }
    
    func setPointText() {
        self.points = self.voronoiView.points
        var str = ""
        for point in self.points {
            str = "\(str)\(point.clampDecimals(2))\n"
        }
        self.textView.string = str
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else {
            return
        }
        guard let fieldType = TextFieldTag(rawValue: textField.tag) else {
            return
        }
        
        if textField.stringValue.matchesRegex("^\\d+$") {
            if textField.integerValue < 1 {
                textField.stringValue = "1"
            } else if textField.integerValue > 1024 {
                textField.stringValue = "1024"
            }
            self.previousText[fieldType] = textField.stringValue
        } else {
            textField.stringValue = self.previousText[fieldType]!
        }
        
    }
    
    func display() {
        self.glView.display()
    }
    
    func viewDidResize() {
        self.voronoiView.viewDidResize()
    }
    
    // MARK: - Parsing Points
    
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
            self.voronoiView.size = CGSize(width: self.widthTextField.doubleValue, height: self.heightTextField.doubleValue)
            let points = try self.parsePoints()
            self.points = points
            self.voronoiView.points = points
            self.voronoiView.calculate()
            self.voronoiView.display()
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
    
    // MARK: - Mouse Events
    
    func getGLLocation(event:NSEvent) -> NSPoint {
        return event.locationInWindow - self.glView.frame.origin - self.voronoiView.voronoiBuffer.position + self.voronoiView.voronoiBuffer.anchor * self.voronoiView.voronoiBuffer.contentSize
    }
    
    override func mouseMoved(with event: NSEvent) {
        /*
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
                self.display()
            }
        }
        */
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
        self.voronoiView.points = self.points
        self.voronoiView.calculate()
        self.voronoiView.display()
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
        self.voronoiView.points = self.points
        self.voronoiView.calculate()
        self.voronoiView.display()
    }
    
    @IBAction func edgesCheckboxChanged(_ sender: Any) {
        self.voronoiView.renderEdges = self.edgesCheckbox.integerValue != 0
        self.voronoiView.display()
    }
    
    @IBAction func pointsCheckboxChanged(_ sender: Any) {
        self.voronoiView.renderPoints = self.pointsCheckbox.integerValue != 0
        self.voronoiView.display()
    }
    
    @IBAction func colorButtonPressed(_ sender: Any) {
        let colorController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "colorSliderController") as! ColorSliderController
        let _ = colorController.colorList.set(colors: self.voronoiView.colors.map() { NSColor(vector4: $0) })
        colorController.dismissHandler = {
            self.voronoiView.colors = $0.map() { c in c.getVector4() }
            self.voronoiView.calculate()
            self.voronoiView.display()
        }
        self.presentViewControllerAsSheet(colorController)
    }
    
    @IBAction func edgeColorButtonPressed(_ sender: Any) {
        let colorController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "colorSliderController") as! ColorSliderController
        colorController.displayColorList = false
        let _ = colorController.colorList.set(colors: self.voronoiView.colors.map() { NSColor(vector4: $0) })
        colorController.initialColor = NSColor(vector4: self.voronoiView.edgeColor)
        colorController.dismissHandler = {
            self.voronoiView.edgeColor = $0.first!.getVector4()
            self.voronoiView.display()
        }
        self.presentViewControllerAsSheet(colorController)
    }
    
    @IBAction func relaxButtonPressed(_ sender: Any) {
        guard let diagram = self.voronoiView.diagram else {
            return
        }
        let cells = diagram.sweep().cells
        let points = cells.map() { cell -> CGPoint in
            let vertices = cell.makeVertexLoop()
            return vertices.reduce(CGPoint.zero) { $0 + $1 } / CGFloat(vertices.count)
        }
        self.voronoiView.points = points
        self.voronoiView.calculate()
        self.voronoiView.display()
        
        self.setPointText()
    }
 
    
    func exportButtonPressed(notification:Notification) {
        let panel = NSSavePanel()
        panel.canSelectHiddenExtension = true
        panel.allowedFileTypes = ["png"]
        switch panel.runModal() {
        case NSModalResponseOK:
            guard let url = panel.url else {
                return
            }
            let image = self.voronoiView.voronoiBuffer.getImage()
            let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
            let bitmap = NSBitmapImageRep(cgImage: cgImage)
            bitmap.size = image.size
            let data = bitmap.representation(using: NSBitmapImageFileType.PNG, properties: [:])
            do {
                try data?.write(to: url, options: .atomic)
            } catch {
                print(error)
            }
        default:
            break
        }
    }
    
}


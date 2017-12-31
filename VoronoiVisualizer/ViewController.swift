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
import GLKit

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
    @IBOutlet weak var edgePopUpButton: NSPopUpButton!
    @IBOutlet weak var pointsCheckbox: NSButton!
    @IBOutlet weak var edgeThicknessTextBox: NSTextField!
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(imageMenuItemClicked(notification:)), name: Notification.Name(rawValue: AppDelegate.ImageNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(maskMenuItemClicked(notification:)), name: Notification.Name(rawValue: AppDelegate.MaskNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(noImageMenuItemClicked(notification:)), name: Notification.Name(rawValue: AppDelegate.NoImageNotification), object: nil)
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
            } else if textField.integerValue > 2048 {
                textField.stringValue = "2048"
            }
            self.previousText[fieldType] = textField.stringValue
        } else {
            textField.stringValue = self.previousText[fieldType]!
        }
        
    }
    
    func display() {
        self.voronoiView.display()
    }
    
    func viewDidResize() {
        self.voronoiView.viewDidResize()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        switch segue.identifier?.rawValue {
        case "edgeColorSegue"?:
            guard let destination = segue.destinationController as? ColorChooserController else {
                break
            }
            destination.doneButtonHidden = false
            destination.set(color: NSColor(vector4: self.voronoiView.edgeColor))
            destination.dismissHandler = { [unowned self] in
                self.voronoiView.edgeColor = $0.getVector4()
                self.voronoiView.display()
            }
        default:
            break
        }
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
        let lines = self.split(string: self.textView.string).map() { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
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
        alert.alertStyle = NSAlert.Style.critical
        alert.messageText = text
        alert.addButton(withTitle: "Ok")
        alert.runModal()
    }
    
    func highlight(line:Int) {
        let string = self.textView.string
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
    
    @IBAction func edgePopUpButtonChanged(_ sender: NSPopUpButton) {
        switch sender.selectedItem?.title {
        case "None"?:
            self.voronoiView.edgeRenderingMode = .none
        case "Edges"?:
            self.voronoiView.edgeRenderingMode = .edges
        case "Outline"?:
            self.voronoiView.edgeRenderingMode = .outline
        default:
            break
        }
        self.voronoiView.calculate()
        self.voronoiView.display()
    }
    
    @IBAction func pointsCheckboxChanged(_ sender: Any) {
        self.voronoiView.renderPoints = self.pointsCheckbox.integerValue != 0
        self.voronoiView.display()
    }
    
    @IBAction func colorButtonPressed(_ sender: Any) {
        let colorController = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "colorController")) as! ColorSplitViewController
        colorController.coloringScheme = self.voronoiView.coloringScheme
        if let colorTab = colorController.childViewControllers.find({ $0 is ColorTabViewController }) as? ColorTabViewController {
            let dismissHandler:(VoronoiViewColoringScheme) -> Void = { [unowned self] in
                self.voronoiView.coloringScheme = $0
                self.voronoiView.calculate()
                self.voronoiView.display()
            }
            for child in colorTab.childViewControllers {
                if let schemeController = child as? ColoringSchemeViewController {
                    schemeController.dismissHandler = dismissHandler
                }
            }
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
            //This weighting causes vertices further from the
            //voronoi point to be weighted more. This has the
            //effect of making vertices on the edge of the
            //diagram to be slightly more similar to the
            //rest of the cells.
            let distances = vertices.map() { ($0, $0.distanceFrom(cell.voronoiPoint)) }
            let totalDistance = distances.reduce(0.0) { $0 + $1.1 }
            let weightedDistances = distances.map() { ($0.0, $0.1 / totalDistance) }
            return weightedDistances.reduce(CGPoint.zero) { $0 + $1.0 * $1.1 }
            
            //This is the normal weighting. I'm not sure if I like
            //the other weighting better or not, so I'm leaving it here.
//            return vertices.reduce(CGPoint.zero) { $0 + $1 } / CGFloat(vertices.count)
        }
        self.voronoiView.points = points
        self.voronoiView.calculate()
        self.voronoiView.display()
        
        self.setPointText()
    }
 
    
    @objc func exportButtonPressed(notification:Notification) {
        let panel = NSSavePanel()
        panel.canSelectHiddenExtension = true
        panel.allowedFileTypes = ["png"]
        switch panel.runModal() {
        case NSApplication.ModalResponse.OK:
            guard let url = panel.url else {
                return
            }
            
            let image = self.voronoiView.voronoiBuffer.getImage()
            let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
            let bitmap = NSBitmapImageRep(cgImage: cgImage)
            bitmap.size = image.size
            let data = bitmap.representation(using: NSBitmapImageRep.FileType.png, properties: [:])
            do {
                try data?.write(to: url, options: .atomic)
            } catch {
                print(error)
            }
        default:
            break
        }
    }
    
    @objc func imageMenuItemClicked(notification:Notification) {
        guard let texture = self.openImageLoadTexture() else {
            return
        }
        self.voronoiView.imageMask.imageMask = .image(texture)
        self.voronoiView.display()
    }
    
    @objc func maskMenuItemClicked(notification:Notification) {
        guard let texture = self.openImageLoadTexture() else {
            return
        }
        self.voronoiView.imageMask.imageMask = .mask(texture)
        self.voronoiView.display()
    }
    
    @objc func noImageMenuItemClicked(notification:Notification) {
        self.voronoiView.imageMask.imageMask = .none
        self.voronoiView.display()
    }
    
    private func openImageLoadTexture() -> CCTexture? {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["png"]
        switch panel.runModal() {
        case NSApplication.ModalResponse.OK:
            guard let url = panel.url else {
                return nil
            }
            guard let glTexture = try? GLKTextureLoader.texture(withContentsOf: url, options: [GLKTextureLoaderOriginBottomLeft:true]) else {
                return nil
            }
            return CCTexture(name: glTexture.name)
        default:
            return nil
        }
    }
    
    func gradientItemClicked(notification:Notification) {
        let controller = NSStoryboard(name: NSStoryboard.Name(rawValue: "Main"), bundle: nil).instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "colorController")) as! NSViewController
        self.presentViewControllerAsModalWindow(controller)
    }
    
    @IBAction func edgeTextBoxChanged(_ sender: Any) {
        guard self.edgeThicknessTextBox.stringValue.matchesRegex("\\d+(\\.\\d+)?") else {
            self.edgeThicknessTextBox.stringValue = "\(self.voronoiView.edgeThickness)"
            return
        }
        let value = self.edgeThicknessTextBox.stringValue.getCGFloatValue()
        guard value > 0.0 else {
            self.edgeThicknessTextBox.stringValue = "\(self.voronoiView.edgeThickness)"
            return
        }
        self.voronoiView.edgeThickness = value
        self.voronoiView.calculate()
        self.voronoiView.display()
    }
    
    @IBAction func tiledCheckboxChanged(_ sender: NSButton) {
        self.voronoiView.isTiled = sender.integerValue == 0 ? false : true
        self.display()
    }
}


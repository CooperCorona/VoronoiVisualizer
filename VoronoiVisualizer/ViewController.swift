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

extension CGPoint: Hashable {
    public var hashValue: Int {
        return (self.x.hashValue << 16) | (self.y.hashValue)
    }
}

class ViewController: NSViewController {

    @IBOutlet weak var glView: OmniGLView2d!
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var sizeLabel: NSTextField!
    @IBOutlet weak var rowTextField: NSTextField!
    @IBOutlet weak var columnTextField: NSTextField!
    
    var sprites:[GLSNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GLSFrameBuffer.globalContext.makeCurrentContext()
        CCTextureOrganizer.sharedInstance.files = ["Atlases"]
        CCTextureOrganizer.sharedInstance.loadTextures()
        ShaderHelper.sharedInstance.loadPrograms([
            "Basic Shader":"BasicShader",
            "Color Shader":"ColorShader"
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
        self.display(diagram: diagram)
    }
    
    func display(diagram:VoronoiDiagram) {
        for s in self.sprites {
            self.glView.removeChild(s)
        }
        self.sprites = []
        
        let result = diagram.sweep()
        for (i, cell) in result.cells.enumerated() {
            let s = GLSVoronoiSprite(cell: cell, boundaries: self.glView.frame.size)
            s.alpha = 0.75
            s.shadeColor = SCVector3.rainbowColorAtIndex(i)
            self.glView.container.addChild(s)
            self.sprites.append(s)
            
            let vs = GLSSprite(position: cell.voronoiPoint, size: CGSize(square: 12.0), texture: "White Circle")
            self.glView.container.addChild(vs)
            self.sprites.append(vs)
            
            let es = GLSVoronoiEdgeSprite(cell: cell, color: SCVector4.blackColor, thickness: 1.0)
            self.glView.addChild(es)
            self.sprites.append(es)
        }
        
        self.textView.string = diagram.points.reduce("") { (a:String, b:CGPoint) in
            "\(a)\(b.clampDecimals(2))\n"
        }
        self.textView.string!.removeLast()
        
        self.glView.display()
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
    
    @IBAction func calculateButtonPressed(_ sender: AnyObject) {
        let lines = self.split(string: self.textView.string!).map() { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
        //This regex matches strings of the form (Number, Number)
        //where that is the only text in the string.
        guard let regex = NSRegularExpression(regex: "^\\([0-9]+\\.*[0-9]*,\\s[0-9]+\\.*[0-9]*\\)$") else {
            return
        }
        
        var usedPoints = Set<CGPoint>()
        for (i, line) in lines.enumerated() where line != "" {
            if !line.matchesRegex(regex.pattern) {
                self.highlight(line: i)
                self.displayAlert(text: "This line is malformatted.")
                return
            }
            let point = NSPointFromString(line)
            if usedPoints.contains(point) {
                self.highlight(line: i)
                self.displayAlert(text: "You've already used this point.")
                return
            }
            if point.x <= 0.0 || point.x >= self.glView.frame.width || point.y <= 0.0 || point.y >= self.glView.frame.height {
                self.highlight(line: i)
                self.displayAlert(text: "This point is outside the bounds (0.0, 0.0) - \(self.glView.frame.size).")
                return
            }
            
            usedPoints.insert(point)
        }
        guard usedPoints.count > 1 else {
            self.displayAlert(text: "More than 1 point is required.")
            return
        }
        
        let diagram = VoronoiDiagram(points: usedPoints.toArray(), size: self.glView.frame.size)
        self.display(diagram: diagram)
        
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
    
}


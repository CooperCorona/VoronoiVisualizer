//
//  TreeController.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 10/2/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Cocoa
import CoronaConvenience
@testable import Voronoi

class TreeController: NSViewController {

    var views:[NSView] = []
    let font = NSFont(descriptor: NSFontDescriptor(name: "Arial", size: 8.0), size: 8.0)!
    
    var edgeLabels:[NSTextField] = []
    var edgeText:[String] = []
    var displayStart = true
    
    func generateViews(diagram:VoronoiDiagram) {
        self.generateViews(head: diagram.parabolaTree.root, minX: 0.0, maxX: self.view.frame.width, y: 0.0, color: 0)
        
        var lastFrame = NSRect.zero
        for edge in diagram.edges {
            let text = NSTextField(frame: lastFrame)
            text.isEditable = false
            if edge.hasSetEnd {
                text.stringValue = "\(edge.startPoint.clampDecimals(0)) -> \(edge.endPoint.clampDecimals(0))"
            } else {
                text.stringValue = "\(edge.startPoint.clampDecimals(0)) ^^ \(edge.directionVector.clampDecimals(0))"
            }
            text.sizeToFit()
            text.frame.origin = NSPoint(x: lastFrame.maxX + 4.0, y: lastFrame.origin.y)
            if text.frame.maxX > self.view.frame.width {
                text.frame.origin = NSPoint(x:0.0, y: lastFrame.maxY + 4.0)
            }
            lastFrame = text.frame
            text.frame.origin.y = self.view.frame.height - text.frame.origin.y - text.frame.height
            self.view.addSubview(text)
        }
    }
    
    func generateViews(head:VoronoiParabola?, minX:CGFloat, maxX:CGFloat, y:CGFloat, color:UInt8) {
        guard let head = head else {
            return
        }
        let frame = NSRect(x: minX, y: y, width: maxX - minX, height: 64.0)

        let v = NSView(frame: frame)
        v.wantsLayer = true
        let gray:CGFloat
        switch color {
        case 0:
            gray = 0.75
        case 1:
            gray = 0.67
        case 2:
            gray = 0.6
        case 3:
            gray = 0.55
        default:
            gray = 1.0
        }
        if head.circleEvent != nil {
            v.layer?.backgroundColor = NSColor(calibratedRed: gray + 0.2, green: gray, blue: gray, alpha: 1.0).cgColor
        } else {
            v.layer?.backgroundColor = NSColor(calibratedWhite: gray, alpha: 1.0).cgColor
        }
        self.views.append(v)
        self.view.addSubview(v)
        
        let label = NSTextField(frame: NSRect(size: frame.size))
        label.font = self.font
        label.isEditable = false
        label.stringValue = "\(head.focus.clampDecimals(1))"
        label.sizeToFit()
        label.frame.center = frame.size.center
        v.addSubview(label)
        
        if let le = head.leftEdge {
            let leftEdgeLabel = NSTextField(frame: NSRect(size: frame.size))
            leftEdgeLabel.font = self.font
            leftEdgeLabel.isEditable = false
            if le.hasSetEnd {
                leftEdgeLabel.stringValue = "\(le.startPoint.clampDecimals(0)) -> \(le.endPoint.clampDecimals(0))"
            } else {
                leftEdgeLabel.stringValue = "\(le.startPoint.clampDecimals(0)) ^^ \(le.directionVector.clampDecimals(0))"
            }
            leftEdgeLabel.sizeToFit()
            leftEdgeLabel.frame.origin = NSPoint.zero
            v.addSubview(leftEdgeLabel)
            
            self.edgeLabels.append(leftEdgeLabel)
            self.edgeText.append(leftEdgeLabel.stringValue)
        }
        if let re = head.rightEdge {
            let rightEdgeLabel = NSTextField(frame: NSRect(size: frame.size))
            rightEdgeLabel.font = self.font
            rightEdgeLabel.isEditable = false
            if re.hasSetEnd {
                rightEdgeLabel.stringValue = "\(re.startPoint.clampDecimals(0)) -> \(re.endPoint.clampDecimals(0))"
            } else {
                rightEdgeLabel.stringValue = "\(re.startPoint.clampDecimals(0)) ^^ \(re.directionVector.clampDecimals(0))"
            }
            rightEdgeLabel.sizeToFit()
            rightEdgeLabel.frame.origin = v.frame.size.getCGPoint() - rightEdgeLabel.frame.size.getCGPoint()
            v.addSubview(rightEdgeLabel)
            
            self.edgeLabels.append(rightEdgeLabel)
            self.edgeText.append(rightEdgeLabel.stringValue)
        }
        
        self.generateViews(head: head.left, minX: minX, maxX: (minX + maxX) / 2.0, y: y + 64.0, color: color ^ 1)
        self.generateViews(head: head.right, minX: (minX + maxX) / 2.0, maxX: maxX, y: y + 64.0, color: color ^ 3)
    }
    
    @IBAction func toggleButtonPressed(_ sender: AnyObject) {
        self.displayStart.flip()
        for (i, field) in self.edgeLabels.enumerated() {
            if self.displayStart {
                field.stringValue = self.edgeText[i]
            } else {
                for j in (0..<self.edgeText[i].characterCount).reversed() {
                    if self.edgeText[i][j] == "(" {
                        field.stringValue = self.edgeText[i][j..<self.edgeText[i].characterCount]
                        break
                    }
                }
            }
        }
    }
    
}

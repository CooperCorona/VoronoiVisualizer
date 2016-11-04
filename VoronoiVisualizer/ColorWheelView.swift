//
//  ColorWheelView.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 11/1/16.
//  Copyright © 2016 Cooper Knaak. All rights reserved.
//

import Cocoa
import CoronaConvenience
import CoronaStructures
import CoronaGL

open class ColorWheelView: OmniGLView2d {
   
    private(set) var wheelBuffer = GLSFrameBuffer(size: CGSize(square: 1.0))
    private(set) var projection = SCMatrix4()
    let vertices = TexturedQuadVertices<UVertex>(vertex: UVertex())
    let program = ShaderHelper.programDictionaryForString("Color Wheel Shader")!
    let gradient = GLGradientTexture2D(gradient: ColorGradient1D.hueGradient)
    var brightness:CGFloat = 1.0
    var outlineColor = SCVector4.blackColor
    var wheelAlpha:CGFloat = 1.0
    
    
    override open var isOpaque: Bool { return false }
    
    public override init?(frame frameRect: NSRect, pixelFormat: NSOpenGLPixelFormat?) {
        super.init(frame: frameRect, pixelFormat: pixelFormat)
        self.setupBuffer()
        self.vertices.iterateWithHandler() { index, vertex in
            let p = TexturedQuad.pointForIndex(index)
            vertex.texture = (p * 2.0 - 1.0).getGLTuple()
        }
        self.clearColor = SCVector4()
        let opaque:[GLint] = [0]
        self.openGLContext?.setValues(opaque, for: NSOpenGLContextParameter.surfaceOpacity)
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupBuffer()
        self.vertices.iterateWithHandler() { index, vertex in
            let p = TexturedQuad.pointForIndex(index)
            vertex.texture = (p * 2.0 - 1.0).getGLTuple()
        }
        self.clearColor = SCVector4()
        let opaque:[GLint] = [0]
        self.openGLContext?.setValues(opaque, for: NSOpenGLContextParameter.surfaceOpacity)
    }
    
    open override func reshape() {
        super.reshape()
        self.setupBuffer()
    }
    
    private func setupBuffer() {
        glViewport(0, 0, GLsizei(self.frame.width), GLsizei(self.frame.height))
        GLSNode.universalProjection = SCMatrix4(right: self.frame.width, top: self.frame.height)
        
        let _ = self.container.removeChild(self.wheelBuffer.sprite)
        self.wheelBuffer = GLSFrameBuffer(size: self.frame.size)
        self.wheelBuffer.sprite.position = self.wheelBuffer.contentSize.center
        self.wheelBuffer.clearColor = SCVector4()
        self.container.addChild(self.wheelBuffer.sprite)
        TexturedQuad.setPosition(CGRect(size: self.frame.size), ofVertices: &self.vertices.vertices)
    }
    
    open override func draw(_ dirtyRect: NSRect) {
        GLSFrameBuffer.globalContext.view = self
        self.renderToBuffer()
        super.draw(dirtyRect)
    }
    
    open func renderToBuffer() {
        let _ = self.container.framebufferStack?.pushGLSFramebuffer(buffer: self.wheelBuffer)
        self.wheelBuffer.bindClearColor()
        
        self.program.use()
        self.vertices.bufferDataWithVertexBuffer(self.program.vertexBuffer)
        
        self.program.uniformMatrix4fv("u_Projection", matrix: GLSNode.universalProjection)
        self.program.uniform1f("u_Brightness", value: self.brightness)
        self.program.uniform1f("u_Alpha", value: self.wheelAlpha)
        glBindTexture(GLenum(GL_TEXTURE_2D), self.gradient.textureName)
        glUniform1i(self.program["u_Gradient"], 0)
        
        self.program.enableAttributes()
        self.program.bridgeAttributesWithSizes([2, 2], stride: self.vertices.stride)
        self.vertices.drawArrays()
        self.program.disableAttributes()
        
        let _ = self.container.framebufferStack?.popFramebuffer()
    }
    
}

@objc protocol ColorWheelViewDelegate {
    
    @objc optional func colorChanged(hue:CGFloat, saturation:CGFloat, brightness:CGFloat, alpha:CGFloat)
    @objc optional func colorChanged(red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat)
    
}

open class ColorWheelViewWrapper: NSView {
    
    override open var frame:NSRect {
        didSet {
            self.colorWheel.frame = NSRect(size: self.frame.size)
        }
    }
    
    private(set) lazy var colorWheel:ColorWheelView = {
        let attrs: [NSOpenGLPixelFormatAttribute] = [
            UInt32(NSOpenGLPFAAccelerated),            //  Use accelerated renderers
            UInt32(NSOpenGLPFAColorSize), UInt32(32),  //  Use 32-bit color
            UInt32(NSOpenGLPFAOpenGLProfile),          //  Use version's >= 3.2 core
            UInt32(NSOpenGLProfileVersion3_2Core),
            UInt32(0)                                  //  C API's expect to end with 0
        ]
        
        let wheel = ColorWheelView(frame: self.frame, pixelFormat: NSOpenGLPixelFormat(attributes: attrs))!
        self.addSubview(wheel)
        /*
        let constraints = [NSLayoutAttribute.leading, NSLayoutAttribute.trailing, NSLayoutAttribute.top, NSLayoutAttribute.bottom]
        for constraint in constraints {
            let const = NSLayoutConstraint(item: wheel, attribute: constraint, relatedBy: .equal, toItem: self, attribute: constraint, multiplier: 1.0, constant: 0.0)
            wheel.addConstraint(const)
        }
        */
        wheel.frame.size = CGSize(square: 128.0)
        
        return wheel
    }()
    private let knobImage = NSView(frame: NSRect(square: 8.0))
    var brightness:CGFloat {
        get { return self.colorWheel.brightness }
        set {
            self.colorWheel.brightness = newValue
            if let hsba = self.getCurrentColor() {
                self.delegate?.colorChanged?(hue: hsba[0], saturation: hsba[1], brightness: hsba[2], alpha: hsba[3])
                let rgb = self.convertToRGB(hue: hsba[0], saturation: hsba[1], brightness: hsba[2])
                self.delegate?.colorChanged?(red: rgb.x, green: rgb.y, blue: rgb.z, alpha: hsba[3])
            }
        }
    }
    var wheelAlpha:CGFloat {
        get { return self.colorWheel.wheelAlpha }
        set { self.colorWheel.wheelAlpha = newValue }
    }
    
    weak var delegate:ColorWheelViewDelegate? = nil
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        //Initialize the color wheel.
        let _ = self.colorWheel
        
        self.knobImage.wantsLayer = true
        self.knobImage.layer?.backgroundColor = NSColor.white.cgColor
        self.knobImage.layer?.cornerRadius = 4.0
        self.knobImage.layer?.borderColor = NSColor.black.cgColor
        self.knobImage.layer?.borderWidth = 1.0
        self.knobImage.frame.center = self.frame.size.center
        self.addSubview(self.knobImage)
    }
    
    open func set(red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat = 1.0) {
        let hsb = NSColor(red: red, green: green, blue: blue, alpha: alpha).getHSBComponents()
        self.colorWheel.brightness = hsb[2]
        self.colorWheel.wheelAlpha = alpha
        self.moveKnobFor(hue: hsb[0], saturation: hsb[1])
    }
    
    private func moveKnobFor(hue:CGFloat, saturation:CGFloat) {
        if saturation ~= 0.0 {
            self.knobImage.frame.center = self.frame.size.center
        } else {
            let angle = CGFloat(2.0 * M_PI) * hue
            let radius = (1.0 - saturation) * self.frame.width / 2.0
            self.knobImage.frame.center = self.frame.size.center + CGPoint(angle: angle, length: radius)
        }
    }
    
    open override func mouseDown(with event: NSEvent) {
        self.mouseEvent(event: event)
    }
    
    open override func mouseDragged(with event: NSEvent) {
        self.mouseEvent(event: event)
    }
    
    private func getCurrentColor() -> [CGFloat]? {
        return self.calculateColorAt(point: self.knobImage.frame.center)
    }
    
    private func calculateColorAt(point:NSPoint) -> [CGFloat]? {
        let center = self.frame.size.center
        let saturation = 1.0 - point.distanceFrom(center) / (self.frame.size.width / 2.0)
        guard saturation >= 0.0 else {
            return nil
        }
        let hue = AngleDelta.makePositive(angle: center.angleTo(point)) / CGFloat(2.0 * M_PI)
        return [hue, saturation, self.brightness, self.wheelAlpha]
    }
    
    private func convertToRGB(hue:CGFloat, saturation:CGFloat, brightness:CGFloat) -> SCVector3 {
        var rgb = ColorGradient1D.hueGradient[hue].xyz
        rgb = linearlyInterpolate(saturation, left: rgb, right: SCVector3.whiteColor)
        rgb *= brightness
        return rgb
    }
    
    private func mouseEvent(event:NSEvent) {
        let loc = event.locationInWindow - self.frame.origin
        /*
        let center = self.frame.size.center
        let saturation = 1.0 - loc.distanceFrom(center) / (self.frame.size.width / 2.0)
        guard saturation >= 0.0 else {
            return
        }
        let hue = AngleDelta.makePositive(angle: center.angleTo(loc)) / CGFloat(2.0 * M_PI)
        */
        guard let hsb = self.calculateColorAt(point: loc) else {
            return
        }
        let hue = hsb[0]
        let saturation = hsb[1]
        self.moveKnobFor(hue: hue, saturation: saturation)
        self.delegate?.colorChanged?(hue: hue, saturation: saturation, brightness: self.colorWheel.brightness, alpha: self.colorWheel.wheelAlpha)
        let rgb = self.convertToRGB(hue: hue, saturation: saturation, brightness: self.brightness)
        self.delegate?.colorChanged?(red: rgb.x, green: rgb.y, blue: rgb.z, alpha: self.colorWheel.wheelAlpha)
    }
    
    open override func display() {
        super.display()
        self.colorWheel.display()
    }
    
}

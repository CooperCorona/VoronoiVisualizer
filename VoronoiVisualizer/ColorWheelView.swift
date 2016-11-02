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
    
    open func set(red:CGFloat, green:CGFloat, blue:CGFloat, alpha:CGFloat = 1.0) {
        let hsb = NSColor(red: red, green: green, blue: blue, alpha: alpha).getHSBComponents()
        self.brightness = hsb[2]
        self.wheelAlpha = alpha
    }
    
}

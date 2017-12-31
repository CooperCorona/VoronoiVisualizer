//
//  VoronoiImageMask.swift
//  VoronoiVisualizer
//
//  Created by Cooper Knaak on 12/31/17.
//  Copyright © 2017 Cooper Knaak. All rights reserved.
//

import Cocoa
import CoronaGL

class VoronoiImageMask {
    
    // MARK: - Types
    
    enum ImageMask {
        case none
        case image(CCTexture)
        case mask(CCTexture)
    }
    
    // MARK: - Properties
    
    var imageMask:ImageMask = .none {
        didSet {
            switch oldValue {
            case .none:
                break
            case let .image(oldTexture):
                var name = oldTexture.name
                glDeleteTextures(1, &name)
            case let .mask(oldTexture):
                var name = oldTexture.name
                glDeleteTextures(1, &name)
            }
            switch self.imageMask {
            case .none:
                self.sprite.texture = nil
            case let .image(newTexture):
                self.sprite.texture = newTexture
            case let .mask(newTexture):
                self.sprite.texture = newTexture
            }
        }
    }
    
    let sprite = GLSSprite(size: CGSize.zero, texture: nil)
    
    // MARK: - Setup
    
    init() {
        self.sprite.position = CGPoint.zero
        self.sprite.anchor = CGPoint.zero
    }
    
    func set(size:CGSize) {
        self.sprite.contentSize = size
    }
    
    // MARK: - Logic
    
}

//
//  Submesh.swift
//  MetalSTL
//
//  Created by Andrey Volodin on 14.03.17.
//  Copyright © 2017 s1ddok. All rights reserved.
//

import MetalKit

public class Submesh {
    
    let submesh: MTKSubmesh
    var uniforms: MTLBuffer!
    
    public init(submesh: MTKSubmesh, mdlSubmesh: MDLSubmesh, device: MTLDevice) {
        self.submesh = submesh
    }
    
    public func render(with encoder: MTLRenderCommandEncoder) {
        encoder.setVertexBuffer(uniforms, offset: 0, at: BufferIndex.materialUniformBuffer.rawValue)
        encoder.setFragmentBuffer(uniforms, offset: 0, at: BufferIndex.materialUniformBuffer.rawValue)
        
        encoder.drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
    }
}

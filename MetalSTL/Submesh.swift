//
//  Submesh.swift
//  MetalSTL
//
//  Created by Andrey Volodin on 14.03.17.
//  Copyright © 2017 s1ddok. All rights reserved.
//

import MetalKit
import SwiftMath

public class Submesh {
    
    let submesh: MTKSubmesh
    let uniforms: MTLBuffer
    var diffuseTexture: MTLTexture?
    
    public init(submesh: MTKSubmesh, mdlSubmesh: MDLSubmesh, device: MTLDevice) {
        self.submesh = submesh
        
        var materialUniforms = MaterialUniforms(emissiveColor: .zero, diffuseColor: .zero, specularColor: .zero, specularIntensity: 0, pad1: 0, pad2: 0, pad3: 0)
        
        // Iterate through the Material's properties...
        if let bcmProperty = mdlSubmesh.material?.propertyNamed("baseColorMap") {
            let textureURL = URL(string: "file://" + bcmProperty.stringValue!)
            let textureLoader = MTKTextureLoader(device: device)
            
            diffuseTexture = try? textureLoader.newTexture(withContentsOf: textureURL!, options: nil)
        }
        
        if let emissionProperty = mdlSubmesh.material?.propertyNamed("emission") {
            if emissionProperty.type == .float4 {
                materialUniforms.emissiveColor = unsafeBitCast(emissionProperty.float4Value, to: Vector4f.self)
            } else if emissionProperty.type == .float3 {
                materialUniforms.emissiveColor = Vector4f(unsafeBitCast(emissionProperty.float3Value, to: Vector3f.self))
            }
        }
        
        if let specularProperty = mdlSubmesh.material?.propertyNamed("specularColor") {
            if specularProperty.type == .float4 {
                materialUniforms.specularColor = unsafeBitCast(specularProperty.float4Value, to: Vector4f.self)
            } else if specularProperty.type == .float3 {
                materialUniforms.specularColor = Vector4f(unsafeBitCast(specularProperty.float3Value, to: Vector3f.self))
            }
        }
        
        self.uniforms = device.makeBuffer(bytes: &materialUniforms, length: MemoryLayout<MaterialUniforms>.size, options: [])
        
    }
    
    public func render(with encoder: MTLRenderCommandEncoder) {
        if let diffuseTexture = diffuseTexture {
            encoder.setFragmentTexture(diffuseTexture, at: TextureIndex.diffuseTextureIndex.rawValue)
        }
        
        encoder.setVertexBuffer(uniforms, offset: 0, at: BufferIndex.materialUniformBuffer.rawValue)
        encoder.setFragmentBuffer(uniforms, offset: 0, at: BufferIndex.materialUniformBuffer.rawValue)
        
        encoder.drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
    }
}

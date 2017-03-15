//
//  Constants.swift
//  MetalSTL
//
//  Created by Andrey Volodin on 15.03.17.
//  Copyright © 2017 s1ddok. All rights reserved.
//

import simd

/// Indices of vertex attribute in descriptor.
enum VertexAttributes: Int {
    case osition = 0, normal, texcoord
}

/// Indices for texture bind points.
enum TextureIndex: Int {
    case diffuseTextureIndex = 0
}

/// Indices for buffer bind points.
enum BufferIndex: Int {
    case vertexBuffer = 0, frameUniformBuffer, materialUniformBuffer
}

/// Per frame uniforms.
struct FrameUniforms {
    var model: float4x4
    var view: float4x4
    var projection: float4x4
    var projectionView: float4x4
    var normal: float4x4
}

/// Material uniforms.
struct AAPLMaterialUniforms {
    var emissiveColor, diffuseColor, specularColot: float4
    
    var specularIntensity, pad1, pad2, pad3: Float
};

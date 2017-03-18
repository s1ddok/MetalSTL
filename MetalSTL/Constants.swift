//
//  Constants.swift
//  MetalSTL
//
//  Created by Andrey Volodin on 15.03.17.
//  Copyright © 2017 s1ddok. All rights reserved.
//

import SwiftMath

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
    var model: Matrix4x4f
    var view: Matrix4x4f
    var projection: Matrix4x4f
    var projectionView: Matrix4x4f
    var normal: Matrix4x4f
}

/// Material uniforms.
struct MaterialUniforms {
    var emissiveColor, diffuseColor, specularColot: Vector4f
    
    var specularIntensity, pad1, pad2, pad3: Float
};

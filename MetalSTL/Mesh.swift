//
//  Mesh.swift
//  MetalSTL
//
//  Created by Andrey Volodin on 14.03.17.
//  Copyright © 2017 s1ddok. All rights reserved.
//

import MetalKit

public class Mesh {
    internal var mesh: MTKMesh
    public var submeshes: [Submesh] = []
    
    public init(mesh: MTKMesh, mdlMesh: MDLMesh, device: MTLDevice) {
        self.mesh = mesh
        
        guard mesh.submeshes.count == mdlMesh.submeshes!.count else {
            fatalError("Error: submeshes count are not equal")
        }
        
        for i in 0..<mesh.submeshes.count {
            submeshes.append(Submesh(submesh: mesh.submeshes[i], mdlSubmesh: mdlMesh.submeshes![i] as! MDLSubmesh, device: device))
        }
    }
    
    public func render(with encoder: MTLRenderCommandEncoder) {
        var bufferIndex = 0
        
        for vb in mesh.vertexBuffers {
            encoder.setVertexBuffer(vb.buffer, offset: vb.offset, at: bufferIndex)
            bufferIndex += 1
        }
        
        for s in submeshes {
            s.render(with: encoder)
        }
    }
}

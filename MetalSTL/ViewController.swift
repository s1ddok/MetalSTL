//
//  ViewController.swift
//  MetalSTL
//
//  Created by Andrey Volodin on 14.03.17.
//  Copyright © 2017 s1ddok. All rights reserved.
//

import UIKit
import MetalKit
import SwiftMath

class ViewController: UIViewController {
    @IBOutlet var metalView: MTKView!

    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var shaderLibrary: MTLLibrary!
    var pipelineState: MTLRenderPipelineState!
    var depthState: MTLDepthStencilState!
    
    var viewMatrix: Matrix4x4f = .identity
    var projectionMatrix: Matrix4x4f = .identity
    
    var rotation: Angle = .zero
    var meshes: [Mesh] = []
    
    var frameUniformsBuffer: MTLBuffer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMetal()
    }
    
    private func setupMetal() {
        device = MTLCreateSystemDefaultDevice()
        
        guard device != nil else {
            fatalError("Metal is not supported on this device")
        }
        
        commandQueue  = device.makeCommandQueue()
        shaderLibrary = device.newDefaultLibrary()
        
        metalView.device   = device
        metalView.delegate = self
        metalView.sampleCount = 4
        metalView.preferredFramesPerSecond = 60
        metalView.depthStencilPixelFormat = .depth32Float_stencil8
    }

}

// ViewController will be the renderer as well
extension ViewController: MTKViewDelegate {
    public func update() {
        let modelMatrix = Matrix4x4f.translate(tx: 0, ty: 0, tz: 2) * Matrix4x4f.rotate(x: rotation)
        let modelViewMatrix = viewMatrix * modelMatrix
        var frameData   = FrameUniforms(model: modelMatrix, view: viewMatrix, projection: .identity, projectionView: projectionMatrix * modelViewMatrix, normal: modelViewMatrix.transposed.inversed)
    
        frameUniformsBuffer = device.makeBuffer(bytes: &frameData, length: MemoryLayout<FrameUniforms>.size, options: .optionCPUCacheModeWriteCombined)
        rotation += 1°
    }
    
    public func render() {
        // Perofm any app logic, including updating any Metal buffers.
        update()
        
        // Create a new command buffer for each renderpass to the current drawable.
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        // Obtain a renderPassDescriptor generated from the view's drawable textures.
        guard let renderPassDescriptor = metalView.currentRenderPassDescriptor else {
            fatalError("Error while trying to obtain current render pass descriptor from MTKView")
        }
        
        // Create a render command encoder so we can render into something.
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        // Set context state.
        renderEncoder.setViewport(MTLViewport(originX: 0, originY: 0, width: Double(metalView.drawableSize.width), height: Double(metalView.drawableSize.height), znear: 0, zfar: 1))
        renderEncoder.setDepthStencilState(depthState)
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // Set the our per frame uniforms.
        renderEncoder.setVertexBuffer(frameUniformsBuffer, offset: 0, at: BufferIndex.frameUniformBuffer.rawValue)
        
        // Render each of our meshes.
        for mesh in meshes {
            mesh.render(with: renderEncoder)
        }
        
        // We're done encoding commands.
        renderEncoder.endEncoding()
        
        // Schedule a present once the framebuffer is complete using the current drawable.
        commandBuffer.present(metalView.currentDrawable!)
        
        // Finalize rendering here & push the command buffer to the GPU.
        commandBuffer.commit()
        
        // Very bad, better use semaphore to dispatch inflight frames
        // But for now we will leave that as is.
        commandBuffer.waitUntilCompleted()
    }
    
    /*
     When reshape is called, update the view and projection matricies since
     this means the view orientation or size changed.
     */
    public func reshape() {
        let aspect = Float(fabs(self.view.bounds.size.width / self.view.bounds.size.height))
        projectionMatrix = Matrix4x4f.from(perspectiveFOV: 65°, aspectLH: aspect, nearZ: 0.1, farZ: 100)
        
        viewMatrix = .identity
    }
    
    func draw(in view: MTKView) {
        autoreleasepool {
            self.render()
        }
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.reshape()
    }
}

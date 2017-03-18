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
    var mtlVertexDescriptor: MTLVertexDescriptor!
    
    var viewMatrix: Matrix4x4f = .identity
    var projectionMatrix: Matrix4x4f = .identity
    
    var rotationX: Angle = .zero
    var rotationY: Angle = .zero
    var meshes: [Mesh] = []
    
    var frameUniformsBuffer: MTLBuffer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMetal()
        loadAssets()
        reshape()
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
        
        // Load the fragment program into the library.
        let fragmentProgram = shaderLibrary.makeFunction(name: "fragmentLight")
        
        // Load the vertex program into the library.
        let vertexProgram = shaderLibrary.makeFunction(name:"vertexLight")
        
        /*
         Create a vertex descriptor for our Metal pipeline. Specifies the layout
         of vertices the pipeline should expect.
         */
        mtlVertexDescriptor = MTLVertexDescriptor()
        
        // Positions.
        mtlVertexDescriptor.attributes[VertexAttributes.position.rawValue].format = .float3
        mtlVertexDescriptor.attributes[VertexAttributes.position.rawValue].offset = 0
        mtlVertexDescriptor.attributes[VertexAttributes.position.rawValue].bufferIndex = BufferIndex.vertexBuffer.rawValue
        
        // Normals.
        mtlVertexDescriptor.attributes[VertexAttributes.normal.rawValue].format = .float3
        mtlVertexDescriptor.attributes[VertexAttributes.normal.rawValue].offset = 12
        mtlVertexDescriptor.attributes[VertexAttributes.normal.rawValue].bufferIndex = BufferIndex.vertexBuffer.rawValue
        
        // Texture coordinates.
        mtlVertexDescriptor.attributes[VertexAttributes.texcoord.rawValue].format = .half2
        mtlVertexDescriptor.attributes[VertexAttributes.texcoord.rawValue].offset = 24
        mtlVertexDescriptor.attributes[VertexAttributes.texcoord.rawValue].bufferIndex = BufferIndex.vertexBuffer.rawValue
        
        // Single interleaved buffer.
        mtlVertexDescriptor.layouts[BufferIndex.vertexBuffer.rawValue].stride = 28
        mtlVertexDescriptor.layouts[BufferIndex.vertexBuffer.rawValue].stepRate = 1
        mtlVertexDescriptor.layouts[BufferIndex.vertexBuffer.rawValue].stepFunction = .perVertex
        
        // Create a reusable pipeline state
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.sampleCount = metalView.sampleCount
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.vertexDescriptor = mtlVertexDescriptor
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        pipelineStateDescriptor.depthAttachmentPixelFormat = metalView.depthStencilPixelFormat
        pipelineStateDescriptor.stencilAttachmentPixelFormat = metalView.depthStencilPixelFormat
        
        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        
        if pipelineState == nil {
            fatalError("Failed to create pipeline state")
        }
        
        let depthStateDesc = MTLDepthStencilDescriptor()
        depthStateDesc.depthCompareFunction = .less
        depthStateDesc.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: depthStateDesc)
    }
    
    private func loadAssets() {
        /*
         From our Metal vertex descriptor, create a Model I/O vertex descriptor we'll
         load our asset with. This specifies the layout of vertices Model I/O should
         format loaded meshes with.
         */
        let mdlVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(mtlVertexDescriptor)
        (mdlVertexDescriptor.attributes[VertexAttributes.position.rawValue] as! MDLVertexAttribute).name = MDLVertexAttributePosition
        (mdlVertexDescriptor.attributes[VertexAttributes.normal.rawValue] as! MDLVertexAttribute).name = MDLVertexAttributeNormal
        (mdlVertexDescriptor.attributes[VertexAttributes.texcoord.rawValue] as! MDLVertexAttribute).name = MDLVertexAttributeTextureCoordinate
        
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        
        guard let assetURL = Bundle.main.url(forResource: "realship", withExtension: "obj") else {
            fatalError("Error: Can't find asset to load.")
        }
        
        /*
         Load Model I/O Asset with mdlVertexDescriptor, specifying vertex layout and
         bufferAllocator enabling ModelIO to load vertex and index buffers directory
         into Metal GPU memory.
         */
        let asset = MDLAsset(url: assetURL, vertexDescriptor: mdlVertexDescriptor, bufferAllocator: bufferAllocator)
    
        var mdlMeshes: NSArray? = NSArray()
        let mtkMeshes = try! MTKMesh.newMeshes(from: asset, device: device, sourceMeshes: &mdlMeshes)
        
        for i in 0..<mtkMeshes.count {
            meshes.append(Mesh(mesh: mtkMeshes[i], mdlMesh: mdlMeshes!.object(at: i) as! MDLMesh, device: device))
        }
    }

}

// ViewController will be the renderer as well
extension ViewController: MTKViewDelegate {
    public func update() {
        let modelMatrix = Matrix4x4f.translate(tx: 0, ty: 0, tz: 2) * Matrix4x4f.rotate(x: rotationX, y: rotationY)
        let modelViewMatrix = viewMatrix * modelMatrix
        var frameData   = FrameUniforms(model: modelMatrix, view: viewMatrix, projection: .identity, projectionView: projectionMatrix * modelViewMatrix, normal: modelViewMatrix.transposed.inversed)
    
        frameUniformsBuffer = device.makeBuffer(bytes: &frameData, length: MemoryLayout<FrameUniforms>.size, options: .optionCPUCacheModeWriteCombined)
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

extension ViewController {
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let previousLocation = touch.previousLocation(in: metalView)
        let currentLocation = touch.location(in: metalView)
        
        let dx = Float(currentLocation.x - previousLocation.x)
        let dy = Float(currentLocation.y - previousLocation.y)
        
        // reversed for landscape orientation
        // don't kill me for that
        rotationX += 0.5° * dy
        rotationY += 0.5° * dx
    }
}

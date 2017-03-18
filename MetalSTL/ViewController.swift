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
    
    var viewMatrix: Matrix4x4f = .identity
    var projectionMatrix: Matrix4x4f = .identity
    
    var rotation: Angle = .zero
    
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
    
        rotation += 1°
    }
    
    public func render() {
        
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

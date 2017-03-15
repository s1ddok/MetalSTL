//
//  ViewController.swift
//  MetalSTL
//
//  Created by Andrey Volodin on 14.03.17.
//  Copyright © 2017 s1ddok. All rights reserved.
//

import UIKit
import MetalKit

class ViewController: UIViewController {
    @IBOutlet var metalView: MTKView!

    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var shaderLibrary: MTLLibrary!
    
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
    }

}

// ViewController will be the renderer as well
extension ViewController: MTKViewDelegate {
    func draw(in view: MTKView) {
        
        
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
        
    }
}

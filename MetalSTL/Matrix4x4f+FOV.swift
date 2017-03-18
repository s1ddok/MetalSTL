//
//  Matrix4x4f+FOV.swift
//  MetalSTL
//
//  Created by Andrey Volodin on 15.03.17.
//  Copyright © 2017 s1ddok. All rights reserved.
//

import SwiftMath

public extension Matrix4x4f {
    public static func from(perspectiveFOV fovY: Angle, aspectLH aspect: Float, nearZ: Float, farZ: Float) -> Matrix4x4f {
        // 1 / tan == cot
        let yscale = 1.0 / tan(fovY * 0.5)
        let xscale = yscale / aspect
        let q = farZ / (farZ - nearZ)
        
        return Matrix4x4f(vec4(xscale, 0.0, 0.0, 0.0),
                          vec4(0.0, yscale, 0.0, 0.0),
                          vec4(0.0, 0.0, q, 1.0),
                          vec4(0.0, 0.0, q * -nearZ, 0.0))

    }
}

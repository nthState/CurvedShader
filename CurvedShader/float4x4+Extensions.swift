//
//  float4x4+Extensions.swift
//  CurvedShader
//
//  Created by Chris Davis on 24/04/2021.
//

import Foundation
import SceneKit

extension float4x4 {
    init(matrix: GLKMatrix4) {
        self.init(columns: (SIMD4<Float>(x: matrix.m00, y: matrix.m01, z: matrix.m02, w: matrix.m03),
                            SIMD4<Float>(x: matrix.m10, y: matrix.m11, z: matrix.m12, w: matrix.m13),
                            SIMD4<Float>(x: matrix.m20, y: matrix.m21, z: matrix.m22, w: matrix.m23),
                            SIMD4<Float>(x: matrix.m30, y: matrix.m31, z: matrix.m32, w: matrix.m33)))
    }
}

extension float4x4 {
    func position() -> simd_float3 {
        return simd_float3(columns.3.x, columns.3.y, columns.3.z)
    }
}

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
        self.init(columns: (float4(x: matrix.m00, y: matrix.m01, z: matrix.m02, w: matrix.m03),
                            float4(x: matrix.m10, y: matrix.m11, z: matrix.m12, w: matrix.m13),
                            float4(x: matrix.m20, y: matrix.m21, z: matrix.m22, w: matrix.m23),
                            float4(x: matrix.m30, y: matrix.m31, z: matrix.m32, w: matrix.m33)))
    }
}

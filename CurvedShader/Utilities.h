//
//  Utilities.h
//  CurvedShader
//
//  Created by Chris Davis on 26/04/2021.
//

@import simd;

/// Builds a symmetric perspective projection matrix with the supplied aspect ratio,
/// vertical field of view (in radians), and near and far distances
matrix_float4x4 matrix_float4x4_perspective(float aspect, float fovy, float near, float far);

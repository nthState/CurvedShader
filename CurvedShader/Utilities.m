//
//  Utilities.m
//  CurvedShader
//
//  Created by Chris Davis on 26/04/2021.
//

#import "Utilities.h"

matrix_float4x4 matrix_float4x4_perspective(float aspect, float fovy, float near, float far)
{
    float yScale = 1 / tan(fovy * 0.5);
    float xScale = yScale / aspect;
    float zRange = far - near;
    float zScale = -(far + near) / zRange;
    float wzScale = -2 * far * near / zRange;

    vector_float4 P = { xScale, 0, 0, 0 };
    vector_float4 Q = { 0, yScale, 0, 0 };
    vector_float4 R = { 0, 0, zScale, -1 };
    vector_float4 S = { 0, 0, wzScale, 0 };

    matrix_float4x4 mat = { P, Q, R, S };
    return mat;
}

//
//  ShaderTypes.h
//  CurvedShader
//
//  Created by Chris Davis on 24/04/2021.
//

#ifndef Shared_h
#define Shared_h

#include <simd/simd.h>

typedef struct {
    matrix_float4x4 modelMatrix;
    matrix_float4x4 worldMatrix;
    matrix_float4x4 cameraMatrix;
    matrix_float4x4 projectionMatrix;
} Uniforms;

#endif /* Shared_h */

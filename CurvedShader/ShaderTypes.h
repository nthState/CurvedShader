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
  matrix_float4x4 modelViewTransform;
  matrix_float4x4 camera;
  matrix_float4x4 worldInverse;
  matrix_float4x4 modelViewProjectionTransform;
} Uniforms;

#endif /* Shared_h */

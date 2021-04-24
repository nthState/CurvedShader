//
//  CurvedShader.metal
//  CurvedShader
//
//  Created by Chris Davis on 24/04/2021.
//

#include <metal_stdlib>
using namespace metal;
#import "ShaderTypes.h"

typedef struct {
  packed_float3 position;
  packed_float4 texCoord;
} VertexIn;

typedef struct {
  float4 position [[position]];
  float4 texCoord;
} ColorInOut;

vertex ColorInOut vertexShader(const device VertexIn* vertex_array [[ buffer(0) ]],
                               constant Uniforms & uniforms [[ buffer(1) ]],
                               unsigned int vid [[ vertex_id ]]) {
  
  VertexIn VertexIn = vertex_array[vid];
  
  float4x4 mv_Matrix = uniforms.modelMatrix;
  float4x4 proj_Matrix = uniforms.projectionMatrix;
  
  ColorInOut out;
  //out.position = float4(VertexIn.position, 1);
  out.position = proj_Matrix * mv_Matrix * float4(VertexIn.position,1);
  out.texCoord = VertexIn.texCoord;
  return out;
}

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(1) ]]) {
  
  matrix_float4x4 v = uniforms.cameraMatrix;
  
  //return float4(1.0, 0.0, 0.0, 1.0);
  return in.texCoord;
}

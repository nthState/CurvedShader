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
} VertexCubeIn;

typedef struct {
  float4 position [[position]];
  float4 texCoord;
} ColorInOut;

vertex ColorInOut vertexShader(const device VertexCubeIn* vertex_array [[ buffer(0) ]],
                               constant Uniforms & uniforms [[ buffer(1) ]],
                               constant float & curvature [[ buffer(2) ]],
                               unsigned int vid [[ vertex_id ]]) {
  
  VertexCubeIn vert = vertex_array[vid];
  

  
  float4 pos = float4(vert.position, 1);
  float4 vv = uniforms.modelViewTransform * pos;
  vv.xyz += uniforms.camera.columns[3].xyz;
  vv = float4( 0.0f, (vv.z * vv.z) * - curvature, 0.0f, 0.0f );
  pos -= uniforms.worldInverse * vv;

  float4 finalPos = uniforms.modelViewProjectionTransform * pos;
  
  ColorInOut out;
  out.position = finalPos;
  out.texCoord = vert.texCoord;
  return out;
}

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(1) ]],
                               texture2d<float> tex) {
  //return in.texCoord;
  return float4(0,1,0,1);
}


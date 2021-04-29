//
//  CurvedShaderModel.metal
//  CurvedShader
//
//  Created by Chris Davis on 29/04/2021.
//

#include <metal_stdlib>
using namespace metal;
#import "ShaderTypes.h"

struct VertexIn {
//    float3 position  [[attribute(0)]];
//    float3 normal    [[attribute(1)]];
//    float2 texCoords [[attribute(2)]];
  packed_float3 position ;
  packed_float3 normal;
  packed_float2 texCoords;
};
 
struct VertexOut {
    float4 position [[position]];
    float4 eyeNormal;
    float4 eyePosition;
    float2 texCoords;
};

vertex VertexOut vertexShaderModel(const device VertexIn* vertex_array [[ buffer(0) ]],
                               constant Uniforms & uniforms [[ buffer(1) ]],
                               constant float & curvature [[ buffer(2) ]],
                               unsigned int vid [[ vertex_id ]]) {
  
  VertexIn vert = vertex_array[vid];
  

  
  float4 pos = float4(vert.position, 1);
//  float4 vv = uniforms.modelViewTransform * pos;
//  vv.xyz += uniforms.camera.columns[3].xyz;
//  vv = float4( 0.0f, (vv.z * vv.z) * - curvature, 0.0f, 0.0f );
//  pos -= uniforms.worldInverse * vv;

  float4 finalPos = uniforms.modelViewProjectionTransform * pos;
  
  VertexOut out;
  out.position = finalPos;
  out.texCoords = vert.texCoords;
//  out.eyeNormal = float4(1);
//  out.eyePosition = float4(1);
  return out;
}

fragment float4 fragmentShaderModel(VertexOut in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(1) ]],
                               texture2d<float> tex) {
  //return in.texCoord;
  return float4(0,0,1,1);
}



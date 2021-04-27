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

//void main()
//{
//  vec4 worldPos = modelMatrix * vec4( positions, 1 );
//  vec4 viewPos = viewMatrix * worldPos;
//  vec4 finalPos = projectionMatrix * vec4(ApplyCylinderTransform(viewPos.xyz, 20.0, 5.0).xyz, 1.0);
//
//  gl_Position = finalPos;
//
//  vWorldPos = worldPos.xyz;
//  vWorldNormal = CalcInverseTranspose(mat3(modelMatrix)) * normals;
//  vWorldView = worldPos.xyz - cameraMatrix[3].xyz;
//  vTexCoord = texCoords;
//}

//float3 ApplyCylinderTransform(float3 v, float cylinderRadius, float cylinderDist)
//{
//  //return v;
//  float angle = v.z / cylinderRadius;  // the two (2 * PI * r) cancel out
//  return float3(v.x,
//        -cylinderRadius + cos(angle) * (cylinderRadius + v.y),
//        -cylinderDist + sin(angle) * (cylinderRadius + v.y));
//}
//
//matrix_float3x3 CalcInverseTranspose(matrix_float3x3 mat)
//{
//  float3 lengths = float3( length(mat[0]), length(mat[1]), length(mat[2]) );
//  lengths = 1.0 / (lengths * lengths);
//  return matrix_float3x3(mat[0]*lengths.x, mat[1]*lengths.y, mat[2]*lengths.z);
//}

vertex ColorInOut vertexShader(const device VertexIn* vertex_array [[ buffer(0) ]],
                               constant Uniforms & uniforms [[ buffer(1) ]],
                               constant float & curvature [[ buffer(2) ]],
                               unsigned int vid [[ vertex_id ]]) {
  
  VertexIn VertexIn = vertex_array[vid];
  

  
  float4 pos = float4(VertexIn.position, 1);
  float4 vv = uniforms.modelViewTransform * pos;
  vv.xyz += uniforms.camera.columns[3].xyz;
  vv = float4( 0.0f, (vv.z * vv.z) * - curvature, 0.0f, 0.0f );
  pos -= uniforms.worldInverse * vv;

  float4 finalPos = uniforms.modelViewProjectionTransform * pos;
  
  ColorInOut out;
  out.position = finalPos;
  out.texCoord = VertexIn.texCoord;
  return out;
}

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(1) ]]) {
  return in.texCoord;
}


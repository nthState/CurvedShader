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

//vertex ColorInOut vertexShader(const device VertexIn* vertex_array [[ buffer(0) ]],
//                               constant Uniforms & uniforms [[ buffer(1) ]],
//                               constant float & curvature [[ buffer(2) ]],
//                               unsigned int vid [[ vertex_id ]]) {
//
//  VertexIn VertexIn = vertex_array[vid];
//
//  float4x4 mv_Matrix = uniforms.modelMatrix;
//  float4x4 cam_Matrix = uniforms.cameraMatrix;
//  float4x4 wrld_Matrix = uniforms.worldMatrix;
//  float4x4 proj_Matrix = uniforms.projectionMatrix;
//
//  float4x4 modelTransform = wrld_Matrix * mv_Matrix; // model world transform
//  float4x4 modelViewTransform = cam_Matrix * modelTransform; // Model/view tranform
//  float4x4 modelViewProjectionTransform = proj_Matrix * modelViewTransform; // Mvp
//
//  ColorInOut out;
//  //out.position = float4(VertexIn.position, 1);
//  out.position = modelViewProjectionTransform * float4(VertexIn.position,1);
//  out.texCoord = VertexIn.texCoord;
//  return out;
//}

vertex ColorInOut vertexShader(const device VertexIn* vertex_array [[ buffer(0) ]],
                               constant Uniforms & uniforms [[ buffer(1) ]],
                               constant float & curvature [[ buffer(2) ]],
                               unsigned int vid [[ vertex_id ]]) {
  
  VertexIn VertexIn = vertex_array[vid];
  
  float4x4 mv_Matrix = uniforms.modelMatrix;
  float4x4 cam_Matrix = uniforms.cameraMatrix;
  float4x4 wrld_Matrix = uniforms.worldMatrix;
  float4x4 proj_Matrix = uniforms.projectionMatrix;
  float4x4 wrld_to_mdl_Matrix = uniforms.worldToModelMatrix;
  
  float4x4 modelTransform = wrld_Matrix * mv_Matrix; // model world transform
  float4x4 modelViewTransform = cam_Matrix * modelTransform; // Model/view tranform
  float4x4 modelViewProjectionTransform = proj_Matrix * modelViewTransform; // Mvp
  
  
  float4 pos = float4(VertexIn.position, 1);
  float4 vv =  pos;
  vv.xyz -= modelViewTransform.columns[3].xyz;
  vv = float4( 0.0f, (vv.z * vv.z) * - curvature, 0.0f, 0.0f );
  pos += vv;
  
  ColorInOut out;
  out.position = modelViewProjectionTransform * pos;
  out.texCoord = VertexIn.texCoord;
  return out;
}

//// This is where the curvature is applied
//        void vert( inout appdata_full v)
//        {
//            // Transform the vertex coordinates from model space into world space
//            float4 vv = mul( _Object2World, v.vertex );
//
//            // Now adjust the coordinates to be relative to the camera position
//            vv.xyz -= _WorldSpaceCameraPos.xyz;
//
//            // Reduce the y coordinate (i.e. lower the "height") of each vertex based
//            // on the square of the distance from the camera in the z axis, multiplied
//            // by the chosen curvature factor
//            vv = float4( 0.0f, (vv.z * vv.z) * - _Curvature, 0.0f, 0.0f );
//
//            // Now apply the offset back to the vertices in model space
//            v.vertex += mul(_World2Object, vv);
//        }

fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(1) ]]) {
  return in.texCoord;
}

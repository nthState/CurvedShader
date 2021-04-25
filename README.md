# Curved Shader Test

## What is it?

I'm attempting to re-create the same shader effect as Animal Crossing, I've made a simple-as-possible Metal based SwiftUI macOS App
to try it out.

I'm still trying to work out how to convert the Unity Shader code into Metal

![Screenshot 1l](https://github.com/nthState/CurvedShader/blob/main/Screenshots/ui.png?raw=true)

## Running the Demo

Download the code and run, use the `z Distance` slider to move the camera along the Z-Axis.

Current issues, the perspective definately seems off

## Shader Info

I'm trying to make this Shader in Metal, but there is a version written for Unity which I'm trying to convert, code snippet below:

```
void vert( inout appdata_full v)
{
    // Transform the vertex coordinates from model space into world space
    float4 vv = mul( _Object2World, v.vertex );

    // Now adjust the coordinates to be relative to the camera position
    vv.xyz -= _WorldSpaceCameraPos.xyz;

    // Reduce the y coordinate (i.e. lower the "height") of each vertex based
    // on the square of the distance from the camera in the z axis, multiplied
    // by the chosen curvature factor
    vv = float4( 0.0f, (vv.z * vv.z) * - _Curvature, 0.0f, 0.0f );

    // Now apply the offset back to the vertices in model space
    v.vertex += mul(_World2Object, vv);
}
```

Current Metal Shader

```metal
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
```


## Useful links

https://alastaira.wordpress.com/2013/10/25/animal-crossing-curved-world-shader/amp/


https://www.haroldserrano.com/blog/rendering-3d-objects-in-metal


https://whackylabs.com/metal/2020/04/30/multiple-objects-single-frame-metal/


https://www.raywenderlich.com/728-metal-tutorial-with-swift-3-part-2-moving-to-3d#toc-anchor-008


https://developer.apple.com/forums/thread/64057


https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html

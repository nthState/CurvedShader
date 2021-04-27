# Curved Shader Test

## What is it?

I'm attempting to re-create the same shader effect as Animal Crossing, I've made a simple-as-possible Metal based SwiftUI macOS App
to try it out.

## Screenshots

![Demo 1l](https://github.com/nthState/CurvedShader/blob/main/Screenshots/demo.gif?raw=true)

![Screenshot 1l](https://github.com/nthState/CurvedShader/blob/main/Screenshots/ui.png?raw=true)

## Running the Demo

Download the code and run, use the `z Distance` slider to move the camera along the Z-Axis.


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
```

## Issues

None


## Useful links

https://alastaira.wordpress.com/2013/10/25/animal-crossing-curved-world-shader/amp/


https://www.haroldserrano.com/blog/rendering-3d-objects-in-metal


https://whackylabs.com/metal/2020/04/30/multiple-objects-single-frame-metal/


https://www.raywenderlich.com/728-metal-tutorial-with-swift-3-part-2-moving-to-3d#toc-anchor-008


https://developer.apple.com/forums/thread/64057


https://docs.unity3d.com/Manual/SL-UnityShaderVariables.html

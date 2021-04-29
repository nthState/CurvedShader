//
//  TiltShift.metal
//  CurvedShader
//
//  Created by Chris Davis on 28/04/2021.
//

#include <metal_stdlib>
using namespace metal;
#import "ShaderTypes.h"



float gauss(float x, float e)
{
  return exp(-pow(x, 2.0) / e);
}

//https://www.shadertoy.com/view/4sdGDB
kernel void tiltShift(texture2d<float, access::read> inTexture [[texture(0)]],
                      texture2d<float, access::write> outTexture [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]]) {
  
  const int blur_size = 30;
  const float blur_width = 10.0;
  
  const float imageWidth = inTexture.get_width();
  const float imageHeight = inTexture.get_height();
  float2 iResolution = float2(imageWidth, imageHeight);
  
  float4 orig = inTexture.read(gid);
  //float2 uv = float2(gid.xy);
  
  float2 pos = float2(gid.xy) / iResolution.xy;
  //float4 pixval = float4(0.);
  float tot = 0.0;
  
  float4 pixval = inTexture.read(gid);
  
  const int nb = 2 * blur_size + 1;
  
  for (int x=0; x<nb; x++)
  {
    float x2 = blur_width * float(x - blur_size);
    float2 ipos = pos + float2(x2 / iResolution.x, 0.0);
    float g = gauss(x2, float(20 * blur_size) * 2.0 * pow(0.01 + abs(pos.y - 0.5), 2.3));
    pixval += g * inTexture.read(uint2(ipos));
    tot += g;
  }
  
  float4 final = pixval / tot;
  
  outTexture.write(orig, gid);
}


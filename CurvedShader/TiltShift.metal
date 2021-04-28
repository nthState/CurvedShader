//
//  TiltShift.metal
//  CurvedShader
//
//  Created by Chris Davis on 28/04/2021.
//

#include <metal_stdlib>
using namespace metal;
#import "ShaderTypes.h"

kernel void tiltShift(texture2d<float, access::read> inTexture [[texture(0)]],
                      texture2d<float, access::write> outTexture [[texture(1)]],
                                    uint2 gid [[thread_position_in_grid]]) {
  
  const float bluramount  = 0.01;
  const float center      = 1.1;
  const float stepSize    = 0.004;
  const float steps       = 2.0;

  const float minOffs     = (float(steps-1.0)) / -2.0;
  const float maxOffs     = (float(steps-1.0)) / +2.0;
  
  float amount;
  float4 blurred;
  
  uint2 uv = gid;
  
  //Work out how much to blur based on the mid point
  amount = pow((uv.y * center) * 2.0 - 1.0, 2.0) * bluramount;
  
  //This is the accumulation of color from the surrounding pixels in the texture
  blurred = float4(0.0, 0.0, 0.0, 1.0);
  
  //From minimum offset to maximum offset
  for (float offsX = minOffs; offsX <= maxOffs; ++offsX) {
    for (float offsY = minOffs; offsY <= maxOffs; ++offsY) {
      
      //copy the coord so we can mess with it
      float2 temp_tcoord = float2(uv.xy);
      
      //work out which uv we want to sample now
      temp_tcoord.x += offsX * amount * stepSize;
      temp_tcoord.y += offsY * amount * stepSize;
      
      //accumulate the sample
      //blurred += texture2D(colorSampler, temp_tcoord);
      blurred += inTexture.read(uint2(temp_tcoord));
      
    } //for y
  } //for x
  
  //because we are doing an average, we divide by the amount (x AND y, hence steps * steps)
  blurred /= float(steps * steps);
  
  //return the final blurred color
  //return blurred;
  //outTexture.write(inTexture.read(gid), gid);
  outTexture.write(blurred, gid);
}


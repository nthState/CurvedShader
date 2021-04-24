//
//  Cube.swift
//  CurvedShader
//
//  Created by Chris Davis on 24/04/2021.
//

import MetalKit
import SceneKit

class Cube {
  
  var vertexBuffer: MTLBuffer!
  
  let A = Vertex(x: -1.0, y:   1.0, z:   1.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0)
  let B = Vertex(x: -1.0, y:  -1.0, z:   1.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0)
  let C = Vertex(x:  1.0, y:  -1.0, z:   1.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0)
  let D = Vertex(x:  1.0, y:   1.0, z:   1.0, r:  0.1, g:  0.6, b:  0.4, a:  1.0)
  
  let Q = Vertex(x: -1.0, y:   1.0, z:  -1.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0)
  let R = Vertex(x:  1.0, y:   1.0, z:  -1.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0)
  let S = Vertex(x: -1.0, y:  -1.0, z:  -1.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0)
  let T = Vertex(x:  1.0, y:  -1.0, z:  -1.0, r:  0.1, g:  0.6, b:  0.4, a:  1.0)
  
  var verticesArray:Array<Vertex> = []
  
  var vertexCount = 8
  
  var position: SIMD3<Float> = .zero
  
  init(device: MTLDevice, position: SIMD3<Float>) {
    verticesArray = [
      A,B,C ,A,C,D,   //Front
      R,T,S ,Q,R,S,   //Back
      
      Q,S,B ,Q,B,A,   //Left
      D,C,T ,D,T,R,   //Right
      
      Q,A,D ,Q,D,R,   //Top
      B,S,T ,B,T,C    //Bot
    ]
    
    vertexCount = verticesArray.count
    
    var vertexData = Array<Float>()
    for vertex in verticesArray {
      vertexData += vertex.floatBuffer()
    }
    
    let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
    vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
    
    self.position = position
  }
  
  func getTransform() -> float4x4 {
    let world = SCNMatrix4MakeTranslation(CGFloat(position.x), CGFloat(position.y), CGFloat(position.z))
    let worldSimd = simd_float4x4(world)
    return worldSimd
  }
}

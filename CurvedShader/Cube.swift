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
  
 
  
  var verticesArray:Array<Vertex> = []
  
  var vertexCount = 8
  
  var position: SIMD3<Float> = .zero
  var color: SIMD3<Float> = .zero
  
  init(device: MTLDevice, size: SIMD3<Float> = .one, position: SIMD3<Float>, color: SIMD3<Float>) {
    
    let A = Vertex(x: -size.x, y:   size.y, z:   size.z)
    let B = Vertex(x: -size.x, y:  -size.y, z:   size.z)
    let C = Vertex(x:  size.x, y:  -size.y, z:   size.z)
    let D = Vertex(x:  size.x, y:   size.y, z:   size.z)
    
    let Q = Vertex(x: -size.x, y:   size.y, z:  -size.z)
    let R = Vertex(x:  size.x, y:   size.y, z:  -size.z)
    let S = Vertex(x: -size.x, y:  -size.y, z:  -size.z)
    let T = Vertex(x:  size.x, y:  -size.y, z:  -size.z)
    
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
      //vertexData += vertex.floatBuffer()
      vertexData += [vertex.x, vertex.y, vertex.z, color.x, color.y, color.z, 1.0]
    }
    
    let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
    vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
    
    self.position = position
    self.color = color
  }
  
  func getTransform() -> float4x4 {
    let world = SCNMatrix4MakeTranslation(CGFloat(position.x), CGFloat(position.y), CGFloat(position.z))
    let worldSimd = simd_float4x4(world)
    return worldSimd
  }
}

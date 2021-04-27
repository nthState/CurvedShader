//
//  RenderView.swift
//  CurvedShader
//
//  Created by Chris Davis on 24/04/2021.
//

import Foundation
import MetalKit
import SceneKit
import os.log

class RenderView: MTKView {
  
  private var renderPipelineState: MTLRenderPipelineState!
  
  private var commandQueue: MTLCommandQueue?
  
  var uiDelegate: Coordinator?
  
  let alignedUniformsSize = (MemoryLayout<Uniforms>.size + 0xFF) & -0x100
  
  var objects: [Cube] = []
  
  init() {
    super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
    
    configureMetal()
    
    for z in (0...20) {
      for x in (0...1) {
        
        let multiplier = 4
        
        let size = SIMD3<Float>(1,1,1)
        let position = SIMD3<Float>(-Float(x * multiplier), 0, -Float(z * multiplier))
        let color = SIMD3<Float>.random(in: 0...1)
        
        objects.append(Cube(device: self.device!, size: size, position: position, color: color))
        
      }
    }

  }
  
  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func deg2rad(_ number: Float) -> Float {
      return number * .pi / 180
  }
  
  func getUniformBuffer(modelTransform modelSimd: float4x4 = matrix_identity_float4x4, worldTransform worldSimd: float4x4 = matrix_identity_float4x4) -> MTLBuffer {
    
    let zCamera = -CGFloat(self.uiDelegate!.parent.zCamera)
    let zCameraAngle = self.uiDelegate!.parent.zCameraAngle
    let zCameraHeight = CGFloat(self.uiDelegate!.parent.zCameraHeight)
    
    //let camRot = float4x4(simd_quatf(angle: deg2rad(zCameraAngle), axis: SIMD3<Float>(1,0,0)))
    let cameraRotation = simd_float4x4(SCNMatrix4Rotate(SCNMatrix4Identity, CGFloat(deg2rad(zCameraAngle)), 1, 0, 0))
    let cameraTranslation = simd_float4x4(SCNMatrix4Translate(SCNMatrix4Identity, 0, zCameraHeight, zCamera))
    
    //let viewSimd = cameraTranslation * cameraRotation
    let viewSimd = cameraRotation * cameraTranslation
//    let viewSimd = lookAt(eye: float3(x: 0, y: Float(zCameraHeight), z: Float(zCamera)),
//                          center: float3(x: 0, y: 0, z: Float(zCamera + 4)),
//                          up: float3(x: 0, y: 0, z: 1))
    
    os_log("%{PUBLIC}@", log: OSLog.camera, type: .debug, "pos: \(viewSimd.position())")
    
    let fovRadians: Float = deg2rad(85)
    let aspect = Float(self.bounds.size.width / self.bounds.size.height)
    let nearZ: Float = 1
    let farZ: Float = 100
    let perspective = GLKMatrix4MakePerspective(fovRadians, aspect, nearZ, farZ)
    let perspectiveSimd = float4x4(matrix: perspective)
    
    // model to world, to camera, to projection
    let modelViewProjectionTransform = perspectiveSimd * viewSimd * worldSimd * modelSimd
    let modelViewTransform = worldSimd * modelSimd
    let worldInverse = modelViewTransform.inverse
    
    var uniform = Uniforms(modelViewTransform: modelViewTransform,
                           camera: cameraTranslation,
                           worldInverse: worldInverse,
                           modelViewProjectionTransform: modelViewProjectionTransform)
    
    let uniformBufferSize = alignedUniformsSize

    let buffer = self.device!.makeBuffer(bytes: &uniform, length: uniformBufferSize, options: [MTLResourceOptions.storageModeShared])!
    
    return buffer
  }
  
  func configureMetal() {
    
    let defaultLibrary = device!.makeDefaultLibrary()!
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "vertexShader")
    pipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "fragmentShader")
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    
    do {
      renderPipelineState = try device!.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch {
      fatalError("Unable to create preview Metal view pipeline state. (\(error))")
    }
    
    commandQueue = device!.makeCommandQueue()
  }
  
  override func draw(_ rect: CGRect) {

    guard let drawable = (self.layer as? CAMetalLayer)?.nextDrawable() else {
      return
    }
    
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
    renderPassDescriptor.colorAttachments[0].storeAction = .store

    // Set up command buffer and encoder
    guard let commandQueue = commandQueue else {
      print("Failed to create Metal command queue")
      return
    }
    
    guard let commandBuffer = commandQueue.makeCommandBuffer() else {
      print("Failed to create Metal command buffer")
      return
    }
    
    // Loop through all objects and issue a render command for each
    for (index, object) in objects.enumerated() {
      let loadAction: MTLLoadAction = index == 0 ? .clear : .load
      renderPassDescriptor.colorAttachments[0].loadAction = loadAction
      
      drawObject(object: object, commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor, loadAction: loadAction)
    }
    
    // Draw to the screen.
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
  
  func drawObject(object: Cube, commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, loadAction: MTLLoadAction) {
    
    guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
      print("Failed to create Metal command encoder")
      return
    }
    //values not rendered into the screen
    let uniformBuffer = getUniformBuffer(worldTransform: object.getTransform())
    
    commandEncoder.label = "Preview display"
    //commandEncoder.setCullMode(MTLCullMode.front)
    commandEncoder.setRenderPipelineState(renderPipelineState!)
    
    commandEncoder.setVertexBuffer(object.vertexBuffer, offset: 0, index: 0)
    
    commandEncoder.setVertexBuffer(uniformBuffer, offset:0, index: 1)
    commandEncoder.setFragmentBuffer(uniformBuffer, offset:0, index: 1)
    
    var curve: Float = self.uiDelegate!.parent.curve
    
    commandEncoder.setVertexBytes(&curve, length: MemoryLayout<Float>.stride, index: 2)
    

    commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: object.vertexCount, instanceCount: object.vertexCount / 3)
    commandEncoder.endEncoding()
  }
  
}

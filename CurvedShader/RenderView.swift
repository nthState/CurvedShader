//
//  RenderView.swift
//  CurvedShader
//
//  Created by Chris Davis on 24/04/2021.
//

import Foundation
import MetalKit
import SceneKit

class RenderView: MTKView {
  
  private var renderPipelineState: MTLRenderPipelineState!
  
  private var commandQueue: MTLCommandQueue?
  
  var uiDelegate: Coordinator?
  
  let alignedUniformsSize = (MemoryLayout<Uniforms>.size + 0xFF) & -0x100
  
  var objects: [Cube] = []
  
  init() {
    super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
    
    configureMetal()
    
    for y in (0...20).reversed() {
      for x in (0...5).reversed() {
        
        // Randomly decide to place a cube
        guard Bool.random() else {
          continue
        }
        
        let multiplier = 4
        
        let size = SIMD3<Float>(1,1,1)
        let position = SIMD3<Float>(-Float(x * multiplier),0,-Float(y * multiplier))
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
  
  func getUniformBuffer(world worldSimd: float4x4) -> MTLBuffer {
    
    let modelSimd = matrix_identity_float4x4
    
//    let world = SCNMatrix4MakeTranslation(0, 0, 0)
//    let worldSimd = simd_float4x4(world)
    
    let zCamera = CGFloat(self.uiDelegate!.parent.zCamera)
    let zCameraAngle = self.uiDelegate!.parent.zCameraAngle
    let zCameraHeight = CGFloat(self.uiDelegate!.parent.zCameraHeight)
    
    let cameraRotation = SCNMatrix4Rotate(SCNMatrix4Identity, CGFloat(deg2rad(zCameraAngle)), 1, 0, 0)
    let cameraTranslation = SCNMatrix4Translate(SCNMatrix4Identity, 0, zCameraHeight, zCamera)
    let camera = SCNMatrix4Mult(cameraTranslation, cameraRotation)
    let cameraSimd = simd_float4x4(camera)
    
    let fovRadians: Float = deg2rad(90)
    let aspect = Float(self.bounds.size.width / self.bounds.size.height)
    let nearZ: Float = 0.01
    let farZ: Float = 100
    let perspective = GLKMatrix4MakePerspective(fovRadians, aspect, nearZ, farZ)
    let perspectiveSimd = float4x4(matrix: perspective)
    
    var uniform = Uniforms(modelMatrix: modelSimd,
                           worldMatrix: worldSimd,
                           cameraMatrix: cameraSimd,
                           projectionMatrix: perspectiveSimd,
                           worldInverseMatrix: (worldSimd * modelSimd).inverse)
    
    let uniformBufferSize = alignedUniformsSize

    let buffer = self.device!.makeBuffer(bytes: &uniform, length: uniformBufferSize, options: [MTLResourceOptions.storageModeShared])!
    
    return buffer
  }
  
//  func getVertexDescriptor() -> MTLVertexDescriptor {
//    let mtlVertexDescriptor = MTLVertexDescriptor()
//
//    mtlVertexDescriptor.attributes[0].format = MTLVertexFormat.float3
//    mtlVertexDescriptor.attributes[0].offset = 0
//    mtlVertexDescriptor.attributes[0].bufferIndex = 0
//
//    mtlVertexDescriptor.attributes[1].format = MTLVertexFormat.float2
//    mtlVertexDescriptor.attributes[1].offset = 0
//    mtlVertexDescriptor.attributes[1].bufferIndex = 1
//
//    mtlVertexDescriptor.layouts[0].stride = 12
//    mtlVertexDescriptor.layouts[0].stepRate = 1
//    mtlVertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunction.perVertex
//
//    mtlVertexDescriptor.layouts[1].stride = 8
//    mtlVertexDescriptor.layouts[1].stepRate = 1
//    mtlVertexDescriptor.layouts[1].stepFunction = MTLVertexStepFunction.perVertex
//
//    return mtlVertexDescriptor
//  }
  
  func configureMetal() {
    
    let defaultLibrary = device!.makeDefaultLibrary()!
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = defaultLibrary.makeFunction(name: "vertexShader")
    pipelineDescriptor.fragmentFunction = defaultLibrary.makeFunction(name: "fragmentShader")
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    //pipelineDescriptor.vertexDescriptor = getVertexDescriptor()
    
    do {
      renderPipelineState = try device!.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch {
      fatalError("Unable to create preview Metal view pipeline state. (\(error))")
    }
    
    commandQueue = device!.makeCommandQueue()
  }
  
  override func draw(_ rect: CGRect) {
    
//    guard let drawable = currentDrawable else {
//      return
//    }
    
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
    
    let uniformBuffer = getUniformBuffer(world: object.getTransform())
    
    commandEncoder.label = "Preview display"
    commandEncoder.setCullMode(MTLCullMode.front)
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

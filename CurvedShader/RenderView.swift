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
  
  private var renderPipelineStateScreen: MTLRenderPipelineState!
  private var renderPipelineStateCurvedShader: MTLRenderPipelineState!
  private var renderPipelineStateCurvedShaderModel: MTLRenderPipelineState!
  private var renderPipelineStateTiltShift: MTLComputePipelineState!
  
  // Model
  private var vertexDescriptor: MTLVertexDescriptor!
  private var meshes: [MTKMesh] = []
  
  /// Threads per thread group
  let threadsPerThreadGroup = MTLSize(width: 1, height: 1, depth: 1)
  
  /// Size of image
  var mtlSize: MTLSize!
  
  private var commandQueue: MTLCommandQueue?
  
  var texturesBuilt: Bool = false
  var renderTarget: MTLTexture!
  var accumulationTarget: MTLTexture!
  
  var uiDelegate: Coordinator?
  
  let alignedUniformsSize = (MemoryLayout<Uniforms>.size + 0xFF) & -0x100
  
  var objects: [Cube] = []
  
  init() {
    super.init(frame: .zero, device: MTLCreateSystemDefaultDevice())
    
    self.framebufferOnly = false
    
    loadModel()
    
    configureMetal()
    
    
    
    for z in (0...20).reversed() {
      for x in (-3...3) {
        
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
    
    let cameraRotation = simd_float4x4(SCNMatrix4Rotate(SCNMatrix4Identity, CGFloat(deg2rad(zCameraAngle)), 1, 0, 0))
    let cameraTranslation = simd_float4x4(SCNMatrix4Translate(SCNMatrix4Identity, 0, zCameraHeight, zCamera))
    
    let viewSimd = cameraRotation * cameraTranslation
    
    //os_log("%{PUBLIC}@", log: OSLog.camera, type: .debug, "pos: \(viewSimd.position())")
    
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
      renderPipelineStateCurvedShader = try device!.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch {
      fatalError("Unable to create preview Metal view pipeline state renderPipelineStateCurvedShader. (\(error))")
    }
    
    let pipelineDescriptorScreen = MTLRenderPipelineDescriptor()
    pipelineDescriptorScreen.vertexFunction = defaultLibrary.makeFunction(name: "mapTexture")
    pipelineDescriptorScreen.fragmentFunction = defaultLibrary.makeFunction(name: "displayTexture")
    pipelineDescriptorScreen.colorAttachments[0].pixelFormat = .bgra8Unorm
    
    do {
      renderPipelineStateScreen = try device!.makeRenderPipelineState(descriptor: pipelineDescriptorScreen)
    } catch {
      fatalError("Unable to create preview Metal view pipeline state pipelineDescriptorScreen. (\(error))")
    }
    
    do {
      if let function = defaultLibrary.makeFunction(name: "tiltShift") {
        renderPipelineStateTiltShift = try self.device!.makeComputePipelineState(function: function)
      }
    } catch {
      fatalError("Unable to create preview Metal view pipeline state renderPipelineStateCurvedShader. (\(error))")
    }
    
    let pipelineDescriptorModel = MTLRenderPipelineDescriptor()
    pipelineDescriptorModel.vertexFunction = defaultLibrary.makeFunction(name: "vertexShaderModel")
    pipelineDescriptorModel.fragmentFunction = defaultLibrary.makeFunction(name: "fragmentShaderModel")
    pipelineDescriptorModel.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineDescriptorModel.vertexDescriptor = self.vertexDescriptor
    
    do {
      renderPipelineStateCurvedShaderModel = try device!.makeRenderPipelineState(descriptor: pipelineDescriptorModel)
    } catch {
      fatalError("Unable to create preview Metal view pipeline state renderPipelineStateCurvedShaderModel. (\(error))")
    }
    
    commandQueue = device!.makeCommandQueue()
  }
  
  func loadModel() {
    let modelUrl = Bundle.main.url(forResource: "teapot", withExtension: "obj")
    let vertexDescriptor = MDLVertexDescriptor()
    vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
    vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.size * 3, bufferIndex: 0)
    vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: MemoryLayout<Float>.size * 6, bufferIndex: 0)
    vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
    self.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)

    let bufferAllocator = MTKMeshBufferAllocator(device: self.device!)
    let asset = MDLAsset(url: modelUrl, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
    (_, meshes) = try! MTKMesh.newMeshes(asset: asset, device: self.device!)
  }
  
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    buildTextures(size: size)
  }
  
  func buildTextures(size: CGSize) {
    
    mtlSize = MTLSize(width: Int(size.width), height: Int(size.height), depth: 1)
    
    let renderTargetDescriptor = MTLTextureDescriptor()
    renderTargetDescriptor.pixelFormat = .bgra8Unorm
    //renderTargetDescriptor.textureType = .type2D
    renderTargetDescriptor.width = Int(size.width)
    renderTargetDescriptor.height = Int(size.height)
    //renderTargetDescriptor.storageMode = .private
    renderTargetDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
    renderTarget = device!.makeTexture(descriptor: renderTargetDescriptor)
    accumulationTarget = device!.makeTexture(descriptor: renderTargetDescriptor)
  }
  
  override func draw(_ rect: CGRect) {
    
    if texturesBuilt == false {
      buildTextures(size: self.bounds.size)
      texturesBuilt = true
    }

    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = accumulationTarget
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
//    for (index, object) in objects.enumerated() {
//      let loadAction: MTLLoadAction = index == 0 ? .clear : .load
//      renderPassDescriptor.colorAttachments[0].loadAction = loadAction
//
//      drawObject(object: object, commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor)
//    }
    
    drawModel(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor)
    
    applyTiltShift(commandBuffer: commandBuffer, renderPassDescriptor: renderPassDescriptor, loadAction: .load)

    drawToScreen(commandBuffer: commandBuffer)
  }
  
  func drawToScreen(commandBuffer: MTLCommandBuffer) {
    guard let currentRenderPassDescriptor = self.currentRenderPassDescriptor,
          let currentDrawable = self.currentDrawable else {
      return
    }
    
    guard let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: currentRenderPassDescriptor) else {
      return
    }
    encoder.pushDebugGroup("RenderFrame")
    encoder.setRenderPipelineState(renderPipelineStateScreen)
    encoder.setFragmentTexture(renderTarget, index: 0)
    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
    encoder.popDebugGroup()
    encoder.endEncoding()
    commandBuffer.present(currentDrawable)
    commandBuffer.commit()
  }
  
  func drawObject(object: Cube, commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor) {
    
    guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
      print("Failed to create Metal command encoder")
      return
    }
    
    let uniformBuffer = getUniformBuffer(worldTransform: object.getTransform())
    
    commandEncoder.label = "Cube Shader"
    commandEncoder.setRenderPipelineState(renderPipelineStateCurvedShader!)
    commandEncoder.setVertexBuffer(object.vertexBuffer, offset: 0, index: 0)
    commandEncoder.setVertexBuffer(uniformBuffer, offset:0, index: 1)
    commandEncoder.setFragmentBuffer(uniformBuffer, offset:0, index: 1)
    commandEncoder.setFragmentTexture(renderTarget, index: 0)
    
    var curve: Float = self.uiDelegate!.parent.curve
    commandEncoder.setVertexBytes(&curve, length: MemoryLayout<Float>.stride, index: 2)
    
    commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: object.vertexCount, instanceCount: object.vertexCount / 3)
    commandEncoder.endEncoding()
  }
  
  func drawModel(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor) {
    
    guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
      print("Failed to create Metal command encoder")
      return
    }
    
    let uniformBuffer = getUniformBuffer(worldTransform: matrix_identity_float4x4)
    
    commandEncoder.label = "3D Model Rendering"
    commandEncoder.setRenderPipelineState(renderPipelineStateCurvedShaderModel!)
    commandEncoder.setVertexBuffer(uniformBuffer, offset:0, index: 1)
    commandEncoder.setFragmentBuffer(uniformBuffer, offset:0, index: 1)
    commandEncoder.setFragmentTexture(renderTarget, index: 0)
    
    var curve: Float = self.uiDelegate!.parent.curve
    commandEncoder.setVertexBytes(&curve, length: MemoryLayout<Float>.stride, index: 2)
    
    for mesh in meshes {
        let vertexBuffer = mesh.vertexBuffers.first!
        commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
     
        for submesh in mesh.submeshes {
            let indexBuffer = submesh.indexBuffer
            commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                 indexCount: submesh.indexCount,
                                                 indexType: submesh.indexType,
                                                 indexBuffer: indexBuffer.buffer,
                                                 indexBufferOffset: indexBuffer.offset)
        }
    }
    
    commandEncoder.endEncoding()
  }
  
  func applyTiltShift(commandBuffer: MTLCommandBuffer, renderPassDescriptor: MTLRenderPassDescriptor, loadAction: MTLLoadAction) {
    
    guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
      print("Failed to create Metal command encoder")
      return
    }
    
    commandEncoder.label = "Tilt Shift Shader"
    commandEncoder.setComputePipelineState(renderPipelineStateTiltShift!)
    commandEncoder.setTexture(accumulationTarget, index: 0)
    commandEncoder.setTexture(renderTarget, index: 1)
    commandEncoder.dispatchThreads(mtlSize, threadsPerThreadgroup: threadsPerThreadGroup)
    commandEncoder.endEncoding()
  }
  
}

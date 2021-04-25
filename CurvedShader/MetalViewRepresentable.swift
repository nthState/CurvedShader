//
//  MetalViewRepresentable.swift
//  CurvedShader
//
//  Created by Chris Davis on 24/04/2021.
//

import AppKit
import SwiftUI

struct MetalViewRepresentable: NSViewRepresentable {
  
  typealias NSViewType = RenderView
  
  @Binding var curve: Float
  @Binding var zCamera: Float
  @Binding var zCameraAngle: Float
  @Binding var zCameraHeight: Float

  func makeNSView(context: NSViewRepresentableContext<MetalViewRepresentable>) -> NSViewType {
    let renderView = NSViewType()
    renderView.uiDelegate = context.coordinator
    return renderView
  }
  
  func updateNSView(_ nsView: NSViewType, context: NSViewRepresentableContext<MetalViewRepresentable>) {
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
}

class Coordinator {
  var parent: MetalViewRepresentable
  
  init(_ parent: MetalViewRepresentable) {
    self.parent = parent
  }
}

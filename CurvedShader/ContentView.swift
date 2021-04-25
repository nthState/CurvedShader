//
//  ContentView.swift
//  CurvedShader
//
//  Created by Chris Davis on 24/04/2021.
//

import SwiftUI

struct ContentView: View {
  
  @State var curve: Float = 0.01
  @State var zCamera: Float = -5.0
  
    var body: some View {
        ZStack {
          
          Color.blue
            .ignoresSafeArea()
          
          MetalViewRepresentable(curve: $curve, zCamera: $zCamera)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
          
          VStack {
            
            HStack {
              Text("Curve")
              Slider(value: $curve, in: 0...1)
            }
            
            HStack {
              Text("Z Camera")
              Slider(value: $zCamera, in: -20...20)
            }
          }
          
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

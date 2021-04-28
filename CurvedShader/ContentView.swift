//
//  ContentView.swift
//  CurvedShader
//
//  Created by Chris Davis on 24/04/2021.
//

import SwiftUI

struct ContentView: View {
  
  @State var curve: Float = -0.01
  @State var zCamera: Float = -48
  @State var zCameraAngle: Float = 64
  @State var zCameraHeight: Float = -5
  
    var body: some View {
        ZStack {
          
          Color.blue
            .ignoresSafeArea()
          
          MetalViewRepresentable(curve: $curve, zCamera: $zCamera, zCameraAngle: $zCameraAngle, zCameraHeight: $zCameraHeight)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
          
          VStack {
            
            HStack {
              Text("World Curve")
              Slider(value: $curve, in: -1...1)
              TextField("", value: $curve, formatter: NumberFormatter())
                .frame(width: 100)
            }
            
            HStack {
              Text("Z Camera Position")
              Slider(value: $zCamera, in: -100...100)
              TextField("", value: $zCamera, formatter: NumberFormatter())
                .frame(width: 100)
            }
            
            HStack {
              Text("Z Camera Angle")
              Slider(value: $zCameraAngle, in: 0...360)
              TextField("", value: $zCameraAngle, formatter: NumberFormatter())
                .frame(width: 100)
            }
            
            HStack {
              Text("Z Camera Height")
              Slider(value: $zCameraHeight, in: -20...20)
              TextField("", value: $zCameraHeight, formatter: NumberFormatter())
                .frame(width: 100)
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

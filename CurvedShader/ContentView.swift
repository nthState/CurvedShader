//
//  ContentView.swift
//  CurvedShader
//
//  Created by Chris Davis on 24/04/2021.
//

import SwiftUI

struct ContentView: View {
  
  @State var curve: Float = 0.01
  
    var body: some View {
        ZStack {
          
          Color.blue
            .ignoresSafeArea()
          
          MetalViewRepresentable(curve: $curve)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
          
          Slider(value: $curve, in: 0...1)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

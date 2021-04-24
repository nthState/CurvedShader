//
//  ContentView.swift
//  CurvedShader
//
//  Created by Chris Davis on 24/04/2021.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
          
          Color.blue
            .ignoresSafeArea()
          
          MetalViewRepresentable()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
           
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

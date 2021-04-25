//
//  Logging.swift
//  CurvedShader
//
//  Created by Chris Davis on 25/04/2021.
//

import Foundation
import os.log

extension OSLog {
  
  // MARK: - Subsystem
  
  /// The subsystem for the app
  public static var appSubsystem = "com.nthstate.CurvedShader"
  
  // MARK: - Categories

  /// Camera
  static let camera = OSLog(subsystem: OSLog.appSubsystem, category: "Camera")
}

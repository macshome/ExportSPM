//
//  File.swift
//  exportSPM
//
//  Created by Josh Wisenbaker on 2/20/26.
//

import Foundation
import Xdecodable

struct ProjectInfo {
    let name: String
    let targets: [PBXNativeTarget]
    let dependencies: SwiftPackageDependencies
    let swiftVersion: SwiftToolsVersion
}

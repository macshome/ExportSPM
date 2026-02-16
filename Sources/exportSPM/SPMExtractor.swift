//
//  File.swift
//  exportSPM
//
//  Created by Josh Wisenbaker on 2/15/26.
//

import Foundation
import Xdecodable

typealias SwiftPackageDependencies = [String: XCRemoteSwiftPackageReference]

struct SPMExtractor {
    func findDependencies(_ project: XcodeProject) -> SwiftPackageDependencies {
        var swiftPackages = SwiftPackageDependencies()

        for (id, object) in project.objects {
            if case .remotePackageReference(let package) = object {
                swiftPackages[id] = package
            }
        }
        return swiftPackages
    }
}

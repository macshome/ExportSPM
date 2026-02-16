//
//  File.swift
//  exportSPM
//
//  Created by Josh Wisenbaker on 2/15/26.
//

import Foundation
import Xdecodable

struct SPMExtractor {
    func extractDependencies(_ project: XcodeProject) throws -> [String] {
        return ["foo"]
    }

    func findDependencies(_ project: XcodeProject)  {
        var swiftPackages: [String: XCRemoteSwiftPackageReference] = [:]

        for (id, object) in project.objects {
            if case .remotePackageReference(let package) = object {
                swiftPackages[id] = package
            }
        }
    }
}

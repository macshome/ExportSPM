//
//  File.swift
//  exportSPM
//
//  Created by Josh Wisenbaker on 2/20/26.
//

import Foundation
import Xdecodable

/// Maps object IDs to their corresponding remote Swift package references.
typealias SwiftPackageDependencies = [String: XCRemoteSwiftPackageReference]
typealias SwiftToolsVersion = String

extension XCRemoteSwiftPackageReference: @retroactive CustomStringConvertible {
    public var description: String {
        return formatKind()
    }

    func formatKind() -> String {
        switch requirement.kind {
        case .upToNextMinorVersion:
            return ".package(url: \(repositoryURL), .upToNextMinor(\"\(requirement.minimumVersion!)\")),"
        case .upToNextMajorVersion:
            return ".package(url: \(repositoryURL), from: \"\(requirement.minimumVersion!)\"),"
        case .branch:
            return ".package(url: \(repositoryURL), .branch(\"\(requirement.branch!)\")),"
        case .exactVersion:
            //TODO: Figure out how Xcode stores the exact version requirement. This option is rarely used.
            return ".package(url: \(repositoryURL), .exact(\"\(requirement.minimumVersion ?? "1.0.0")\")),"
        case .versionRange:
            return ".package(url: \(repositoryURL), .range(\"\(requirement.minimumVersion!)\" ..< \"\(requirement.maximumVersion!)\")),"
        case .revision:
            return ".package(url: \(repositoryURL), .revision(\"\(requirement.revision!)\")),"
        }
    }
}

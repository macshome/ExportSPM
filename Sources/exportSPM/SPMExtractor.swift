//
//  File.swift
//  exportSPM
//
//  Created by Josh Wisenbaker on 2/15/26.
//

import Foundation
import Xdecodable

/// Maps object IDs to their corresponding remote Swift package references.
typealias SwiftPackageDependencies = [String: XCRemoteSwiftPackageReference]
typealias SwiftToolsVersion = String

/// Extracts Swift Package Manager dependencies from an `XcodeProject`.
struct SPMExtractor {

    /// Finds all remote Swift package references in the project.
    ///
    /// - Parameter project: The decoded Xcode project to scan.
    /// - Returns: A dictionary keyed by object ID containing remote package references.
    func findDependencies(_ project: XcodeProject) -> SwiftPackageDependencies {
        var swiftPackages = SwiftPackageDependencies()

        for (id, object) in project.objects {
            if case .remotePackageReference(let package) = object {
                swiftPackages[id] = package
            }
        }

        return swiftPackages
    }

    /// Finds the highest Swift version specified in the project.
    ///
    /// Checks project-level and target-level build configurations for SWIFT_VERSION settings.
    /// Returns the highest version found, normalized to major.minor format (e.g., "5.7").
    ///
    /// - Parameter project: The decoded Xcode project to scan.
    /// - Returns: Swift tools version string in major.minor format, defaults to "6.0" if none found.
    func findSwiftVersion(_ project: XcodeProject) -> SwiftToolsVersion {
        let versions = extractVersions(from: project)

        guard let maxVersion = versions.max(by: compareVersions) else {
            return "6.0"
        }

        return normalizeVersion(maxVersion)
    }

    /// Extracts all SWIFT_VERSION values from project and target build configurations.
    private func extractVersions(from project: XcodeProject) -> [String] {
        project.objects.values.flatMap { object -> [String] in
            switch object {
            case .project(let pbxProject):
                return getVersions(from: pbxProject.buildConfigurationList, in: project)
            case .nativeTarget(let target):
                return getVersions(from: target.buildConfigurationList, in: project)
            default:
                return []
            }
        }
    }

    /// Extracts SWIFT_VERSION values from a build configuration list.
    private func getVersions(from configListId: String, in project: XcodeProject) -> [String] {
        guard let configList = project.objects[configListId],
              case .configurationList(let list) = configList else {
            return []
        }

        return list.buildConfigurations.compactMap { configId in
            guard let config = project.objects[configId],
                  case .buildConfiguration(let buildConfig) = config,
                  let versionValue = buildConfig.buildSettings["SWIFT_VERSION"],
                  let swiftVersion = versionValue.value as? String else {
                return nil
            }

            return swiftVersion
        }
    }

    /// Compares two version strings numerically.
     func compareVersions(_ v1: String, _ v2: String) -> Bool {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(parts1.count, parts2.count) {
            let p1 = i < parts1.count ? parts1[i] : 0
            let p2 = i < parts2.count ? parts2[i] : 0
            if p1 != p2 {
                return p1 < p2
            }
        }

        return false
    }

    /// Normalizes a version string to major.minor format.
     func normalizeVersion(_ version: String) -> String {
        let parts = version.split(separator: ".").compactMap { Int($0) }

        guard parts.count >= 2 else {
            return parts.isEmpty ? "6.0" : "\(parts[0]).0"
        }

        return "\(parts[0]).\(parts[1])"
    }
}

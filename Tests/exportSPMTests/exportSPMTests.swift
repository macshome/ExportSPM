//
//  exportSPMTests.swift
//  exportSPM
//
//  Created by Josh Wisenbaker on 12/5/25.
//

import ArgumentParser
import Foundation
import Testing
@testable import exportSPM

@Suite("Tests for the main executable")
struct MainTests {
    @Test("Test Path Parsing", arguments: try TestResources.projects)
    func testPathParsing(_ url: URL) async throws {
        let sut = ExportSPM()
        let expectedURL = url.appending(path: "project.pbxproj")
        let projectURL = try sut.getURL(url.path)
        #expect(projectURL == expectedURL)
    }

    @Test("Test Throws with Invalid Path", arguments: try TestResources.projects)
    func testInvalidPath(_ url: URL) async throws {
        let sut = ExportSPM()
        let invalidPath = url.path + "/nonexistent"
        #expect(throws: (any Error).self) {
            try sut.getURL(invalidPath)
        }
    }
}

@Suite("Tests for Xcode project parsing")
struct ParserTests {
    @Test("Test Xcode Project Loading", arguments: try TestResources.projects)
    func testProjectLoading(_ url: URL) async throws {
        let sut = XcodeParser()
        let projectURL = url.appending(path: "project.pbxproj")
        let project = try sut.parseProject(projectURL)
        #expect(!project.objects.isEmpty, "Expected project to contain objects")
    }

    @Test("Test Throws with Invalid Path", arguments: try TestResources.projects)
    func testBadDecodePath(_ url: URL) async throws {
        let sut = XcodeParser()
        #expect(throws: (any Error).self) {
            try sut.parseProject(url)
        }
    }
}

@Suite("Tests for SPM extraction logic")
struct ExtractorTests {
    @Test(
        "Test SPM Extraction",
        arguments: try TestResources.projects.filter { $0.lastPathComponent == "SPM.xcodeproj" }
    )
    func testSPMExtraction(_ url: URL) async throws {
        let parser = XcodeParser()
        let sut = SPMExtractor()
        let projectURL = url.appending(path: "project.pbxproj")
        let project = try parser.parseProject(projectURL)
        let spmInfo = sut.findDependencies(project)
        #expect(spmInfo.count > 0, "Expected to extract at least one SPM dependency")
    }

    @Test(
        "Test SPM Extraction with No Dependencies",
        arguments: try TestResources.projects.filter { $0.lastPathComponent == "NoSPM.xcodeproj" }
    )
    func testNoSPMExtraction(_ url: URL) async throws {
        let parser = XcodeParser()
        let sut = SPMExtractor()
        let projectURL = url.appending(path: "project.pbxproj")
        let project = try parser.parseProject(projectURL)
        let spmInfo = sut.findDependencies(project)
        #expect(spmInfo.isEmpty, "Expected to extract no SPM dependencies")
    }

    @Test("Find Swift Version", arguments: try TestResources.projects.filter { $0.lastPathComponent == "SPM.xcodeproj" })
    func testFindSwiftVersion(_ url: URL) async throws {
        let parser = XcodeParser()
        let sut = SPMExtractor()
        let projectURL = url.appending(path: "project.pbxproj")
        let project = try parser.parseProject(projectURL)
        let swiftVersion = sut.findSwiftVersion(project)
        #expect(swiftVersion == "5.0", "Expected to find Swift version 5.0")
    }

    @Test("Find Swift Version fallback", arguments: try TestResources.projects.filter { $0.lastPathComponent == "SPM-No-Version.xcodeproj" })
    func testVersionFallback(_ url: URL) async throws {
        let parser = XcodeParser()
        let sut = SPMExtractor()
        let projectURL = url.appending(path: "project.pbxproj")
        let project = try parser.parseProject(projectURL)
        let swiftVersion = sut.findSwiftVersion(project)
        #expect(swiftVersion == "6.0", "Expected to find Swift version 6.0")
    }

    @Test("Version comparison handles major versions correctly")
    func testVersionComparison() {
        let extractor = SPMExtractor()

        #expect(extractor.compareVersions("5.0", "6.0") == true)
        #expect(extractor.compareVersions("6.0", "5.0") == false)
        #expect(extractor.compareVersions("5.0", "5.0") == false)
    }

    @Test("Version comparison handles minor versions correctly")
    func testVersionComparisonMinor() {
        let extractor = SPMExtractor()

        #expect(extractor.compareVersions("5.7", "5.8") == true)
        #expect(extractor.compareVersions("5.9", "5.10") == true)
        #expect(extractor.compareVersions("5.7", "5.7") == false)
    }

    @Test("Version comparison handles different lengths")
    func testVersionComparisonDifferentLengths() {
        let extractor = SPMExtractor()

        #expect(extractor.compareVersions("5", "5.0") == false)
        #expect(extractor.compareVersions("5.0", "5") == false)
        #expect(extractor.compareVersions("5", "5.0.1") == true)
        #expect(extractor.compareVersions("5.7.1", "5.7") == false)
    }

    @Test("Version normalization handles single component")
    func testNormalizeVersionSingle() {
        let extractor = SPMExtractor()

        #expect(extractor.normalizeVersion("5") == "5.0")
        #expect(extractor.normalizeVersion("6") == "6.0")
    }

    @Test("Version normalization handles two components")
    func testNormalizeVersionDouble() {
        let extractor = SPMExtractor()

        #expect(extractor.normalizeVersion("5.7") == "5.7")
        #expect(extractor.normalizeVersion("6.0") == "6.0")
    }

    @Test("Version normalization truncates patch version")
    func testNormalizeVersionTruncate() {
        let extractor = SPMExtractor()

        #expect(extractor.normalizeVersion("5.7.1") == "5.7")
        #expect(extractor.normalizeVersion("6.0.1") == "6.0")
    }

    @Test("Version normalization handles empty string")
    func testNormalizeVersionEmpty() {
        let extractor = SPMExtractor()

        #expect(extractor.normalizeVersion("") == "6.0")
    }
}

/// Helper struct for loading test project resources from the bundle.
///
/// Provides a convenient interface for discovering and accessing Xcode project files
/// bundled with the test target.
struct TestResources {
    /// Returns an array of URLs for all `.xcodeproj` bundles in the TestProjects directory.
    /// To add a new test project, just drop the project file in the TestProjects directory.
    ///
    /// Loads all Xcode project directories from the test bundle's TestProjects subdirectory.
    /// This property is used as the argument source for parameterized tests.
    ///
    /// - Returns: Array of file URLs pointing to `.xcodeproj` directories
    /// - Throws: `NSError` if the TestProjects directory cannot be found in the bundle
    static var projects: [URL] {
        get throws {
            guard
                let resourcesURL = Bundle.module.resourceURL?
                    .appending(path: "TestProjects", directoryHint: .isDirectory)
            else {
                throw NSError(
                    domain: "Tests",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to load test project URL"]
                )
            }

            return try FileManager.default.contentsOfDirectory(
                at: resourcesURL,
                includingPropertiesForKeys: nil
            ).filter { $0.pathExtension == "xcodeproj" }
        }
    }
}

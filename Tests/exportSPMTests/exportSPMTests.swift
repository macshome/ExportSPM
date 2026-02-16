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

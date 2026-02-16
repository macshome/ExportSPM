// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import Xdecodable

@main
struct ExportSPM: ParsableCommand {
    @Argument(help: "Path to the .xcodeproj file.")
    var xcodeprojPath = ""

    mutating func run() throws {
        let projectURL = try getURL(xcodeprojPath)
        let parser = XcodeParser()
        let extractor = SPMExtractor()

        let parsedProj = try parser.parseProject(projectURL)
        let spmInfo = try extractor.extractDependencies(parsedProj)
    }

    func getURL(_ path: String) throws -> URL {

        let projectURL = URL(fileURLWithPath: path + "/project.pbxproj")
        try projectURL.checkResourceIsReachable()
        return projectURL
    }
}

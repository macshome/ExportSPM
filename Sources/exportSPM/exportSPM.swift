// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation

@main
struct exportSPM: ParsableCommand {
    @Argument(help: "Path to the .xcodeproj file.")
    var xcodeprojPath = ""

    mutating func run() throws {
            let projectURL = try getURL(xcodeprojPath)
    }

    func getURL(_ path: String) throws -> URL {
        let projectURL = URL(fileURLWithPath: path + "/project.pbxproj")
          guard try projectURL.checkResourceIsReachable() else {
              throw ValidationError("Path to project file does not exist.")
          }
        return projectURL
    }
}

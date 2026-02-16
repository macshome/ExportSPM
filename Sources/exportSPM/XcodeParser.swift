//
//  File.swift
//  exportSPM
//
//  Created by Josh Wisenbaker on 2/13/26.
//

import Foundation
import Xdecodable

struct XcodeParser {
    func parseProject(_ url: URL) throws -> XcodeProject {

        let data = try Data(contentsOf: url)

        let decoder = PropertyListDecoder()
        let project = try decoder.decode(XcodeProject.self, from: data)

        return project
    }
}

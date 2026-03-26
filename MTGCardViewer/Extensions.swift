//
//  Extensions.swift
//  MTGCardViewer
//
//  Created by Michael Nguyen on 10/28/25.
//
import Foundation

extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        guard let build = infoDictionary?["CFBundleVersion"] as? String,
              let buildInt = Int(build) else {
            return infoDictionary?["CFBundleVersion"] as? String
        }
        return String(format: "%03d", buildInt)
    }
}

//
//  DeepLinkRouter.swift
//  TogetherWeGo
//
//  Created by Aaryaman on 10/11/26.
//


import Foundation
import Observation

@Observable
class DeepLinkRouter {
    // Set when the app is opened from an invite link
    var pendingJoinCode: String?

    // Handles links like togetherwego://join/K7QX2M
    func handle(_ url: URL) {
        guard url.scheme == "togetherwego", url.host == "join" else { return }

        let code = url.lastPathComponent.uppercased()

        // Never trust a link: check the code is shaped correctly first
        guard code.count == 6,
              code.allSatisfy({ Trip.codeCharacters.contains($0) }) else { return }

        pendingJoinCode = code
    }
}
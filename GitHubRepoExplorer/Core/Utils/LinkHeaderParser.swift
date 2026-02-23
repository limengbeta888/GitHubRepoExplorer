//
//  LinkHeaderParser.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
//

import Foundation

class LinkHeaderParser {

    /// Parses a GitHub-style `Link` HTTP header and returns the `rel="next"` URL, if present.
    ///
    /// Example input:
    ///   `<https://api.github.com/repositories?since=364>; rel="next", <...>; rel="first"`
    static func nextURL(from header: String?) -> URL? {
        guard let header, !header.isEmpty else { return nil }

        for part in header.components(separatedBy: ",") {
            let segments = part.components(separatedBy: ";")
            guard segments.count >= 2 else { continue }

            let urlPart = segments[0].trimmingCharacters(in: .whitespaces)
            let relPart = segments[1].trimmingCharacters(in: .whitespaces)

            guard relPart.contains(#"rel="next""#) else { continue }

            let urlString = urlPart.trimmingCharacters(in: CharacterSet(charactersIn: "<> "))
            return URL(string: urlString)
        }
        return nil
    }
}

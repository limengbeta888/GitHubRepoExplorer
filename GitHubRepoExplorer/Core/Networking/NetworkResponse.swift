//
//  NetworkResponse.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 11/06/2026.
//

import Foundation

/// Wraps a decoded response body together with the raw `HTTPURLResponse`.
/// Callers use this when they need to inspect response headers —
/// most importantly GitHub's `Link` header for pagination cursors.
struct NetworkResponse<T> {
    let body: T
    let httpResponse: HTTPURLResponse

    /// Parses the `Link: rel="next"` header and returns the cursor URL, if present.
    /// Delegates to `LinkHeaderParser` — callers never need to import it directly.
    var nextPageURL: URL? {
        nextURL(from: httpResponse.value(forHTTPHeaderField: "Link"))
    }
    
    /// Parses a GitHub-style `Link` HTTP header and returns the `rel="next"` URL, if present.
    ///
    /// Example input:
    ///   `<https://api.github.com/repositories?since=364>; rel="next", <...>; rel="first"`
    private func nextURL(from header: String?) -> URL? {
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

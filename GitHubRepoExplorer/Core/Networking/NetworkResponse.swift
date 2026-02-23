//
//  NetworkResponse.swift
//  GitHubRepoExplorer
//
//  Created by Meng Li on 23/02/2026.
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
        LinkHeaderParser.nextURL(from: httpResponse.value(forHTTPHeaderField: "Link"))
    }
}

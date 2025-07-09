#if os(iOS)
import Foundation

extension URL {
    /// Builds the aegis://x-callback-url/nip46Auth URL with required query items.
    static func aegisCallbackURL(
        nostrConnectURI: String,
        redirect: Redirect
    ) -> URL? {
        var components = URLComponents()
        components.scheme = "aegis"
        components.host = "x-callback-url"
        components.path = "/nip46Auth"
        components.queryItems = [
            .init(name: "nostrconnect", value: nostrConnectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)),
            .init(name: "x-source", value: redirect.source),
            .init(name: "x-success", value: redirect.successScheme),
            .init(name: "x-error", value: redirect.errorScheme)
        ]
        return components.url
    }
}
#endif 
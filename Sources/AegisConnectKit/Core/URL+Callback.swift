#if os(iOS)
import Foundation

extension URL {
    static func aegisCallbackURL(
        nostrConnectURI: String,
        redirect: Redirect
    ) -> URL? {
        var components = URLComponents()
        components.scheme = "aegis"
        components.host = "x-callback-url"
        components.path = "/auth/nip46"
        components.queryItems = [
            .init(name: "method", value: "connect"),
            .init(name: "nostrconnect", value: nostrConnectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)),
            .init(name: "x-source", value: redirect.source),
            .init(name: "x-success", value: redirect.successScheme),
            .init(name: "x-error", value: redirect.errorScheme)
        ]
        return components.url
    }
}
#endif 
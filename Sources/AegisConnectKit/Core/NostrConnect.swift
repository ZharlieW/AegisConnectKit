import Foundation
import libsecp256k1

public enum NIP46Builder {
    public static func createNostrConnectURI(
        clientPubKey: String,
        secret: String,
        name: String? = nil,
        url: String = "",
        image: String = "",
        scheme: String? = nil
    ) -> String {
        let uri = createNostrConnectURL(
            clientPubKey: clientPubKey,
            secret: secret,
            relays: ["ws://127.0.0.1:8081"],
            name: name ?? scheme ?? Self.defaultAppScheme,
            url: url,
            image: image,
            scheme: scheme ?? Self.defaultAppScheme
        )
        
        return uri
    }

    public static func createNostrConnectURL(
        clientPubKey: String,
        secret: String,
        relays: [String],
        name: String? = nil,
        url: String? = nil,
        image: String? = nil,
        scheme: String? = nil
    ) -> String {
        var components = URLComponents()
        components.scheme = "nostrconnect"
        components.host = clientPubKey.lowercased()

        var query: [URLQueryItem] = [
            URLQueryItem(name: "relay", value: relays.joined(separator: "&relay=")),
            URLQueryItem(name: "secret", value: secret),
            URLQueryItem(name: "scheme", value: scheme ?? Self.defaultAppScheme)
        ]
        if let name = name { query.append(.init(name: "name", value: name)) }
        if let url = url { query.append(.init(name: "url", value: url)) }
        if let image = image { query.append(.init(name: "image", value: image)) }
        

        components.queryItems = query
        return components.url?.absoluteString ?? ""
    }
    
    private static var defaultAppScheme: String? {
        guard let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] else {
            return nil
        }
        for dict in urlTypes {
            if let schemes = dict["CFBundleURLSchemes"] as? [String],
               let first = schemes.first, !first.isEmpty {
                return first
            }
        }
        return nil
    }
}

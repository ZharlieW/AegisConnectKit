import Foundation
import libsecp256k1

public enum NIP46Builder {
    public static func createNostrConnectURI(
        relays: [String] = ["wss://relay.nsec.app"],
        perms: String? = nil,
        name: String? = nil,
        url: String = "",
        image: String = "",
        scheme: String? = nil
    ) -> (uri: String, pubkey: String, privkey: String, secret: String) {
        let keychain = Keychain.generate()
        let pubHex = keychain.public
        let privHex = keychain.private
        let secret = CryptoUtils.generate64RandomHexChars() // 64 hex chars


        let uri = createNostrConnectURL(
            clientPubKey: pubHex,
            secret: secret,
            relays: relays,
            perms: perms,
            name: name ?? scheme ?? Self.defaultAppScheme,
            url: url,
            image: image,
            scheme: scheme ?? Self.defaultAppScheme
        )
        
        return (uri, pubHex, privHex, secret)
    }

    public static func createNostrConnectURL(
        clientPubKey: String,
        secret: String,
        relays: [String],
        perms: String? = nil,
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
        if let perms = perms, !perms.isEmpty { query.append(.init(name: "perms", value: perms)) }
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

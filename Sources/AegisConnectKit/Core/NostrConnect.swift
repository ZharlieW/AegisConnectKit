import Foundation
import secp256k1

public enum NIP46Builder {
    /// Generates keypair and secret, stores them into a connection holder then returns nostrconnect URI.
    /// - Parameters:
    ///   - relays: Relay URLs, default common relay.
    ///   - perms: Permissions string, optional.
    ///   - name: Client name.
    ///   - url: Client website.
    ///   - image: Client icon URL.
    /// - Returns: Tuple of URI, clientPubKey, clientPrivKey, secret.
    public static func createNostrConnectURI(
        relays: [String] = ["wss://relay.nsec.app"],
        perms: String? = nil,
        name: String = "Aegis-iOS",
        url: String = "",
        image: String = ""
    ) -> (uri: String, pubkey: String, privkey: String, secret: String) {
        guard let keychain = try? BIP340Keychain() else {
            fatalError("Unable to generate keypair")
        }
        let pubHex = keychain.publicKeyHex
        let privHex = keychain.privateKeyHex
        let secret = CryptoUtils.generate64RandomHexChars() // 64 hex chars

        let uri = createNostrConnectURL(
            clientPubKey: pubHex,
            secret: secret,
            relays: relays,
            perms: perms,
            name: name,
            url: url,
            image: image
        )
        return (uri, pubHex, privHex, secret)
    }

    /// Builds Nostr Connect URL according to NIP-46 spec.
    public static func createNostrConnectURL(
        clientPubKey: String,
        secret: String,
        relays: [String],
        perms: String? = nil,
        name: String? = nil,
        url: String? = nil,
        image: String? = nil
    ) -> String {
        var components = URLComponents()
        components.scheme = "nostrconnect"
        components.host = clientPubKey.lowercased()

        var query: [URLQueryItem] = [
            URLQueryItem(name: "relay", value: relays.joined(separator: "&relay=")),
            URLQueryItem(name: "secret", value: secret)
        ]
        if let perms = perms, !perms.isEmpty { query.append(.init(name: "perms", value: perms)) }
        if let name = name { query.append(.init(name: "name", value: name)) }
        if let url = url { query.append(.init(name: "url", value: url)) }
        if let image = image { query.append(.init(name: "image", value: image)) }

        components.queryItems = query
        return components.url?.absoluteString ?? ""
    }
} 

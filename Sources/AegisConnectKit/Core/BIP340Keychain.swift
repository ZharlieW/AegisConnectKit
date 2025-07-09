import Foundation
import secp256k1

/// Swift version of the Dart `Keychain` using BIP-340 Schnorr signatures over secp256k1.
public struct BIP340Keychain {
    /// 32-byte private key (hex encoded, lowercase, 64 chars)
    public let privateKeyHex: String
    /// 32-byte public key (hex encoded, lowercase, 64 chars) – x-coordinate only as in BIP-340
    public let publicKeyHex: String

    private let privateKey: S256K1.PrivateKey
    private let publicKey: S256K1.PublicKey

    // MARK: - Initializers

    /// Create keychain from an existing 64-char private key hex string.
    public init?(privateKeyHex: String) {
        guard let privData = Data(hex: privateKeyHex), privData.count == 32,
              let pk = try? S256K1.PrivateKey(rawRepresentation: privData) else {
            return nil
        }
        self.privateKey = pk
        self.publicKey = pk.publicKey
        self.privateKeyHex = privateKeyHex.lowercased()
        self.publicKeyHex = publicKey.xonly.hexString
    }

    /// Generate a fresh random keypair.
    public init() throws {
        let pk = S256K1.PrivateKey()
        self.privateKey = pk
        self.publicKey = pk.publicKey
        self.privateKeyHex = pk.rawRepresentation.hexString
        self.publicKeyHex = publicKey.xonly.hexString
    }

    // MARK: - Sign / Verify

    /// Schnorr sign message and return 128-char hex signature (64 bytes).
    public func sign(message: Data) throws -> String {
        // 32-byte aux random as per BIP-340
        let auxHex = CryptoUtils.generate64RandomHexChars()
        guard let auxData = Data(hex: auxHex) else { throw KeychainError.invalidHex }
        let sig = try privateKey.schnorr.sign(message, auxRand: auxData)
        return sig.rawRepresentation.hexString
    }

    /// Verify Schnorr signature.
    /// - Returns: true if valid.
    public static func verify(publicKeyHex: String, message: Data, signatureHex: String) -> Bool {
        guard let pubData = Data(hex: publicKeyHex), pubData.count == 32,
              let sigData = Data(hex: signatureHex), sigData.count == 64,
              let pub = try? S256K1.PublicKey(xonly: pubData),
              let sig = try? S256K1.SchnorrSignature(rawRepresentation: sigData) else {
            return false
        }
        return pub.schnorr.isValid(signature: sig, message: message)
    }

    // MARK: - Errors
    public enum KeychainError: Error {
        case invalidHex
    }
} 
import Foundation

extension Data {
    /// Returns lowercase hex string representation.
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

enum CryptoUtils {
    /// Generates a random hex string of given byte length * 2 characters.
    static func randomHex(byteCount: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        _ = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
        return Data(bytes).hexString
    }
} 
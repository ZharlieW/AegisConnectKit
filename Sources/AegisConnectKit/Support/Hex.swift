import Foundation

extension Data {
    /// Returns lowercase hex string representation.
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }

    /// Initialize Data from hex string.
    init?(hex: String) {
        let len = hex.count
        guard len % 2 == 0 else { return nil }
        var bytes = [UInt8]()
        bytes.reserveCapacity(len / 2)
        var index = hex.startIndex
        for _ in 0..<(len / 2) {
            let next = hex.index(index, offsetBy: 2)
            let byteStr = hex[index..<next]
            if let byte = UInt8(byteStr, radix: 16) {
                bytes.append(byte)
            } else { return nil }
            index = next
        }
        self.init(bytes)
    }
}

enum CryptoUtils {
    /// Generates a random hex string of given byte length * 2 characters.
    static func generate64RandomHexChars() -> String {
        randomHex(byteCount: 32)
    }
}

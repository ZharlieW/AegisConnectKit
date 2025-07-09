import Foundation
import libsecp256k1

public class Keychain {
    public var `private`: String
    public var `public`: String
    private var privBytes: [UInt8] { Array(Data(hex: `private`)!) }
    private var pubkey: secp256k1_pubkey = secp256k1_pubkey()
    private static let ctx: OpaquePointer = {
        let c = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN|SECP256K1_CONTEXT_VERIFY))!
        return c
    }()

    public init(_ priv: String) {
        precondition(priv.count == 64)
        let privLower = priv.lowercased()
        let privBytes = Array(Data(hex: privLower)!)
        self.private = privLower
        var pub = secp256k1_pubkey()
        let ok = secp256k1_ec_pubkey_create(Keychain.ctx, &pub, privBytes)
        precondition(ok == 1, "Invalid private key")
        self.pubkey = pub
        self.public = Keychain.getPublicKey(privLower)
    }

    public static func generate() -> Keychain {
        let priv = CryptoUtils.generate64RandomHexChars()
        return Keychain(priv)
    }


    public static func getPublicKey(_ priv: String) -> String {
        var pub = secp256k1_pubkey()
        let privBytes = Array(Data(hex: priv)!)
        let ok = secp256k1_ec_pubkey_create(Keychain.ctx, &pub, privBytes)
        precondition(ok == 1, "Invalid private key")
        // BIP340 x-only
        var xonlyPubkey = secp256k1_xonly_pubkey()
        var pk_parity: Int32 = 0
        let ok2 = secp256k1_xonly_pubkey_from_pubkey(Keychain.ctx, &xonlyPubkey, &pk_parity, &pub)
        precondition(ok2 == 1, "Failed to get xonly pubkey")
        var xonly = [UInt8](repeating: 0, count: 32)
        secp256k1_xonly_pubkey_serialize(Keychain.ctx, &xonly, &xonlyPubkey)
        return Data(xonly).hexString
    }

}

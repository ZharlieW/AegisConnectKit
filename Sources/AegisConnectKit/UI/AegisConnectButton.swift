#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import UIKit

public struct AegisConnectButton: View {
    private let scope: [String]
    private let redirect: Redirect
    private let scheme: String
    private let qrCodeURL: String?
    private let title: String
    private let onResult: (Result<Credential, Error>) -> Void

    /// Creates an Aegis connect button.
    /// - Parameters:
    ///   - scope: Permission scopes.
    ///   - scheme: Custom URL scheme declared in Info.plist (without `://`).
    ///   - title: Button title, default is "Connect with Aegis".
    ///   - onResult: Callback invoked when the connect flow finishes.
    public init(
        scope: [String] = ["read"],
        scheme: String,
        qrCodeURL: String? = nil,
        title: String = "Connect with Aegis",
        onResult: @escaping (Result<Credential, Error>) -> Void = { _ in }
    ) {
        self.scope = scope
        self.scheme = scheme
        self.redirect = Redirect(
            source: scheme,
            successScheme: "\(scheme)://x-callback-url/nip46AuthSuccess",
            errorScheme: "\(scheme)://x-callback-url/nip46AuthError"
        )
        self.qrCodeURL = qrCodeURL
        self.title = title
        self.onResult = onResult
    }

    /// Convenience initializer keeping compatibility with previous version.
    /// It tries to infer scheme via first URL type in Info.plist.
    public init(scope: [String] = ["read"]) {
        let scheme: String = {
            if let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]],
               let schemes = urlTypes.first?["CFBundleURLSchemes"] as? [String],
               let first = schemes.first {
                return first
            }
            return "myapp"
        }()
        self.init(scope: scope, scheme: scheme)
    }

    /// Convenience initializer that auto-generates keypair & secret.
    public init(
        relays: [String] = ["wss://relay.nsec.app"],
        scheme: String,
        title: String = "Connect with Aegis",
        onResult: @escaping (Result<Credential, Error>) -> Void = { _ in }
    ) {
        let (uri, _, _, _) = NIP46Builder.createNostrConnectURI(relays: relays)
        self.init(scope: ["read"], scheme: scheme, qrCodeURL: uri, title: title, onResult: onResult)
    }

    public var body: some View {
        Button(action: connect) {
            HStack {
                Image(systemName: "shield.fill")
                Text(title)
            }
            .padding()
            .foregroundColor(.white)
            .background(Color.accentColor)
            .cornerRadius(8)
        }
    }

    private func connect() {
        guard let rootVC = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }

        Task {
            do {
                let credential: Credential
                if let qr = qrCodeURL {
                    let nostrURI = "\(qr)&scheme=\(scheme)"
                    credential = try await AegisConnectKit.shared.connect(
                        nostrConnectURI: nostrURI,
                        redirect: redirect,
                        scope: scope,
                        from: rootVC
                    )
                } else {
                    credential = try await AegisConnectKit.shared.connect(
                        redirect: redirect,
                        scope: scope,
                        from: rootVC
                    )
                }
                onResult(.success(credential))
            } catch {
                onResult(.failure(error))
            }
        }
    }
}
#endif

#if DEBUG && canImport(SwiftUI)
struct AegisConnectButton_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AegisConnectButton()
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Default")
            AegisConnectButton(scope: ["read", "write"])
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif 
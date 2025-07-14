
#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import UIKit


public struct AegisConnectButton: View {

    private let redirect: Redirect
    private let scheme: String
    private let relays: [String]
    private let perms: String?
    private let url: String
    private let image: String
    private let title: String
    private let onResult: (Result<Credential, Error>) -> Void
    private let name: String?
    private let clientPubKey: String
    private let secret: String

    public init(
        clientPubKey: String,
        secret: String,
        scheme: String? = nil,
        relays: [String] = ["wss://relay.nsec.app"],
        perms: String? = nil,
        url: String = "",
        image: String = "",
        name: String? = nil,
        title: String = "Connect with Aegis",
        onResult: @escaping (Result<Credential, Error>) -> Void = { _ in }
    ) {
        self.clientPubKey = clientPubKey
        self.secret = secret
        
        let resolvedScheme: String? = scheme ?? {
            if let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] {
                for item in urlTypes {
                    if let schemes = item["CFBundleURLSchemes"] as? [String],
                       let first = schemes.first(where: { !$0.isEmpty }) {
                        return first
                    }
                }
            }
            return nil
        }()
        guard let schemeValue = resolvedScheme else {
            self.scheme = ""
            self.redirect = Redirect(source: "", successScheme: "", errorScheme: "")
            self.relays = relays
            self.perms = perms
            self.url = url
            self.image = image
            self.title = title
            self.onResult = onResult
            self.name = name
            return
        }
        self.scheme = schemeValue
        self.redirect = Redirect(
            source: schemeValue,
            successScheme: "\(schemeValue)://x-callback-url/nip46AuthSuccess",
            errorScheme:   "\(schemeValue)://x-callback-url/nip46AuthError"
        )
        self.relays = relays
        self.perms = perms
        self.url = url
        self.image = image
        self.title     = title
        self.onResult  = onResult
        self.name = name
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
        guard let _ = UIApplication.shared
            .connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }

        Task {
            do {
                let credential: Credential
                credential = try await AegisConnectKit.shared.connect(
                    clientPubKey: clientPubKey,
                    secret: secret,
                    redirect: redirect,
                    perms: perms,
                    name: name,
                    url: url,
                    image: image,
                    scheme: scheme
                )
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
            AegisConnectButton(
                clientPubKey: "preview_client_pubkey",
                secret: "preview_secret"
            )
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Default")
            AegisConnectButton(
                clientPubKey: "preview_client_pubkey",
                secret: "preview_secret"
            )
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif

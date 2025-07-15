
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
    private let useCustomLogo: Bool

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
        useCustomLogo: Bool = false,
        onResult: @escaping (Result<Credential, Error>) -> Void = { _ in }
    ) {
        self.clientPubKey = clientPubKey
        self.secret = secret
        self.useCustomLogo = useCustomLogo
        
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
                if useCustomLogo {
                    Image("aegis_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                }
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
                .previewDisplayName("System Icon")
            AegisConnectButton(
                clientPubKey: "preview_client_pubkey",
                secret: "preview_secret",
                useCustomLogo: true
            )
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Custom Logo")
        }
    }
}
#endif

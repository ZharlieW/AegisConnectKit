
#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import UIKit


public struct AegisConnectButton: View {
    private let clientPubKey: String
    private let secret: String
    private let redirect: Redirect
    private let scheme: String
    private let url: String
    private let image: String
    private let title: String
    private let onResult: (Result<Credential, Error>) -> Void
    private let name: String?
    private let useAegisLogo: Bool
    private let backgroundColor: Color

    public init(
        clientPubKey: String,
        secret: String,
        scheme: String? = nil,
        url: String = "",
        image: String = "",
        name: String? = nil,
        title: String = "Connect with Aegis",
        useAegisLogo: Bool = false,
        backgroundColor: Color = .white,
        onResult: @escaping (Result<Credential, Error>) -> Void = { _ in }
    ) {
        self.clientPubKey = clientPubKey
        self.secret = secret
        self.useAegisLogo = useAegisLogo
        self.backgroundColor = backgroundColor
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
            print("[AegisConnectButton] Error: No URL scheme found. Please set scheme explicitly or configure Info.plist.")
            self.scheme = ""
            self.redirect = Redirect(source: "", successScheme: "", errorScheme: "")
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
            successScheme: "\(schemeValue)://x-callback-url/authSuccess",
            errorScheme:   "\(schemeValue)://x-callback-url/authError"
        )
        self.url = url
        self.image = image
        self.title     = title
        self.onResult  = onResult
        self.name = name
    }

    public var body: some View {
        Button(action: connect) {
            HStack {
                if useAegisLogo {
                    Image("aegis_logo", bundle: .module)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "shield.fill")
                }
                Text(title)
            }
            .padding()
            .foregroundColor(backgroundColor == .white ? .black : .white)
            .background(backgroundColor)
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
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
                credential = try await AegisConnectKit.shared.authenticate(
                    clientPubKey: clientPubKey,
                    secret: secret,
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




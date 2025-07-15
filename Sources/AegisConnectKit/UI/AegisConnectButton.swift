
#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import UIKit


public struct AegisConnectButton: View {

    private let redirect: Redirect
    private let scheme: String
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
        
        // Auto-detect scheme if not provided
        let resolvedScheme: String? = scheme ?? {
            guard let urlTypes = Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] else {
                return nil
            }
            
            for item in urlTypes {
                if let schemes = item["CFBundleURLSchemes"] as? [String],
                   let first = schemes.first(where: { !$0.isEmpty }) {
                    return first
                }
            }
            return nil
        }()
        
        guard let schemeValue = resolvedScheme else {
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
            successScheme: "\(schemeValue)://x-callback-url/nip46AuthSuccess",
            errorScheme: "\(schemeValue)://x-callback-url/nip46AuthError"
        )
        self.url = url
        self.image = image
        self.title = title
        self.onResult = onResult
        self.name = name
    }

    public var body: some View {
        Button(action: connect) {
            HStack(spacing: 8) {
                if useCustomLogo {
                    Image("aegis_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                } else {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.blue)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(width: 36, height: 36)
                        )
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: true)
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
        VStack(spacing: 20) {
            AegisConnectButton(
                clientPubKey: "preview_client_pubkey",
                secret: "preview_secret"
            )
            .previewDisplayName("Default")
            
            AegisConnectButton(
                clientPubKey: "preview_client_pubkey",
                secret: "preview_secret",
                useCustomLogo: true
            )
            .previewDisplayName("With Logo")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .previewLayout(.sizeThatFits)
    }
}
#endif

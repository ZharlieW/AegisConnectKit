
#if canImport(SwiftUI) && os(iOS)
import SwiftUI
import UIKit


public struct AegisConnectButton: View {

    private let redirect: Redirect
    private let scheme: String
    private let nostrconnectUrl: String?
    private let title: String
    private let onResult: (Result<Credential, Error>) -> Void


    public init(
        scheme: String? = nil,
        nostrconnectUrl: String? = nil,
        title: String = "Connect with Aegis",
        onResult: @escaping (Result<Credential, Error>) -> Void = { _ in }
    ) {
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
            self.nostrconnectUrl = nostrconnectUrl
            self.title = title
            self.onResult = onResult
            return
        }
        self.scheme = schemeValue
        self.redirect = Redirect(
            source: schemeValue,
            successScheme: "\(schemeValue)://x-callback-url/nip46AuthSuccess",
            errorScheme:   "\(schemeValue)://x-callback-url/nip46AuthError"
        )
        self.nostrconnectUrl = nostrconnectUrl
        self.title     = title
        self.onResult  = onResult
    }

   
    public init(
        relays: [String] = ["wss://relay.nsec.app"],
        scheme: String,
        title: String = "Connect with Aegis",
        onResult: @escaping (Result<Credential, Error>) -> Void = { _ in }
    ) {
        let (uri, _, _, _) = NIP46Builder.createNostrConnectURI(relays: relays)
        self.init(scheme: scheme, nostrconnectUrl: uri, title: title, onResult: onResult)
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
                credential = try await AegisConnectKit.shared.connect(
                    redirect: redirect,
                    name: nostrconnectUrl, 
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
            AegisConnectButton()
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Default")
            AegisConnectButton()
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
                .padding()
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif

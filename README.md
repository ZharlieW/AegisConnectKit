# AegisConnectKit

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2015.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

SwiftUI component library for quickly integrating Aegis signer URL scheme method.

## 🚀 Quick Integration

### 1. Install Dependencies

In Xcode:
1. Project → **Package Dependencies** → **"+"**
2. Enter: `https://github.com/ZharlieW/AegisConnectKit.git`
3. Choose version rule → **Add Package**

### 2. Configure URL Scheme

**Key Step**: Configure custom URL scheme in `Info.plist` to redirect back from Aegis signer to your app:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourapp</string>
        </array>
    </dict>
</array>
```

### 3. Handle Callbacks

Handle URL callbacks redirected back from Aegis signer:

```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    AegisConnectKit.shared.handleOpenURL(url)
}
```

## 📱 Integration Options

### Option 1: Use Button Component (Recommended)

Click the button to **automatically redirect users to Aegis signer** for authentication:

```swift
import SwiftUI
import AegisConnectKit

AegisConnectButton(
    clientPubKey: "your_client_public_key",
    secret: "your_secret"
) { result in
    switch result {
    case .success(let credential):
        print("✅ Login successful: \(credential)")
        // Get relay and connect
        if let relay = credential.queryParameters["relay"] {
            print("📡 Connecting to relay: \(relay)")
            // Implement your relay connection logic here
        }
    case .failure(let error):
        print("❌ Login failed: \(error)")
    }
}
```

### Option 2: Direct Method Call

**Manually trigger redirection to Aegis signer**:

```swift
func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    guard let url = URLContexts.first?.url else { return }
    AegisConnectKit.shared.handleOpenURL(url)
}
```

## 📚 API Reference

### Direct Authentication Method

```swift
let credential = try await AegisConnectKit.shared.authenticate(
    clientPubKey: "your_client_public_key",
    secret: "your_secret",
    name: "Your App Name",           // Optional
    url: "https://yourapp.com",      // Optional
    image: "https://yourapp.com/icon.png",  // Optional
    scheme: "yourapp"                // Optional, auto-reads from Info.plist
)
```

### Credential Structure

The returned `Credential` contains relay connection information:

```swift
public struct Credential: Codable {
    public let callbackURL: String           // Callback URL path
    public let fullCallbackURL: String       // Complete callback URL
    public let queryParameters: [String: String]  // Relay connection parameters
}
```

**Important**: After authentication, you must use the information in `queryParameters` to connect to the relay and complete the NIP-46 flow.

### Button Component Parameters

```swift
AegisConnectButton(
    // Required parameters
    clientPubKey: String,            // Client public key
    secret: String,                  // Secret key
    
    // Optional parameters
    scheme: String? = nil,           // URL scheme
    url: String = "",                // App URL
    image: String = "",              // App icon URL
    name: String? = nil,             // App name
    title: String = "Connect with Aegis",  // Button title
    useAegisLogo: Bool = false,      // Whether to use Aegis logo
    backgroundColor: Color = .white,  // Background color
    onResult: @escaping (Result<Credential, Error>) -> Void = { _ in }  // Result callback
)
```

## 💡 Examples

### Basic Usage

```swift
AegisConnectButton(
    clientPubKey: "your_client_public_key",
    secret: "your_secret"
) { result in
    handleAuthenticationResult(result)
}

func handleAuthenticationResult(_ result: Result<Credential, Error>) {
    switch result {
    case .success(let credential):
        // Get relay and connect
        if let relay = credential.queryParameters["relay"] {
            print("📡 Connecting to relay: \(relay)")
            // Implement your relay connection logic here
        }
    case .failure(let error):
        print("❌ Authentication failed: \(error)")
    }
}
```

### Custom Styling

```swift
AegisConnectButton(
    clientPubKey: "your_client_public_key",
    secret: "your_secret",
    title: "Use Aegis Logo",
    useAegisLogo: true,
    backgroundColor: .blue
) { result in
    handleResult(result)
}
```

### Direct Method Call

```swift
Button("Connect Aegis") {
    Task {
        do {
            let credential = try await AegisConnectKit.shared.authenticate(
                clientPubKey: "your_client_public_key",
                secret: "your_secret",
                name: "Your App Name"
            )
            print("✅ Login successful: \(credential)")
            // Get relay and connect
            if let relay = credential.queryParameters["relay"] {
                print("📡 Connecting to relay: \(relay)")
                // Implement your relay connection logic here
            }
        } catch {
            print("❌ Login failed: \(error)")
        }
    }
}
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.


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


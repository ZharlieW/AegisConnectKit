#if os(iOS)
import UIKit

extension UIWindowScene {
    /// Returns the first key window inside the scene.
    var keyWindow: UIWindow? {
        return windows.first(where: { $0.isKeyWindow })
    }
}
#endif 
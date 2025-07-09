#if os(iOS)
import Foundation

enum Logger {
    static func debug(_ message: @autoclosure () -> String) {
        #if DEBUG
        print("[AegisConnectKit] \(message())")
        #endif
    }
}
#endif 
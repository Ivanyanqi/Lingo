import Foundation
import ServiceManagement

/// 管理开机自启动，基于 SMAppService（macOS 13+）
final class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()

    @Published var isEnabled: Bool = false

    private init() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func toggle() {
        isEnabled ? disable() : enable()
    }

    func enable() {
        do {
            try SMAppService.mainApp.register()
            isEnabled = true
        } catch {
            isEnabled = false
        }
    }

    func disable() {
        do {
            try SMAppService.mainApp.unregister()
            isEnabled = false
        } catch {
            // 即使失败也更新状态
            isEnabled = SMAppService.mainApp.status == .enabled
        }
    }
}

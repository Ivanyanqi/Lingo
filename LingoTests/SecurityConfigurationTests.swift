import XCTest

final class SecurityConfigurationTests: XCTestCase {
    func test_projectDisablesAppShortcutsFlexibleMatching() throws {
        let projectText = try loadProjectFile()

        XCTAssertTrue(projectText.contains("APP_SHORTCUTS_ENABLE_FLEXIBLE_MATCHING = NO;"))
    }

    func test_entitlements_enableSandboxNetworkAndUserSelectedWriteAccess() throws {
        let entitlements = try loadPlist(atRelativePath: "Lingo/Lingo.entitlements")

        XCTAssertEqual(entitlements["com.apple.security.app-sandbox"] as? Bool, true)
        XCTAssertEqual(entitlements["com.apple.security.network.client"] as? Bool, true)
        XCTAssertEqual(entitlements["com.apple.security.files.user-selected.read-write"] as? Bool, true)
    }

    func test_containerMigrationManifest_movesLegacyApplicationSupportDirectory() throws {
        let manifest = try loadPlist(atRelativePath: "Lingo/container-migration.plist")
        let moveEntries = try XCTUnwrap(manifest["Move"] as? [Any])

        XCTAssertTrue(
            moveEntries.contains { entry in
                (entry as? String) == "${ApplicationSupport}/Lingo"
            }
        )
    }

    func test_containerMigrationManifest_isBundledInMainApp() {
        XCTAssertNotNil(Bundle.main.url(forResource: "container-migration", withExtension: "plist"))
    }

    private func loadPlist(atRelativePath relativePath: String) throws -> [String: Any] {
        let sourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = sourceRoot.appendingPathComponent(relativePath)
        let data = try Data(contentsOf: url)
        let plist = try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        )
        return plist
    }

    private func loadProjectFile() throws -> String {
        let sourceRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = sourceRoot.appendingPathComponent("Lingo.xcodeproj/project.pbxproj")
        return try String(contentsOf: url, encoding: .utf8)
    }
}

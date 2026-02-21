import Foundation

/// Codable settings persisted in UserDefaults.
struct TeleprompterSettings: Codable {

    /// Bump this when field names change so old data can be migrated safely.
    var settingsVersion: Int = 1

    var fontSize: Double = 32
    var backgroundOpacity: Double = 0.75
    var scrollSpeed: Double = 50
    var textColorRed: Double   = 1.0
    var textColorGreen: Double = 1.0
    var textColorBlue: Double  = 1.0
    var textColorAlpha: Double = 1.0

    // Window geometry — applied only when windowPositionSaved == true
    var windowX: Double = 0
    var windowY: Double = 0
    var windowWidth: Double  = 620
    var windowHeight: Double = 280
    var windowPositionSaved: Bool = false

    private static let key = "TeleprompterSettings"

    static func load() -> TeleprompterSettings {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode(TeleprompterSettings.self, from: data)
        else { return TeleprompterSettings() }
        return decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.key)
    }
}

import Foundation

@MainActor
enum FileLoader {

    /// Reads a user-selected file (UTF-8) and writes content into the view model.
    /// Returns a localised error string on failure so the caller can surface it
    /// as an alert — errors are NEVER written into rawText.
    @discardableResult
    static func load(url: URL, into viewModel: TeleprompterViewModel) -> String? {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        do {
            let text = try String(contentsOf: url, encoding: .utf8)
            viewModel.rawText        = text
            viewModel.isLoaded       = true
            viewModel.loadedFileName = url.lastPathComponent
            viewModel.scrollOffset   = 0
            viewModel.isPlaying      = false
            return nil   // success
        } catch {
            return error.localizedDescription   // caller shows an alert
        }
    }
}

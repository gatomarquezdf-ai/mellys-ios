import Foundation

/// Dirección de la app publicada en HTTPS (Netlify, Cloudflare Pages, etc.).
/// Se guarda en el dispositivo para que el contenedor nativo abra siempre la
/// misma instalación y conserve los datos de IndexedDB de ese origen.
enum AppConfig {
    static let storageKey = "melys.app.url"

    /// Dirección publicada que se propone la primera vez que se abre la app.
    /// Déjala vacía para escribirla a mano, o escribe aquí tu URL de Netlify
    /// (por ejemplo "https://melys.netlify.app") antes de compilar.
    static let suggestedURL = ""

    static var appURL: URL? {
        get { normalize(UserDefaults.standard.string(forKey: storageKey) ?? "") }
        set {
            if let url = newValue {
                UserDefaults.standard.set(url.absoluteString, forKey: storageKey)
            } else {
                UserDefaults.standard.removeObject(forKey: storageKey)
            }
        }
    }

    /// Acepta "melys.netlify.app" o "https://melys.netlify.app" y devuelve
    /// siempre una URL con host válido.
    static func normalize(_ raw: String) -> URL? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return nil }
        if !text.lowercased().hasPrefix("http://") && !text.lowercased().hasPrefix("https://") {
            text = "https://" + text
        }
        guard let url = URL(string: text),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host,
              !host.isEmpty else {
            return nil
        }
        return url
    }
}

import SwiftUI
import WebKit
import UIKit

/* MARK: - Modelo */

final class WebViewModel: ObservableObject {
    @Published var url: URL?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var reloadToken = 0

    init() {
        url = AppConfig.appURL
    }

    func start() {
        if url == nil { url = AppConfig.appURL }
    }

    func save(_ url: URL) {
        AppConfig.appURL = url
        self.url = url
        errorMessage = nil
        isLoading = true
        reloadToken += 1
    }

    func clear() {
        AppConfig.appURL = nil
        url = nil
        errorMessage = nil
        isLoading = false
    }

    func retry() {
        errorMessage = nil
        isLoading = true
        reloadToken += 1
    }
}

/* MARK: - Contenedor WKWebView */

struct WebView: UIViewRepresentable {
    @ObservedObject var model: WebViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.websiteDataStore = .default()

        let controller = WKUserContentController()
        controller.addUserScript(
            WKUserScript(
                source: WebView.bridgeScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
        )
        controller.add(context.coordinator, name: "melys")
        configuration.userContentController = controller

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.keyboardDismissMode = .interactive
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        context.coordinator.webView = webView
        context.coordinator.installRefreshControl()

        if let url = model.url {
            context.coordinator.loadedURL = url
            context.coordinator.loadedToken = model.reloadToken
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.model = model
        guard let url = model.url else { return }
        if context.coordinator.loadedURL != url || context.coordinator.loadedToken != model.reloadToken {
            context.coordinator.loadedURL = url
            context.coordinator.loadedToken = model.reloadToken
            webView.load(URLRequest(url: url))
        }
    }

    /// Puente para que la app web use las descargas y la impresión de iOS.
    static let bridgeScript = """
    (function () {
      if (window.MelysIOS) { return; }
      window.MelysIOS = {
        platform: 'ios',
        saveFile: function (name, base64, mime) {
          try {
            window.webkit.messageHandlers.melys.postMessage({
              type: 'saveFile',
              name: name || 'archivo',
              base64: base64 || '',
              mime: mime || 'application/octet-stream'
            });
          } catch (e) {}
        },
        printPage: function () {
          try {
            window.webkit.messageHandlers.melys.postMessage({ type: 'print' });
          } catch (e) {}
        }
      };
    })();
    """

    /* MARK: - Coordinador */

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate,
                            WKScriptMessageHandler, WKDownloadDelegate {
        var model: WebViewModel
        weak var webView: WKWebView?
        var loadedURL: URL?
        var loadedToken = 0
        private var destinations: [ObjectIdentifier: URL] = [:]

        init(model: WebViewModel) {
            self.model = model
        }

        func installRefreshControl() {
            guard let webView else { return }
            let refresh = UIRefreshControl()
            refresh.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
            webView.scrollView.refreshControl = refresh
        }

        @objc private func pullToRefresh() {
            webView?.reload()
        }

        /* MARK: Navegación */

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.model.isLoading = true
                self.model.errorMessage = nil
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.model.isLoading = false
                webView.scrollView.refreshControl?.endRefreshing()
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.reload()
        }

        private func handle(_ error: Error) {
            let ns = error as NSError
            if ns.domain == NSURLErrorDomain && ns.code == NSURLErrorCancelled { return }
            DispatchQueue.main.async {
                self.model.isLoading = false
                self.webView?.scrollView.refreshControl?.endRefreshing()
                self.model.errorMessage = "Revisa la conexión a internet y que la dirección esté publicada con HTTPS."
            }
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            if navigationAction.shouldPerformDownload {
                decisionHandler(.download)
                return
            }

            let scheme = url.scheme?.lowercased() ?? ""
            if scheme == "about" || scheme == "data" || scheme == "blob" || scheme == "javascript" {
                decisionHandler(.allow)
                return
            }

            if scheme != "http" && scheme != "https" {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            if let host = model.url?.host, url.host != host {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationResponse: WKNavigationResponse,
                     decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if !navigationResponse.canShowMimeType {
                decisionHandler(.download)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
            download.delegate = self
        }

        func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
            download.delegate = self
        }

        /* MARK: Descargas */

        func download(_ download: WKDownload,
                      decideDestinationUsing response: URLResponse,
                      suggestedFilename: String,
                      completionHandler: @escaping (URL?) -> Void) {
            let folder = FileManager.default.temporaryDirectory
                .appendingPathComponent("melys-\(UUID().uuidString)", isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            } catch {
                completionHandler(nil)
                return
            }
            let file = folder.appendingPathComponent(Coordinator.safeFileName(suggestedFilename))
            destinations[ObjectIdentifier(download)] = file
            completionHandler(file)
        }

        func downloadDidFinish(_ download: WKDownload) {
            guard let file = destinations.removeValue(forKey: ObjectIdentifier(download)) else { return }
            Coordinator.presentShareSheet(items: [file])
        }

        func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
            destinations.removeValue(forKey: ObjectIdentifier(download))
            Coordinator.presentAlert(title: "Descarga", message: "No se pudo descargar el archivo.")
        }

        /* MARK: Puente de la app web */

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard message.name == "melys",
                  let body = message.body as? [String: Any],
                  let type = body["type"] as? String else { return }

            switch type {
            case "saveFile":
                let name = Coordinator.safeFileName(body["name"] as? String ?? "archivo")
                guard let base64 = body["base64"] as? String,
                      let data = Data(base64Encoded: base64) else {
                    Coordinator.presentAlert(title: "Archivo", message: "El archivo llegó vacío. Intenta de nuevo.")
                    return
                }
                let folder = FileManager.default.temporaryDirectory
                    .appendingPathComponent("melys-\(UUID().uuidString)", isDirectory: true)
                do {
                    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                    let file = folder.appendingPathComponent(name)
                    try data.write(to: file, options: .atomic)
                    Coordinator.presentShareSheet(items: [file])
                } catch {
                    Coordinator.presentAlert(title: "Archivo", message: "No se pudo guardar el archivo.")
                }
            case "print":
                printPage()
            default:
                break
            }
        }

        /* MARK: Impresión */

        private func printPage() {
            guard let webView else { return }
            let info = UIPrintInfo.printInfo()
            info.outputType = .general
            info.jobName = "Distribuidora Mely's"
            let controller = UIPrintInteractionController.shared
            controller.printInfo = info
            controller.printFormatter = webView.viewPrintFormatter()
            DispatchQueue.main.async {
                if let top = Coordinator.topViewController() {
                    controller.present(from: top.view.bounds,
                                       in: top.view,
                                       animated: true,
                                       completionHandler: nil)
                } else {
                    controller.present(animated: true, completionHandler: nil)
                }
            }
        }

        /* MARK: Diálogos del navegador */

        func webView(_ webView: WKWebView,
                     runJavaScriptAlertPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo,
                     completionHandler: @escaping () -> Void) {
            guard let top = Coordinator.topViewController() else {
                completionHandler()
                return
            }
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Aceptar", style: .default) { _ in completionHandler() })
            top.present(alert, animated: true)
        }

        func webView(_ webView: WKWebView,
                     runJavaScriptConfirmPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo,
                     completionHandler: @escaping (Bool) -> Void) {
            guard let top = Coordinator.topViewController() else {
                completionHandler(false)
                return
            }
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "Aceptar", style: .default) { _ in completionHandler(true) })
            top.present(alert, animated: true)
        }

        func webView(_ webView: WKWebView,
                     runJavaScriptTextInputPanelWithPrompt prompt: String,
                     defaultText: String?,
                     initiatedByFrame frame: WKFrameInfo,
                     completionHandler: @escaping (String?) -> Void) {
            guard let top = Coordinator.topViewController() else {
                completionHandler(nil)
                return
            }
            let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
            alert.addTextField { field in field.text = defaultText }
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel) { _ in completionHandler(nil) })
            alert.addAction(UIAlertAction(title: "Aceptar", style: .default) { _ in
                completionHandler(alert.textFields?.first?.text)
            })
            top.present(alert, animated: true)
        }

        func webView(_ webView: WKWebView,
                     createWebViewWith configuration: WKWebViewConfiguration,
                     for navigationAction: WKNavigationAction,
                     windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }

        /* MARK: Utilidades de presentación */

        static func presentShareSheet(items: [Any]) {
            DispatchQueue.main.async {
                guard let top = topViewController() else { return }
                let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
                if let popover = controller.popoverPresentationController {
                    popover.sourceView = top.view
                    popover.sourceRect = CGRect(x: top.view.bounds.midX,
                                                y: top.view.bounds.midY,
                                                width: 0,
                                                height: 0)
                    popover.permittedArrowDirections = []
                }
                top.present(controller, animated: true)
            }
        }

        static func presentAlert(title: String, message: String) {
            DispatchQueue.main.async {
                guard let top = topViewController() else { return }
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Aceptar", style: .default))
                top.present(alert, animated: true)
            }
        }

        static func topViewController(_ base: UIViewController? = nil) -> UIViewController? {
            let root: UIViewController?
            if let base = base {
                root = base
            } else {
                root = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first(where: { $0.isKeyWindow })?
                    .rootViewController
            }
            if let navigation = root as? UINavigationController {
                return topViewController(navigation.visibleViewController)
            }
            if let tab = root as? UITabBarController {
                return topViewController(tab.selectedViewController)
            }
            if let presented = root?.presentedViewController {
                return topViewController(presented)
            }
            return root
        }

        static func safeFileName(_ raw: String) -> String {
            let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|")
            var name = raw
                .components(separatedBy: invalid)
                .joined(separator: "-")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if name.isEmpty { name = "archivo" }
            if name.count > 120 { name = String(name.prefix(120)) }
            return name
        }
    }
}

import SwiftUI

struct ContentView: View {
    @StateObject private var model = WebViewModel()
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(red: 0.96, green: 0.965, blue: 0.98)
                .ignoresSafeArea()

            if model.url == nil {
                SetupView(model: model)
            } else {
                WebView(model: model)
                    .ignoresSafeArea(edges: .bottom)

                if model.isLoading && model.errorMessage == nil {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.indigo)
                        .scaleEffect(1.15)
                }

                if let message = model.errorMessage {
                    ErrorOverlay(
                        message: message,
                        retry: { model.retry() },
                        changeURL: { model.clear() }
                    )
                }

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(9)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .padding(.trailing, 10)
                .padding(.bottom, 10)
                .opacity(0.6)
                .accessibilityLabel("Ajustes de la app")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(model: model)
        }
        .onAppear { model.start() }
    }
}

/* MARK: - Primera configuración */

struct SetupView: View {
    @ObservedObject var model: WebViewModel
    @State private var text = AppConfig.suggestedURL
    @State private var error: String?
    @State private var showHelp = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LinearGradient(colors: [Color(red: 0.31, green: 0.27, blue: 0.90),
                                                          Color(red: 0.49, green: 0.23, blue: 0.93)],
                                                 startPoint: .topLeading,
                                                 endPoint: .bottomTrailing))
                            .frame(width: 62, height: 62)
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Distribuidora Mely's")
                            .font(.title2.bold())
                        Text("App para iPhone y iPad")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 24)

                Text("Conecta tu catálogo")
                    .font(.headline)

                Text("Pega la dirección HTTPS donde publicaste la carpeta **dist/web** (Netlify, Cloudflare Pages o tu hosting). La app abrirá tu catálogo, inventario y pedidos, y guardará los datos en este dispositivo.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Dirección de la app")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextField("https://melys.netlify.app", text: $text)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.URL)
                        .padding(14)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color.black.opacity(0.10), lineWidth: 1)
                        )
                        .onSubmit(open)
                    if let error {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Button(action: open) {
                    Text("Abrir la app")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.31, green: 0.27, blue: 0.90),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .foregroundStyle(.white)
                }

                DisclosureGroup("¿Cómo publico la app?", isExpanded: $showHelp) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. En el computador ejecuta **tools\\build-web.ps1**.")
                        Text("2. Entra a **app.netlify.com/drop** y arrastra **dist\\DistribuidoraMelys-web.zip**.")
                        Text("3. Copia la dirección HTTPS que te entrega el servicio.")
                        Text("4. Pega esa dirección arriba y toca **Abrir la app**.")
                        Text("La primera vez debes iniciar sesión con tu usuario de administradora o vendedor.")
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                }
                .padding(14)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text("Si aún no tienes una dirección publicada, también puedes abrir la versión web en Safari y usar **Compartir → Añadir a pantalla de inicio**.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 28)
            }
            .padding(.horizontal, 22)
        }
        .background(Color(red: 0.96, green: 0.965, blue: 0.98).ignoresSafeArea())
    }

    private func open() {
        guard let url = AppConfig.normalize(text) else {
            error = "Escribe una dirección válida, por ejemplo https://melys.netlify.app"
            return
        }
        error = nil
        model.save(url)
    }
}

/* MARK: - Ajustes */

struct SettingsView: View {
    @ObservedObject var model: WebViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var error: String?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Dirección de la app")) {
                    TextField("https://…", text: $text)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if let error {
                        Text(error).foregroundStyle(.red)
                    }
                }

                Section {
                    Button("Guardar y recargar") {
                        guard let url = AppConfig.normalize(text) else {
                            error = "La dirección no es válida."
                            return
                        }
                        error = nil
                        model.save(url)
                        dismiss()
                    }
                    Button("Quitar dirección", role: .destructive) {
                        model.clear()
                        dismiss()
                    }
                }

                Section(header: Text("Ayuda")) {
                    Text("La dirección debe empezar con https:// y ser la misma que abres en Safari. Cambiarla cambia también el origen de los datos guardados en el teléfono.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear { text = model.url?.absoluteString ?? "" }
    }
}

/* MARK: - Error de carga */

struct ErrorOverlay: View {
    let message: String
    let retry: () -> Void
    let changeURL: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.orange)
            Text("No se pudo abrir la app")
                .font(.headline)
            Text(message)
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                Button("Reintentar", action: retry)
                    .buttonStyle(.borderedProminent)
                Button("Cambiar dirección", action: changeURL)
                    .buttonStyle(.bordered)
            }
        }
        .padding(22)
        .frame(maxWidth: 330)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(24)
    }
}

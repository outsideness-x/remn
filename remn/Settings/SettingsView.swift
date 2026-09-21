import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("desiredRetention") private var desiredRetention = 0.90
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue

    @State private var exportDocument = BackupDocument()
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var resultMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            RemnNavigationHeader(title: "settings")
            ScrollView {
                VStack(alignment: .leading, spacing: 38) {
                    settingsSection("settings.study") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("settings.retention")
                                Spacer()
                                Text(desiredRetention, format: .percent.precision(.fractionLength(0)))
                                    .monospacedDigit()
                            }
                            Slider(value: $desiredRetention, in: 0.70...0.97, step: 0.01)
                            Text("settings.retention.help")
                                .font(.footnote)
                                .foregroundStyle(Color.remnGraphite)
                        }
                    }
                    settingsSection("settings.appearance") {
                        HStack(spacing: 24) {
                            appearanceChoice(.system, title: "appearance.system")
                            appearanceChoice(.light, title: "appearance.light")
                            appearanceChoice(.dark, title: "appearance.dark")
                        }
                    }
                    settingsSection("settings.data") {
                        VStack(spacing: 2) {
                            settingsButton("backup.export", systemImage: "arrow.up.doc", action: exportBackup)
                            ScribbleDivider(seed: 112)
                            settingsButton("backup.import", systemImage: "arrow.down.doc") {
                                showImporter = true
                            }
                        }
                    }
                    settingsSection("settings.about") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("remn")
                                .font(RemnTypography.display(25, weight: .medium, relativeTo: .title2))
                            Text(versionText)
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(Color.remnGraphite)
                            Text("about.openSource")
                            Text("MIT")
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color.remnPaper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: backupFilename
        ) { result in
            if case .failure(let error) = result { resultMessage = error.localizedDescription }
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            importBackup(result)
        }
        .alert(
            "backup.result",
            isPresented: Binding(
                get: { resultMessage != nil },
                set: { if !$0 { resultMessage = nil } }
            )
        ) {
            Button("ok", role: .cancel) { resultMessage = nil }
        } message: { Text(resultMessage ?? "") }
    }

    private func settingsSection<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(RemnTypography.display(22, weight: .medium, relativeTo: .title3))
            content()
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func appearanceChoice(_ mode: AppearanceMode, title: LocalizedStringKey) -> some View {
        Button { appearanceMode = mode.rawValue } label: {
            VStack(spacing: 7) {
                Text(title)
                    .font(RemnTypography.smallControl)
                    .foregroundStyle(appearanceMode == mode.rawValue ? Color.remnInk : Color.remnGraphite)
                Capsule()
                    .fill(appearanceMode == mode.rawValue ? Color.remnAccent : Color.clear)
                    .frame(height: 1.5)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func settingsButton(
        _ title: LocalizedStringKey,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage).frame(width: 28)
                Text(title)
                Spacer()
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(RemnLanguage.localized("about.version")) \(version) (\(build))"
    }

    private var backupFilename: String {
        let date = Date.now.formatted(.iso8601.year().month().day())
        return "remn-backup-\(date)"
    }

    private func exportBackup() {
        do {
            let data = try BackupService.export(
                context: context,
                settings: BackupSettings(
                    desiredRetention: desiredRetention,
                    appearanceMode: appearanceMode
                )
            )
            exportDocument = BackupDocument(data: data)
            showExporter = true
        } catch {
            resultMessage = error.localizedDescription
        }
    }

    private func importBackup(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            let archive = try BackupService.decode(Data(contentsOf: url))
            let settings = try BackupService.importArchive(archive, context: context)
            desiredRetention = settings.desiredRetention
            appearanceMode = settings.appearanceMode
            resultMessage = RemnLanguage.localized("backup.imported")
        } catch {
            resultMessage = error.localizedDescription
        }
    }
}

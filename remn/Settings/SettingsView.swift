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
    @State private var showSRSExplanation = false
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
                            HandmadeSlider(
                                value: $desiredRetention,
                                range: 0.70...0.97,
                                step: 0.01
                            )
                            Text("settings.retention.help")
                                .font(.footnote)
                                .foregroundStyle(Color.remnGraphite)

                            Button { showSRSExplanation = true } label: {
                                HStack(spacing: 7) {
                                    HandwrittenText("settings.srs.open")
                                        .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                                    Text("→")
                                        .accessibilityHidden(true)
                                }
                                .font(RemnTypography.smallControl)
                                .foregroundStyle(Color.remnAccent)
                                .padding(.top, 4)
                            }
                            .buttonStyle(.plain)
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
                            settingsButton("backup.export", icon: .upload, action: exportBackup)
                            ScribbleDivider(seed: 112)
                            settingsButton("backup.import", icon: .download) {
                                showImporter = true
                            }
                        }
                    }
                    settingsSection("settings.about") {
                        aboutPanel
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
        .handmadeDialog(
            isPresented: Binding(
                get: { resultMessage != nil },
                set: { if !$0 { resultMessage = nil } }
            ),
            title: "backup.result",
            message: Text(verbatim: resultMessage ?? ""),
            actions: [
                HandmadeDialogAction("ok") { resultMessage = nil }
            ]
        )
        .sheet(isPresented: $showSRSExplanation) {
            SRSExplainerSheet()
        }
    }

    private func settingsSection<Content: View>(
        _ title: LocalizedStringKey,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HandwrittenText(title)
                .font(RemnTypography.display(22, weight: .medium, relativeTo: .title3))
                .remnHandwrittenBounds()
            content()
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func appearanceChoice(_ mode: AppearanceMode, title: LocalizedStringKey) -> some View {
        Button { appearanceMode = mode.rawValue } label: {
            VStack(spacing: 7) {
                HandwrittenText(title)
                    .font(RemnTypography.smallControl)
                    .remnHandwrittenBounds(horizontal: 2, vertical: 1)
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
        icon: DoodleIconKind,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                DoodleIcon(kind: icon, color: .remnInk, size: 22)
                    .frame(width: 28)
                Text(title)
                Spacer()
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var aboutPanel: some View {
        FlashcardSurface(seed: 734, style: .compact) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    HandwrittenText("remn")
                        .font(RemnTypography.display(34, weight: .medium, relativeTo: .title))
                        .remnHandwrittenBounds()
                        .foregroundStyle(Color.remnAccent)
                    Spacer()
                    StackedCardsDoodle()
                        .scaleEffect(0.72)
                        .frame(width: 44, height: 38)
                }

                HandwrittenText("about.tagline")
                    .font(RemnTypography.display(20, relativeTo: .body))
                    .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                    .foregroundStyle(Color.remnInk)
                    .fixedSize(horizontal: false, vertical: true)

                ScribbleDivider(seed: 735)

                HStack(alignment: .center, spacing: 14) {
                    VStack(alignment: .leading, spacing: 2) {
                        HandwrittenText("about.openSource")
                            .font(RemnTypography.smallControl)
                            .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                            .foregroundStyle(Color.remnGraphite)
                        HandwrittenText(verbatim: versionText)
                            .font(RemnTypography.display(15, relativeTo: .caption))
                            .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                            .foregroundStyle(Color.remnGraphite)
                    }
                    Spacer()
                    HandwrittenText(verbatim: "MIT")
                        .font(RemnTypography.display(25, weight: .semibold, relativeTo: .title3))
                        .remnHandwrittenBounds()
                        .foregroundStyle(Color.remnAccent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background {
                            WobblyRoundedRectangle(seed: 738, cornerRadius: 7)
                                .fill(Color.remnAccent.opacity(0.08))
                        }
                        .overlay {
                            WobblyRoundedRectangle(seed: 738, cornerRadius: 7)
                                .stroke(Color.remnAccent, lineWidth: 1.2)
                        }
                        .rotationEffect(.degrees(-2.2))
                        .accessibilityLabel(Text("about.mit"))
                }

                HandwrittenText("about.ownership")
                    .font(RemnTypography.display(16, relativeTo: .footnote))
                    .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                    .foregroundStyle(Color.remnGraphite)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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

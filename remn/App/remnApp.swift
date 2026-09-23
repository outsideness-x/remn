import SwiftData
import SwiftUI

@main
struct remnApp: App {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    private let container: ModelContainer?
    private let startupError: String?

    init() {
        do {
            let schema = Schema(versionedSchema: RemnSchemaV1.self)
            let configuration = ModelConfiguration("remn", schema: schema)
            container = try ModelContainer(
                for: schema,
                migrationPlan: RemnMigrationPlan.self,
                configurations: [configuration]
            )
            startupError = nil
        } catch {
            container = nil
            startupError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                if ProcessInfo.processInfo.arguments.contains("-inkLab") {
                    InkLab()
                } else {
                    content
                }
                #else
                content
                #endif
            }
            .preferredColorScheme(AppearanceMode(rawValue: appearanceMode)?.colorScheme)
            .environment(\.locale, RemnLanguage.locale)
            .tint(.remnAccent)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let container {
            RootView()
                .modelContainer(container)
        } else {
            StartupFailureView(message: startupError ?? "storage.error")
        }
    }
}

private struct StartupFailureView: View {
    let message: String

    var body: some View {
        VStack(spacing: 18) {
            HandwrittenText("remn")
                .font(RemnTypography.brand)
                .remnHandwrittenBounds()
            HandwrittenText("storage.couldNotOpen")
                .font(RemnTypography.navigationTitle)
                .remnHandwrittenBounds()
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.remnPaper)
    }
}

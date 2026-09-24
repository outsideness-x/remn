import SwiftData
import SwiftUI

@main
struct remnApp: App {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system.rawValue
    private let container: ModelContainer?
    private let startupError: String?

    init() {
        do {
            #if DEBUG
            if DemoLibrary.isRequested {
                container = try DemoLibrary.makeContainer()
                startupError = nil
                return
            }
            #endif
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
            .tint(.remnAccent)
            #if os(macOS)
            .frame(minWidth: 760, minHeight: 540)
            .toolbar(.hidden, for: .windowToolbar)
            #endif
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1120, height: 780)
        .windowBackgroundDragBehavior(.enabled)
        #endif
        .commands { RemnCommands() }

        #if os(macOS)
        Settings {
            Group {
                if let container {
                    SettingsView()
                        .environment(\.remnIsNavigationRoot, true)
                        .modelContainer(container)
                } else {
                    StartupFailureView(message: startupError ?? String(localized: "storage.error"))
                }
            }
            .frame(width: 540, height: 720)
            .preferredColorScheme(AppearanceMode(rawValue: appearanceMode)?.colorScheme)
            .tint(.remnAccent)
        }
        .windowResizability(.contentSize)
        #endif
    }

    @ViewBuilder
    private var content: some View {
        if let container {
            RootView()
                .modelContainer(container)
        } else {
            StartupFailureView(message: startupError ?? String(localized: "storage.error"))
        }
    }
}

private struct StartupFailureView: View {
    let message: String

    var body: some View {
        VStack(spacing: 20) {
            StackedCardsDoodle(width: 84)
            HandwrittenText("storage.couldNotOpen", weight: 0.6)
                .font(RemnTypography.sectionTitle)
                .foregroundStyle(Color.remnInk)
                .multilineTextAlignment(.center)
            Text(message)
                .font(.footnote)
                .foregroundStyle(Color.remnGraphite)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .paperBackground()
    }
}

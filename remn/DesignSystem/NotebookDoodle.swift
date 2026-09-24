import SwiftUI

/// A spiral notebook, drawn in the same pen as the stacked cards: the mark for notes.
struct NotebookDoodle: View {
    var ink: Color = .remnInk
    var accent: Color = .remnAccent
    var paper: Color = .remnCardPaper
    var width: CGFloat = 58

    var body: some View {
        let height = width * 1.12
        let scale = max(width / 58, 0.45)
        let pen = InkPen.pen.scaled(by: scale)
        let hairline = InkPen.hairline.scaled(by: max(scale, 0.7))
        ZStack(alignment: .topLeading) {
            InkPatch(seed: 6_101, cornerRadius: width * 0.08)
                .fill(paper)
            // Ruling, and the red margin a notebook page has.
            ForEach(0..<4, id: \.self) { line in
                InkLine(seed: 6_110 + line, pen: hairline)
                    .fill(ink.opacity(0.45))
                    .frame(width: width * 0.56, height: 4)
                    .offset(x: width * 0.3, y: height * (0.26 + CGFloat(line) * 0.17))
            }
            InkLine(seed: 6_120, pen: hairline, vertical: true)
                .fill(accent)
                .frame(width: 4, height: height * 0.86)
                .offset(x: width * 0.22, y: height * 0.07)
            InkRoundedRect(seed: 6_101, cornerRadius: width * 0.08, pen: pen)
                .ink(ink)
            // Rings through the spine.
            ForEach(0..<4, id: \.self) { ring in
                InkEllipse(seed: 6_130 + ring, pen: pen)
                    .fill(ink)
                    .frame(width: width * 0.2, height: width * 0.11)
                    .offset(x: -width * 0.08, y: height * (0.14 + CGFloat(ring) * 0.22))
            }
        }
        .frame(width: width, height: height)
        .accessibilityHidden(true)
    }
}

/// What the app is showing: flashcards or notes.
enum AppSection: String, CaseIterable, Identifiable {
    case cards
    case notes

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .cards: "section.cards"
        case .notes: "section.notes"
        }
    }
}

/// The bottom of the iPhone screen: two words and their drawings; the one you're on is underlined in red pencil.
struct RemnTabBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var selection: AppSection

    var body: some View {
        VStack(spacing: 0) {
            InkLine(seed: 7_210, pen: .hairline)
                .fill(Color.remnInk.opacity(0.22))
                .frame(height: 6)
                .padding(.horizontal, 14)
            HStack(spacing: 0) {
                ForEach(AppSection.allCases) { section in
                    item(section)
                }
            }
            .padding(.top, 2)
        }
        .background(alignment: .bottom) { PaperBackground() }
        .sensoryFeedback(.selection, trigger: selection)
    }

    private func item(_ section: AppSection) -> some View {
        let chosen = selection == section
        return Button {
            selection = section
        } label: {
            VStack(spacing: 3) {
                Group {
                    switch section {
                    case .cards:
                        StackedCardsDoodle(
                            ink: chosen ? .remnInk : .remnGraphite,
                            accent: chosen ? .remnAccent : .remnGraphite,
                            width: 30
                        )
                    case .notes:
                        NotebookDoodle(
                            ink: chosen ? .remnInk : .remnGraphite,
                            accent: chosen ? .remnAccent : .remnGraphite,
                            width: 21
                        )
                    }
                }
                .frame(height: 25)
                HandwrittenText(section.title, weight: chosen ? 0.4 : 0)
                    .font(RemnTypography.display(15, relativeTo: .caption))
                    .foregroundStyle(chosen ? Color.remnInk : Color.remnGraphite)
                InkUnderline(seed: section == .cards ? 7_221 : 7_222, pen: .fine, progress: chosen ? 1 : 0)
                    .fill(Color.remnAccent)
                    .frame(width: 34, height: 5)
                    .animation(reduceMotion ? nil : .easeOut(duration: chosen ? 0.3 : 0.1), value: chosen)
            }
            .frame(maxWidth: .infinity, minHeight: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(InkPressStyle())
        .accessibilityLabel(Text(section.title))
        .accessibilityAddTraits(chosen ? [.isSelected, .isButton] : .isButton)
    }
}

/// The top of the sidebar on iPad and the Mac: the wordmark, search and settings, and cards or notes.
struct SidebarHeader: View {
    #if os(macOS)
    @Environment(\.openSettings) private var openSettings
    #endif
    @Binding var section: AppSection
    let searchSelected: Bool
    let settingsSelected: Bool
    let onSearch: () -> Void
    let onSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 0) {
                HandwrittenText("remn", weight: 1)
                    .font(RemnTypography.display(38, relativeTo: .largeTitle))
                    .foregroundStyle(Color.remnInk)
                    .accessibilityAddTraits(.isHeader)
                    .inkWritesOn(duration: 0.55)
                Spacer()
                InkIconButton(kind: .search, label: "search", color: searchSelected ? .remnAccent : .remnInk, size: 22) {
                    onSearch()
                }
                InkIconButton(kind: .settings, label: "settings", color: settingsSelected ? .remnAccent : .remnInk, size: 23) {
                    #if os(macOS)
                    openSettings()
                    #else
                    onSettings()
                    #endif
                }
            }
            .padding(.trailing, -10)

            InkChoiceRow(
                selection: $section,
                options: AppSection.allCases.map { .init(value: $0, title: Text($0.title)) },
                seed: 7_300
            )
            .padding(.horizontal, -6)
        }
    }
}

import SwiftData
import SwiftUI

struct StudySetupSheet: View {
    enum CountChoice: String, CaseIterable, Identifiable {
        case ten, twenty, thirty, fifty, allDue, custom
        var id: String { rawValue }

        var value: Int? {
            switch self {
            case .ten: 10
            case .twenty: 20
            case .thirty: 30
            case .fifty: 50
            case .allDue, .custom: nil
            }
        }

        var label: String {
            switch self {
            case .ten: "10"
            case .twenty: "20"
            case .thirty: "30"
            case .fifty: "50"
            case .allDue: RemnLanguage.localized("study.allDue")
            case .custom: RemnLanguage.localized("study.custom")
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query(sort: [SortDescriptor(\SubjectModel.manualSortOrder), SortDescriptor(\SubjectModel.createdAt)])
    private var subjects: [SubjectModel]
    @Query private var cards: [Flashcard]
    @AppStorage("lastSubjectIDs") private var lastSubjectIDs = ""

    let initialSubjectIDs: Set<UUID>
    let initialDeckID: UUID?
    let onStart: (StudySessionRecord) -> Void

    @State private var selectedSubjectIDs: Set<UUID>
    @State private var countChoice = CountChoice.twenty
    @State private var customCount = 20
    @State private var noCards = false

    init(
        initialSubjectIDs: Set<UUID>,
        initialDeckID: UUID?,
        onStart: @escaping (StudySessionRecord) -> Void
    ) {
        self.initialSubjectIDs = initialSubjectIDs
        self.initialDeckID = initialDeckID
        self.onStart = onStart
        _selectedSubjectIDs = State(initialValue: initialSubjectIDs)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button { dismiss() } label: {
                    HandwrittenText("cancel")
                        .remnHandwrittenBounds()
                }
                .frame(minWidth: 64, minHeight: 44, alignment: .leading)
                Spacer()
                HandwrittenText("study.setup")
                    .font(RemnTypography.navigationTitle)
                    .remnHandwrittenBounds()
                    .foregroundStyle(Color.remnInk)
                Spacer()
                Color.clear.frame(width: 64, height: 44)
            }
            .font(RemnTypography.control)
            .foregroundStyle(Color.remnAccent)
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
            .padding(.vertical, 6)

            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    sectionTitle("study.what")
                    subjectsPicker
                    sectionTitle("study.howMany")
                    countPicker
                    TimelineView(.periodic(from: .now, by: 15)) { timeline in
                        sessionSummary(at: timeline.date)
                    }
                    if countChoice == .custom {
                        HStack(spacing: 14) {
                            Button { customCount = max(1, customCount - 1) } label: {
                                DoodleIcon(kind: .minus, color: .remnInk, size: 19)
                                    .frame(width: 44, height: 44)
                                    .background {
                                        WobblyRoundedRectangle(seed: 517, cornerRadius: 10)
                                            .fill(Color.remnSurface)
                                    }
                                    .overlay {
                                        WobblyRoundedRectangle(seed: 517, cornerRadius: 10)
                                            .stroke(Color.remnInk.opacity(0.45), lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                            .disabled(customCount == 1)
                            .accessibilityLabel(Text("decrease"))

                            HandwrittenText(
                                verbatim: RemnLanguage.counted(
                                    customCount,
                                    singular: "library.card",
                                    plural: "library.cards"
                                )
                            )
                            .font(RemnTypography.control)
                            .remnHandwrittenBounds()
                            .frame(maxWidth: .infinity)

                            Button { customCount = min(500, customCount + 1) } label: {
                                DoodleIcon(kind: .plus, color: .remnInk, size: 19)
                                    .frame(width: 44, height: 44)
                                    .background {
                                        WobblyRoundedRectangle(seed: 529, cornerRadius: 10)
                                            .fill(Color.remnSurface)
                                    }
                                    .overlay {
                                        WobblyRoundedRectangle(seed: 529, cornerRadius: 10)
                                            .stroke(Color.remnInk.opacity(0.45), lineWidth: 1)
                                    }
                            }
                            .buttonStyle(.plain)
                            .disabled(customCount == 500)
                            .accessibilityLabel(Text("increase"))
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 116)
            }
            .background(Color.remnPaper.ignoresSafeArea())
        }
        .background(Color.remnPaper.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            Button(action: start) {
                HandwrittenText("study.start")
                    .frame(maxWidth: .infinity)
            }
                .buttonStyle(WobblyButtonStyle(filled: true, seed: 91))
                .disabled(selectedSubjectIDs.isEmpty)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.remnPaper.opacity(0.97))
        }
        .onAppear(perform: restoreSelection)
        .handmadeDialog(
            isPresented: $noCards,
            title: "study.noneAvailable",
            message: Text("study.noneAvailable.message"),
            actions: [HandmadeDialogAction("ok") {}]
        )
    }

    private var subjectsPicker: some View {
        VStack(spacing: 10) {
            ForEach(subjects, id: \.id) { subject in
                Button {
                    if selectedSubjectIDs.contains(subject.id) {
                        selectedSubjectIDs.remove(subject.id)
                    } else {
                        selectedSubjectIDs.insert(subject.id)
                    }
                } label: {
                    HStack {
                        DoodleSelectionMark(selected: selectedSubjectIDs.contains(subject.id))
                        HandwrittenText(verbatim: subject.name)
                            .font(RemnTypography.display(22, weight: .medium, relativeTo: .headline))
                            .remnHandwrittenBounds(horizontal: 3, vertical: 1)
                            .foregroundStyle(Color.remnInk)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Text("\(subject.cards.count)")
                            .font(.caption)
                            .foregroundStyle(Color.remnGraphite)
                    }
                    .frame(minHeight: 44)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 5)
                }
                .buttonStyle(.plain)
                ScribbleDivider(seed: subject.id.hashValue)
            }
        }
    }

    private var countPicker: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 10)], spacing: 10) {
            ForEach(Array(CountChoice.allCases.enumerated()), id: \.element.id) { index, choice in
                Button {
                    countChoice = choice
                } label: {
                    HandwrittenText(verbatim: choice.label)
                        .font(RemnTypography.smallControl)
                        .remnHandwrittenBounds(horizontal: 3, vertical: 1)
                        .foregroundStyle(countChoice == choice ? Color.remnAccent : Color.remnInk)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background {
                            WobblyRoundedRectangle(seed: 310 + index * 19, cornerRadius: 10)
                                .fill(Color.remnSurface.opacity(countChoice == choice ? 1 : 0.36))
                        }
                        .overlay {
                            WobblyRoundedRectangle(seed: 310 + index * 19, cornerRadius: 10)
                                .stroke(
                                    countChoice == choice ? Color.remnAccent : Color.remnInk.opacity(0.36),
                                    lineWidth: countChoice == choice ? 1.5 : 0.9
                                )
                        }
                        .rotationEffect(.degrees(Double(index % 3 - 1) * 0.20))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sectionTitle(_ key: LocalizedStringKey) -> some View {
        HandwrittenText(key)
            .font(RemnTypography.display(23, weight: .medium, relativeTo: .title3))
            .remnHandwrittenBounds()
            .foregroundStyle(Color.remnInk)
    }

    private var targetCount: Int? {
        countChoice == .custom ? customCount : countChoice.value
    }

    private func sessionSummary(at date: Date) -> some View {
        let selectedCount = StudyQueueBuilder.select(
            from: cards,
            subjectIDs: selectedSubjectIDs,
            deckID: initialDeckID,
            targetCount: targetCount,
            now: date
        ).count
        let availability = StudyQueueBuilder.availability(
            from: cards,
            subjectIDs: selectedSubjectIDs,
            deckID: initialDeckID,
            now: date
        )

        return VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 7) {
                HandwrittenText(verbatim: "\(selectedCount)")
                    .font(RemnTypography.display(31, weight: .semibold, relativeTo: .title))
                    .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                    .foregroundStyle(Color.remnAccent)
                HandwrittenText("study.inSession")
                    .font(RemnTypography.control)
                    .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                    .foregroundStyle(Color.remnInk)
                Spacer()
                StackedCardsDoodle()
                    .scaleEffect(0.48)
                    .frame(width: 28, height: 22)
            }
            HStack(spacing: 6) {
                Text("\(availability.availableNow) \(RemnLanguage.localized("study.availableNow"))")
                Text("·")
                Text("\(availability.scheduledLater) \(RemnLanguage.localized("study.scheduledLater"))")
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(Color.remnGraphite)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background {
            WobblyRoundedRectangle(seed: 441, cornerRadius: 9)
                .fill(Color.remnSurface.opacity(0.55))
        }
        .overlay {
            WobblyRoundedRectangle(seed: 441, cornerRadius: 9)
                .stroke(Color.remnInk.opacity(0.38), lineWidth: 1.1)
        }
        .accessibilityElement(children: .combine)
    }

    private func restoreSelection() {
        guard selectedSubjectIDs.isEmpty else { return }
        let saved = Set(
            lastSubjectIDs.split(separator: ",").compactMap { UUID(uuidString: String($0)) }
        )
        let available = Set(subjects.map(\.id))
        selectedSubjectIDs = saved.intersection(available)
        if selectedSubjectIDs.isEmpty, let first = subjects.first {
            selectedSubjectIDs = [first.id]
        }
    }

    private func start() {
        do {
            let session = try SessionService.start(
                cards: cards,
                subjectIDs: selectedSubjectIDs,
                deckID: initialDeckID,
                targetCount: targetCount,
                context: context
            )
            guard let session else { noCards = true; return }
            lastSubjectIDs = selectedSubjectIDs.map(\.uuidString).joined(separator: ",")
            onStart(session)
        } catch {
            appState.errorMessage = error.localizedDescription
        }
    }
}

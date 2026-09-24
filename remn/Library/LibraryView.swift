import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query(sort: [SortDescriptor(\SubjectModel.manualSortOrder), SortDescriptor(\SubjectModel.createdAt)])
    private var subjects: [SubjectModel]
    @Query private var cards: [Flashcard]
    @Query private var sessions: [StudySessionRecord]

    @State private var showCreate = false
    @State private var manageSubject: SubjectModel?
    @State private var renameSubject: SubjectModel?
    @State private var deleteSubject: SubjectModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if subjects.isEmpty {
                    QuietEmptyState(
                        title: "library.empty",
                        actionTitle: "subject.make",
                        action: { showCreate = true }
                    )
                    .padding(.top, 36)
                } else {
                    TimelineView(.everyMinute) { timeline in
                        today(at: timeline.date)
                    }
                    .padding(.top, 2)
                    subjectList
                        .padding(.top, 30)
                    newSubjectButton
                        .padding(.top, 10)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 6)
            .padding(.bottom, 40)
            .remnReadableWidth()
        }
        .paperBackground()
        .remnHidesSystemBar()
        .safeAreaInset(edge: .bottom) {
            if !cards.isEmpty {
                bottomActions
            }
        }
        .sheet(isPresented: $showCreate) {
            NameEditorSheet(title: "subject.new") { name in
                let order = (subjects.map(\.manualSortOrder).max() ?? -1) + 1
                context.insert(SubjectModel(name: name, manualSortOrder: order))
                save()
            }
        }
        .sheet(item: $renameSubject) { subject in
            NameEditorSheet(title: "subject.rename", initialValue: subject.name) { name in
                subject.name = name
                subject.updatedAt = .now
                save()
            }
        }
        .handmadeDialog(
            isPresented: Binding(
                get: { manageSubject != nil },
                set: { if !$0 { manageSubject = nil } }
            ),
            title: "subject",
            message: Text(verbatim: manageSubject?.name ?? ""),
            actions: subjectActions
        )
        .handmadeDialog(
            isPresented: Binding(
                get: { deleteSubject != nil },
                set: { if !$0 { deleteSubject = nil } }
            ),
            title: "subject.delete.title",
            message: Text("subject.delete.message"),
            actions: [
                HandmadeDialogAction("delete", role: .destructive) {
                    if let deleteSubject { context.delete(deleteSubject); save() }
                    deleteSubject = nil
                },
                HandmadeDialogAction("cancel", role: .cancel) { deleteSubject = nil }
            ]
        )
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 0) {
            HandwrittenText("remn", weight: 1)
                .font(RemnTypography.wordmark)
                .foregroundStyle(Color.remnInk)
                .accessibilityAddTraits(.isHeader)
                .inkWritesOn(duration: 0.55)
            Spacer()
            NavigationLink { SearchView() } label: {
                InkIcon(kind: .search, size: 23)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(InkPressStyle())
            .accessibilityLabel(Text("search"))
            NavigationLink { SettingsView() } label: {
                InkIcon(kind: .settings, size: 24)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(InkPressStyle())
            .accessibilityLabel(Text("settings"))
        }
        .padding(.trailing, -10)
    }

    @ViewBuilder
    private func today(at date: Date) -> some View {
        let due = cards.dueTodayCount(now: date)
        let fresh = cards.count { $0.state == .new }
        Group {
            if due > 0 {
                HandwrittenText("home.dueToday \(due)")
            } else if fresh > 0 {
                HandwrittenText("home.newReady \(fresh)")
            } else if let next = cards.map(\.due).filter({ $0 > date }).min() {
                HandwrittenText("home.caughtUp \(next.formatted(.relative(presentation: .named)))")
            } else {
                HandwrittenText("home.noCards")
            }
        }
        .font(RemnTypography.body)
        .foregroundStyle(Color.remnGraphite)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var subjectList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(subjects.enumerated()), id: \.element.id) { index, subject in
                if index > 0 {
                    InkDivider(seed: subject.id.inkSeed)
                }
                HStack(spacing: 0) {
                    NavigationLink {
                        SubjectDetailView(subject: subject)
                    } label: {
                        LibraryRow(
                            title: subject.name,
                            dueCount: subject.cards.dueTodayCount(),
                            totalCount: subject.cards.count
                        )
                    }
                    .buttonStyle(InkRowStyle())

                    InkIconButton(kind: .more, label: "actions", color: .remnGraphite, size: 20) {
                        manageSubject = subject
                    }
                    .padding(.trailing, -10)
                }
            }
        }
    }

    private var newSubjectButton: some View {
        Button { showCreate = true } label: {
            HStack(spacing: 8) {
                InkIcon(kind: .plus, color: .remnAccent, size: 18)
                HandwrittenText("subject.new")
            }
        }
        .buttonStyle(InkButtonStyle(kind: .quiet, seed: 44))
        .padding(.leading, -10)
    }

    private var bottomActions: some View {
        VStack(spacing: 10) {
            if let activeSession {
                Button {
                    appState.presentedSession = activeSession
                } label: {
                    HandwrittenText("study.continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(InkButtonStyle(kind: .secondary, seed: 72))
            }
            Button {
                appState.prepareStudy()
            } label: {
                HStack(spacing: 14) {
                    StackedCardsDoodle(
                        ink: .remnOnAccent,
                        accent: .remnOnAccent,
                        paper: .remnAccent,
                        width: 36
                    )
                    HandwrittenText("study", weight: 0.6)
                    Spacer()
                    InkIcon(kind: .forward, color: .remnOnAccent, size: 22)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(InkButtonStyle(kind: .primary, seed: 8))
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .remnReadableWidth(600)
        .background(alignment: .bottom) { PaperFade() }
    }

    private var activeSession: StudySessionRecord? {
        sessions.filter(\.isActive).max { $0.updatedAt < $1.updatedAt }
    }

    private var subjectActions: [HandmadeDialogAction] {
        guard let subject = manageSubject else { return [] }
        var actions = [
            HandmadeDialogAction("rename", role: .plain) {
                manageSubject = nil
                renameSubject = subject
            }
        ]
        if let index = subjects.firstIndex(where: { $0.id == subject.id }) {
            if index > subjects.startIndex {
                actions.append(
                    HandmadeDialogAction("move.up", role: .plain) {
                        move(subject, by: -1)
                    }
                )
            }
            if index < subjects.index(before: subjects.endIndex) {
                actions.append(
                    HandmadeDialogAction("move.down", role: .plain) {
                        move(subject, by: 1)
                    }
                )
            }
        }
        actions.append(contentsOf: [
            HandmadeDialogAction("delete", role: .destructive) {
                manageSubject = nil
                deleteSubject = subject
            },
            HandmadeDialogAction("cancel", role: .cancel) { manageSubject = nil }
        ])
        return actions
    }

    private func move(_ subject: SubjectModel, by offset: Int) {
        guard let index = subjects.firstIndex(where: { $0.id == subject.id }) else { return }
        let destination = index + offset
        guard subjects.indices.contains(destination) else { return }
        let other = subjects[destination]
        let oldOrder = subject.manualSortOrder
        subject.manualSortOrder = other.manualSortOrder
        other.manualSortOrder = oldOrder
        save()
    }

    private func save() {
        do { try context.save() } catch { appState.errorMessage = error.localizedDescription }
    }
}

/// Paper that fades in behind controls pinned to the bottom of a scrolling page.
struct PaperFade: View {
    var body: some View {
        PaperBackground()
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.28),
                        .init(color: .black, location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
    }
}

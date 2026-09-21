import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @Query(sort: [SortDescriptor(\SubjectModel.manualSortOrder), SortDescriptor(\SubjectModel.createdAt)])
    private var subjects: [SubjectModel]
    @Query private var sessions: [StudySessionRecord]

    @State private var showCreate = false
    @State private var renameSubject: SubjectModel?
    @State private var deleteSubject: SubjectModel?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                if subjects.isEmpty {
                    QuietEmptyState(
                        title: "library.empty",
                        actionTitle: "subject.make",
                        action: { showCreate = true }
                    )
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(subjects, id: \.id) { subject in
                            NavigationLink {
                                SubjectDetailView(subject: subject)
                            } label: {
                                LibraryRow(
                                    title: subject.name,
                                    dueCount: dueCount(subject.cards),
                                    totalCount: subject.cards.count,
                                    seed: subject.id.hashValue
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu { subjectMenu(subject) }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 130)
        }
        .background(Color.remnPaper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) { bottomActions }
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
        .confirmationDialog(
            "subject.delete.title",
            isPresented: Binding(
                get: { deleteSubject != nil },
                set: { if !$0 { deleteSubject = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("delete", role: .destructive) {
                if let deleteSubject { context.delete(deleteSubject); save() }
                deleteSubject = nil
            }
            Button("cancel", role: .cancel) { deleteSubject = nil }
        } message: {
            Text("subject.delete.message")
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("remn")
                .font(RemnTypography.brand)
                .foregroundStyle(Color.remnInk)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            NavigationLink { SearchView() } label: {
                Image(systemName: "magnifyingglass")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("search"))
            NavigationLink { SettingsView() } label: {
                Image(systemName: "gearshape")
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(Text("settings"))
        }
        .foregroundStyle(Color.remnInk)
        .padding(.bottom, 22)
    }

    @ViewBuilder
    private var bottomActions: some View {
        VStack(spacing: 8) {
            if let activeSession = activeSession {
                Button {
                    appState.presentedSession = activeSession
                } label: {
                    Text("study.continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(WobblyButtonStyle(filled: false, seed: 72))
            }
            Button {
                appState.prepareStudy()
            } label: {
                HStack {
                    StackedCardsDoodle().scaleEffect(0.55).frame(width: 34, height: 30)
                    Text("study")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(WobblyButtonStyle(filled: true, seed: 8))
            .disabled(subjects.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Color.remnPaper.opacity(0.97))
        .overlay(alignment: .top) {
            Rectangle().fill(Color.remnInk.opacity(0.08)).frame(height: 0.5)
        }
    }

    private var activeSession: StudySessionRecord? {
        sessions.filter(\.isActive).max { $0.updatedAt < $1.updatedAt }
    }

    @ViewBuilder
    private func subjectMenu(_ subject: SubjectModel) -> some View {
        Button("rename") { renameSubject = subject }
        Button("move.up") { move(subject, by: -1) }
        Button("move.down") { move(subject, by: 1) }
        Divider()
        Button("delete", role: .destructive) { deleteSubject = subject }
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

    private func dueCount(_ cards: [Flashcard]) -> Int {
        let endOfToday = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: .now)) ?? .now
        return cards.count { $0.state != .new && $0.due < endOfToday }
    }

    private func save() {
        do { try context.save() } catch { appState.errorMessage = error.localizedDescription }
    }
}

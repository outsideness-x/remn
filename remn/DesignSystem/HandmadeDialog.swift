import SwiftUI

enum HandmadeDialogRole {
    case normal
    case destructive
    case cancel
}

struct HandmadeDialogAction: Identifiable {
    let id = UUID()
    let title: LocalizedStringKey
    let role: HandmadeDialogRole
    let perform: () -> Void

    init(
        _ title: LocalizedStringKey,
        role: HandmadeDialogRole = .normal,
        perform: @escaping () -> Void
    ) {
        self.title = title
        self.role = role
        self.perform = perform
    }
}

private struct HandmadeDialogModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var isPresented: Bool

    let title: LocalizedStringKey
    let message: Text?
    let actions: [HandmadeDialogAction]

    func body(content: Content) -> some View {
        content
            .overlay {
                if isPresented {
                    ZStack {
                        Color.black.opacity(0.46)
                            .ignoresSafeArea()
                            .contentShape(Rectangle())
                            .onTapGesture { dismiss() }

                        VStack(alignment: .leading, spacing: 18) {
                            HStack(alignment: .top, spacing: 14) {
                                HandwrittenText(title)
                                    .font(RemnTypography.display(29, weight: .semibold, relativeTo: .title2))
                                    .remnHandwrittenBounds()
                                    .foregroundStyle(Color.remnInk)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 6)
                                StackedCardsDoodle()
                                    .scaleEffect(0.48)
                                    .frame(width: 28, height: 24)
                            }

                            if let message {
                                message
                                    .font(.body)
                                    .foregroundStyle(Color.remnInk)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            ScribbleDivider(seed: 913)

                            VStack(spacing: 9) {
                                ForEach(actions) { action in
                                    dialogButton(action)
                                }
                            }
                        }
                        .padding(.horizontal, 22)
                        .padding(.vertical, 20)
                        .background {
                            ZStack {
                                WobblyRoundedRectangle(seed: 822, cornerRadius: 13)
                                    .fill(Color.remnAccent.opacity(0.18))
                                    .offset(x: 3, y: 5)
                                WobblyRoundedRectangle(seed: 771, cornerRadius: 13)
                                    .fill(Color.remnCardPaper)
                            }
                        }
                        .overlay {
                            WobblyRoundedRectangle(seed: 771, cornerRadius: 13)
                                .stroke(Color.remnInk.opacity(0.78), lineWidth: 1.35)
                        }
                        .padding(.horizontal, 30)
                        .frame(maxWidth: 390)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .scale(scale: 0.96).combined(with: .opacity)
                        )
                    }
                    .zIndex(1000)
                }
            }
            .animation(
                reduceMotion ? .easeOut(duration: 0.12) : .spring(duration: 0.28, bounce: 0.12),
                value: isPresented
            )
    }

    private func dialogButton(_ action: HandmadeDialogAction) -> some View {
        Button {
            action.perform()
            dismiss()
        } label: {
            HandwrittenText(action.title)
                .font(RemnTypography.control)
                .remnHandwrittenBounds()
                .foregroundStyle(foreground(for: action.role))
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background {
            if action.role != .cancel {
                WobblyRoundedRectangle(seed: action.role == .destructive ? 883 : 851, cornerRadius: 11)
                    .fill(action.role == .normal ? Color.remnAccent : Color.remnSurface)
            }
        }
        .overlay {
            if action.role == .destructive {
                WobblyRoundedRectangle(seed: 883, cornerRadius: 11)
                    .stroke(Color.remnAccent, lineWidth: 1.25)
            }
        }
    }

    private func foreground(for role: HandmadeDialogRole) -> Color {
        switch role {
        case .normal: .remnPaper
        case .destructive: .remnAccent
        case .cancel: .remnGraphite
        }
    }

    private func dismiss() {
        isPresented = false
    }
}

extension View {
    func handmadeDialog(
        isPresented: Binding<Bool>,
        title: LocalizedStringKey,
        message: Text? = nil,
        actions: [HandmadeDialogAction]
    ) -> some View {
        modifier(
            HandmadeDialogModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                actions: actions
            )
        )
    }
}

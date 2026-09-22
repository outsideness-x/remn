import SwiftUI

struct SRSExplainerSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HandwrittenText("srs.title")
                    .font(RemnTypography.navigationTitle)
                    .remnHandwrittenBounds()
                Spacer()
                Button { dismiss() } label: {
                    HandwrittenText("done")
                        .font(RemnTypography.smallControl)
                        .remnHandwrittenBounds()
                }
                    .foregroundStyle(Color.remnAccent)
                    .buttonStyle(.plain)
                    .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    FlashcardSurface(seed: 606, style: .compact) {
                        VStack(alignment: .leading, spacing: 8) {
                            HandwrittenText(verbatim: "FSRS-6")
                                .font(RemnTypography.display(32, weight: .semibold, relativeTo: .title))
                                .remnHandwrittenBounds()
                                .foregroundStyle(Color.remnAccent)
                            Text("srs.intro")
                                .font(.body)
                                .foregroundStyle(Color.remnInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    explainerSection(number: "1", title: "srs.memory.title", body: "srs.memory.body") {
                        memoryDoodle
                    }

                    explainerSection(number: "2", title: "srs.ratings.title", body: "srs.ratings.body") {
                        ratingLegend
                    }

                    explainerSection(number: "3", title: "srs.queue.title", body: "srs.queue.body") {
                        EmptyView()
                    }

                    explainerSection(number: "4", title: "srs.retention.title", body: "srs.retention.body") {
                        EmptyView()
                    }

                    Text("srs.history")
                        .font(.footnote)
                        .foregroundStyle(Color.remnGraphite)
                        .padding(.bottom, 18)
                }
                .padding(.horizontal, 24)
                .padding(.top, 18)
            }
        }
        .background(Color.remnPaper.ignoresSafeArea())
    }

    private func explainerSection<Detail: View>(
        number: String,
        title: LocalizedStringKey,
        body: LocalizedStringKey,
        @ViewBuilder detail: () -> Detail
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 9) {
                HandwrittenText(verbatim: number)
                    .font(RemnTypography.display(18, weight: .semibold, relativeTo: .headline))
                    .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                    .foregroundStyle(Color.remnAccent)
                    .frame(width: 25, height: 25)
                    .overlay {
                        Circle()
                            .stroke(Color.remnAccent, lineWidth: 1.4)
                    }
                    .rotationEffect(.degrees(number == "2" ? 4 : -3))
                HandwrittenText(title)
                    .font(RemnTypography.display(25, weight: .semibold, relativeTo: .title3))
                    .remnHandwrittenBounds()
                    .foregroundStyle(Color.remnInk)
            }
            Text(body)
                .font(.body)
                .foregroundStyle(Color.remnInk)
                .fixedSize(horizontal: false, vertical: true)
            detail()
        }
    }

    private var memoryDoodle: some View {
        HStack(spacing: 7) {
            memoryStep("srs.now", width: 46)
            Text("→").foregroundStyle(Color.remnAccent)
            memoryStep("srs.later", width: 62)
            Text("→").foregroundStyle(Color.remnAccent)
            memoryStep("srs.muchLater", width: 88)
        }
        .font(RemnTypography.smallControl)
        .remnHandwrittenBounds(horizontal: 2, vertical: 1)
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
    }

    private func memoryStep(_ title: LocalizedStringKey, width: CGFloat) -> some View {
        HandwrittenText(title)
            .frame(width: width)
            .padding(.vertical, 7)
            .background {
                WobblyRoundedRectangle(seed: Int(width), cornerRadius: 10)
                    .fill(Color.remnSurface)
            }
    }

    private var ratingLegend: some View {
        VStack(alignment: .leading, spacing: 7) {
            ratingLine("rating.again", note: "srs.again")
            ratingLine("rating.hard", note: "srs.hard")
            ratingLine("rating.good", note: "srs.good")
            ratingLine("rating.easy", note: "srs.easy")
        }
        .padding(.top, 4)
    }

    private func ratingLine(_ rating: LocalizedStringKey, note: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            HandwrittenText(rating)
                .font(RemnTypography.smallControl)
                .remnHandwrittenBounds(horizontal: 2, vertical: 1)
                .foregroundStyle(Color.remnAccent)
                .frame(width: 54, alignment: .leading)
            Text(note)
                .font(.subheadline)
                .foregroundStyle(Color.remnGraphite)
        }
    }
}


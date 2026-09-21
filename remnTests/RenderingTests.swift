import Testing
import Textual
import SwiftUI
import UIKit
@testable import remn

struct RenderingTests {
    @Test func multilineDisplayMathIsCollapsedBeforeMarkdownParsing() {
        let source = """
        before

        $$
          E = mc^2
        $$

        after
        """

        #expect(
            MarkdownRenderSource.normalized(source) == """
            before

            $$E = mc^2$$

            after
            """
        )
    }

    @Test func spacedAndLatexDelimitersAreNormalized() {
        #expect(MarkdownRenderSource.normalized("$$ E = mc^2 $$") == "$$E = mc^2$$")
        #expect(MarkdownRenderSource.normalized("\\[ x^2 \\]") == "$$x^2$$")
        #expect(MarkdownRenderSource.normalized("value \\( x + 1 \\)") == "value $x + 1$")
    }

    @Test func displayMathIsSeparatedFromMarkdown() {
        #expect(
            MarkdownRenderSource.blocks(in: "before\n\n$$E = mc^2$$\n\nafter") == [
                .markdown("before\n\n"),
                .displayMath("E = mc^2"),
                .markdown("\n\nafter"),
            ]
        )
    }

    @Test func mathDelimitersInsideCodeFencesStayCode() {
        let source = """
        ```swift
        let selector = "$$notMath$$"
        ```

        $$x^2$$
        """

        #expect(MarkdownRenderSource.normalized(source).contains("$$notMath$$"))
        #expect(
            MarkdownRenderSource.blocks(in: source) == [
                .markdown("""
                ```swift
                let selector = "$$notMath$$"
                ```

                """),
                .displayMath("x^2"),
            ]
        )
    }

    @MainActor
    @Test func normalizedMathIsRecognizedByTextual() throws {
        let parser = AttributedStringMarkdownParser(
            baseURL: nil,
            patternOptions: .init(mathExpressions: true)
        )
        let output = try parser.attributedString(
            for: MarkdownRenderSource.normalized("$$\nE = mc^2\n$$")
        )

        #expect(String(output.characters).contains("\u{FFFC}"))
        #expect(!String(output.characters).contains("$$"))
    }

    @MainActor
    @Test func displayMathProducesARealImage() throws {
        let renderer = ImageRenderer(
            content: CardContentView(
                markdown: "$$E = mc^2$$",
                context: .preview
            )
            .frame(width: 320)
            .padding(24)
            .background(Color.remnPaper)
            .environment(\.colorScheme, .dark)
        )
        renderer.scale = 3

        let image = try #require(renderer.uiImage)
        let png = try #require(image.pngData())
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("remn-math-render.png")
        try png.write(to: output, options: .atomic)

        #expect(image.size.width == 368)
        #expect(image.size.height > 60)
    }
}
